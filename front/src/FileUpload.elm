import Browser
import File exposing (File)
import File.Select as Select
import Html exposing (Html, button, div, text)
import Html.Attributes exposing (type_, value)
import Html.Events exposing (onClick)
import Http

main =
  Browser.element
    { init = init
    , update = update
    , subscriptions = subscriptions
    , view = view
    }

type Model =
  CsvRequested |
  CsvSelected File |
  Uploaded


init : () -> (Model, Cmd Msg)
init _ =
  ( Loading, Cmd.none )

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        CsvRequested ->
            ( model, Select.file [] CsvSelected )

        CsvSelected f ->
            ( model , Http.post {
              url = "/upload_image"
            , body = Http.multipartBody [ Http.filePart "uploadFile" f ]
        , expect = Http.expectWhatever Uploaded
        }
    )
        _ ->
            ( model, Cmd.none )

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none


view : Model -> Html Msg
view model =
    div []
        [ button [ onClick CsvRequested ] [ text "Upload csv" ]
        ]
