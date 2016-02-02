"use strict";

var initialValues = {
  ckeditor : '',
  dropzoneUploadedFile : null,
  selectEvent: null
};

var elmApp = Elm.fullscreen(Elm.Main, initialValues);

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
function waitForElement(selector, fn, model, tryCount) {

  // Repeat the timeout only maximum 5 times, which sohuld be enough for the
  // element to appear.
  tryCount = tryCount || 5;
  --tryCount;
  if (tryCount == 0) {
    return;
  }

  setTimeout(function() {

    var result = fn.call(null, selector, model, tryCount);
    if (!result) {
      // Element still doesn't exist, so wait some more.
      waitForElement(selector, fn, model, tryCount);
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

  // The event Ids holds the array of all the current events - even the one that
  // might be filtered out. By unsetting the ones that have visible markers, we
  // remain with the ones that should be removed.
  // We make sure to clonse the event Ids, so we can always query the original
  // events.
  var eventIds = JSON.parse(JSON.stringify(model.events));

  var selectedMarker = undefined;

  model.leaflet.markers.forEach(function(marker) {
    var id = marker.id;
    if (!markersEl[id]) {
      markersEl[id] = L.marker([marker.lat, marker.lng]).addTo(mapEl);
      selectMarker(markersEl[id], id);
    }
    else {
      markersEl[id].setLatLng([marker.lat, marker.lng]);
    }

    var isSelected = !!model.leaflet.selectedMarker && model.leaflet.selectedMarker === id;

    if (isSelected) {
      // Center the map around the selected event.
      selectedMarker = markersEl[id];
    }

    // Set the marker's icon.
    markersEl[id].setIcon(isSelected ? selectedIcon : defaultIcon);

    // Unset the marker form the event IDs list.
    var index = eventIds.indexOf(id);
    eventIds.splice(index, 1);
  });

  // When there are markers available, fit the map around them.
  if (model.leaflet.markers.length) {

    // Try to see is there are bounds. If there are not, center the map.
    try {
      mapEl.getBounds();
    }
    catch (err) {
      mapEl.fitBounds(model.leaflet.markers);
    }

    // When a marker is selected, center the map around it.
    if (selectedMarker) {
      mapEl.panTo(selectedMarker._latlng);
    }
    else {
      mapEl.fitBounds(model.leaflet.markers);
    }
  }
  else {
    // Show the entire world when no markers are set.
    mapEl.setZoom(1);
  }

  // Hide filtered markers.
  eventIds.forEach(function(id) {
    if (markersEl[id]) {
      mapEl.removeLayer(markersEl[id]);
      markersEl[id] = undefined;
    }
  });


  // Iterate over all the existing markers, and make sure they part of the
  // existing events list. Otherwise, remove them.
  for (var id in markersEl) {
    if (model.events.indexOf(parseInt(id)) > -1) {
      // Marker doesn't exist in the current event list.
      continue;
    }

    if (!markersEl[id]) {
      // Marker is already invisible.
      continue;
    }

    mapEl.removeLayer(markersEl[id]);
    markersEl[id] = undefined;
  }

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
  // Leaflet map.
  var mapEl = L.map('map');

  L.tileLayer('https://api.tiles.mapbox.com/v4/{id}/{z}/{x}/{y}.png?access_token=pk.eyJ1IjoibWFwYm94IiwiYSI6ImNpandmbXliNDBjZWd2M2x6bDk3c2ZtOTkifQ._QA7i5Mpkd_m30IGElHziw', {
    maxZoom: 10,
    id: 'mapbox.streets'
  }).addTo(mapEl);

  return mapEl;
}



// Dropzone
// @todo: Move to own file.

var ck = undefined;
var dropZone = undefined;

elmApp.ports.activePage.subscribe(function(model) {
  if (model.activePage != 'Article') {
    // Reset dropzone variable, in case we switch between pages.
    ck = undefined;
    dropZone = undefined;
    return;
  }

  waitForElement('.dropzone', attachDropzone, model);
});

function attachDropzone(selector, model) {
  if (model.activePage != 'Article') {
    return false;
  }

  var element = document.querySelector(selector);
  if (!element) {
    // Element doesn't exist yet.
    return false;
  }

  if (!!dropZone) {

    // Check if we need to remove files.
    if (model.postStatus == "Done") {
      // Remove all files, even the ones being currently uploaded.
      dropZone.removeAllFiles(true);

      // Clear the CKeditor text area.
      ck.setData('');
    }

    // Widgets were already attached once.
    return true;
  }


  // Set the backend url with the access token.
  var url = model.backendUrl + '/api/file-upload?access_token=' + model.accessToken;

  dropZone = new Dropzone(selector, { url: url});

  dropZone.on('complete', function(file) {
    if (!file.accepted) {
      // File was not uploaded.
      return;
    }

    if (file.xhr.status !== 200) {
      return;
    }

    var data = JSON.parse(file.xhr.response);

    // Get the file ID, and send it to Elm.
    var id = parseInt(data.data[0]['id']);
    elmApp.ports.dropzoneUploadedFile.send(id);
  });

  ck = CKEDITOR.replace('body');

  // Send the data to Elm.
  ck.on('change', function() {
    elmApp.ports.ckeditor.send(ck.getData());
  });
}
