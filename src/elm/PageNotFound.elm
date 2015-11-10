module PageNotFound where

import Html exposing (a, div, h2, text, Html)
import Html.Attributes exposing (class, href, style)

-- VIEW

view : Html
view =
  div
    [ class "container", style elementStyle ]
    [ h2 [] [ text "This is a 404 page!"]
    , a [ href "#!/"] [ text "Back to safety"]
    ]

elementStyle : List (String, String)
elementStyle =
  [ ("text-align", "center") ]
