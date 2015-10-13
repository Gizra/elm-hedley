"use strict";

var elmApp = Elm.fullscreen(Elm.Main, {selectEvent: null});

// @todo: Remove this hack, that makes sure that the map will appear on first
// load, as the subscribe to port is triggered only on the first change of
// model, and not when it is initialized.
elmApp.ports.selectEvent.send(null);

// Maintain the map and marker state.
var mapEl = undefined;
var markersEl = {};

var defaultIcon = L.icon({
  iconUrl: 'default@2x.png',
  iconRetinaUrl: 'default@2x.png',
  iconSize: [35, 46]
});

var selectedIcon = L.icon({
  iconUrl: 'selected@2x.png',
  iconRetinaUrl: 'selected@2x.png',
  iconSize: [35, 46]
});

elmApp.ports.mapManager.subscribe(function(model) {
  if (!model.leaflet.showMap && !!mapEl) {
    // Hide the map.
    mapEl.remove();
    mapEl = undefined;
    markersEl = {};
    return;
  }

  // We use timeout, to let virtual-dom add the div we need to bind to.
  waitForElement('#map', mapManager, model);
});


/**
 * Wait for selector to appear before invoking related functions.
 */
function waitForElement(selector, fn, model) {
  setTimeout(function() {
    var result = fn.call(null, selector, model);
    if (!result) {
      // Element still doesn't exist, so wait some more.
      waitForElement(selector, fn, model);
    }
  }, 50);
}

/**
 * Attach or detach the Leaflet map and markers.
 *
 * @return bool
 *   Determines if mapManager completed it's operation. True means we don't need
 *   ro re-call this function.
 */
function mapManager(selector, model) {
  if (!model.leaflet.showMap) {
    return true;
  }

  var element = document.querySelector(selector);
  if (!element) {
    // Element doesn't exist yet.
    return false;
  }

  mapEl = mapEl || addMap();

  // The event Ids holds the array of all the events - even the one that are
  // hidden. By unsetting the ones that have visible markers, we remain with
  // the ones that should be removed.
  var eventIds = model.events;

  model.leaflet.markers.forEach(function(marker) {
    var id = marker.id;
    if (!markersEl[id]) {
      markersEl[id] = L.marker([marker.lat, marker.lng]).addTo(mapEl);
      selectMarker(markersEl[id], id);
    }
    else {
      markersEl[id].setLatLng([marker.lat, marker.lng]);
    }

    // Set the marker's icon.
    markersEl[id].setIcon(!!model.leaflet.selectedMarker && model.leaflet.selectedMarker === id ? selectedIcon : defaultIcon);

    // Unset the marker form the event IDs list.
    var index = eventIds.indexOf(id);
    eventIds.splice(index, 1);
  });

  // Hide existing markers.
  eventIds.forEach(function(id) {
    if (markersEl[id]) {
      mapEl.removeLayer(markersEl[id]);
      markersEl[id] = undefined;
    }
  });

  // Map was binded properly.
  return true;
}

/**
 * Send marker click event to Elm.
 */
function selectMarker(markerEl, id) {
  markerEl.on('click', function(e) {
    elmApp.ports.selectEvent.send(id);
  });
}

/**
 * Initialize a Leaflet map.
 */
function addMap() {
  // Leaflet
  var mapEl = L.map('map').setView([50, 50], 3);

  L.tileLayer('https://api.tiles.mapbox.com/v4/{id}/{z}/{x}/{y}.png?access_token=pk.eyJ1IjoibWFwYm94IiwiYSI6IjZjNmRjNzk3ZmE2MTcwOTEwMGY0MzU3YjUzOWFmNWZhIn0.Y8bhBaUMqFiPrDRW9hieoQ', {
    maxZoom: 10,
    id: 'mapbox.streets'
  }).addTo(mapEl);

  return mapEl;
}
