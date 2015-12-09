module Pages.Login.View where

import Pages.Login.Model exposing (initialModel, Model)
import Pages.Login.Update exposing (Action)

import Config.Model exposing (BackendConfig)
import Html exposing (a, button, div, i, input, h2, hr, span, text, Html)
import Html.Attributes exposing (action, class, disabled, id, hidden, href, placeholder, required, size, style, type', value)
import Html.Events exposing (on, onClick, onSubmit, targetValue)
import String exposing (isEmpty)

type alias ViewContext =
  { backendConfig : BackendConfig
  }

view : ViewContext -> Signal.Address Action -> Model -> Html
view context address model =
  let
    modelForm =
      model.loginForm

    isFormEmpty =
      String.isEmpty modelForm.name || String.isEmpty modelForm.pass

    isFetchStatus =
      model.status == Pages.Login.Model.Fetching || model.status == Pages.Login.Model.Fetched

    githubClientId =
      (.backendConfig >> .githubClientId) context

    githubUrl =
      "https://github.com/login/oauth/authorize?client_id=" ++ githubClientId ++ "&scope=user:email"


    githubLogin =
      div
      [ class "btn btn-lg btn-primary btn-block"]
      [ a
        [ href githubUrl]
        [ i [ class "fa fa-github", style [("margin-right", "10px")] ] []
        , span [] [ text "Login with GitHub" ]
        ]
      ]

    loginForm =
      Html.form
        [ onSubmit address Pages.Login.Update.SubmitForm
        , action "javascript:void(0);"
        , class "form-signin"
        -- Don't show the form while checking for the access token from the
        -- storage.
        , hidden model.hasAccessTokenInStorage
        ]

        -- Form title
        [ h2 [] [ text "Please login" ]
        -- UserName
        , githubLogin
        , div
          [ style [("margin-bottom", "20px"), ("margin-top", "20px"), ("text-align", "center")] ]
          [ text "OR" ]
        , div
            [ class "input-group" ]
            [ span
                [ class "input-group-addon" ]
                [ i [ class "glyphicon glyphicon-user" ] [] ]
                , input
                    [ type' "text"
                    , class "form-control"
                    , placeholder "Name"
                    , value model.loginForm.name
                    , on "input" targetValue (Signal.message address << Pages.Login.Update.UpdateName)
                    , size 40
                    , required True
                    , disabled (isFetchStatus)
                    ]
                    []
           ]
        -- Password
        , div
          [ class "input-group"]
          [ span
              [ class "input-group-addon" ]
              [ i [ class "fa fa-lock fa-lg" ] [] ]
          , input
              [ type' "password"
              , class "form-control"
              , placeholder "Password"
              , value modelForm.pass
              , on "input" targetValue (Signal.message address << Pages.Login.Update.UpdatePass)
              , size 40
              , required True
              , disabled (isFetchStatus)
              ]
              []
           ]

        -- Submit button
        , button
            [ onClick address Pages.Login.Update.SubmitForm
            , class "btn btn-lg btn-primary btn-block"
            , disabled (isFetchStatus || isFormEmpty)
            ]
            [ span [ hidden <| not isFetchStatus] [ spinner ]
            , span [ hidden isFetchStatus ] [ text "Login" ] ]
            ]

    spinner =
      i [ class "fa fa-spinner fa-spin" ] []

    userMessage =
      case model.userMessage of
        Pages.Login.Model.None ->
          div [] []
        Pages.Login.Model.Error message ->
          div [ style [("text-align", "center")]] [ text message ]

  in
    div [ id "login-page" ] [
      hr [] []
      , div
          [ class "container" ]
          [ userMessage
          , div
              [ class "wrapper" ]
              [ loginForm
              , div
                  [ class "text-center"
                  , hidden (not (model.status == Pages.Login.Model.Fetching) && not model.hasAccessTokenInStorage) ]
                  [ text "Loading ..." ]
              ]
            ]
            , hr [] []
          ]
