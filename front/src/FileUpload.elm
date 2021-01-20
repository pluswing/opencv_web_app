module FileUpload exposing (main)

import Browser
import File exposing (File)
import File.Select as Select
import Html exposing (Html, button, div, img, text)
import Html.Attributes exposing (src, type_, value)
import Html.Events exposing (onClick)
import Http
import Json.Decode exposing (Decoder, field, map2, string)


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }


type Msg
    = CsvRequested
    | CsvSelected File
    | Uploaded (Result Http.Error Image)


type alias Model =
    { image : Maybe Image
    }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { image = Nothing }, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        CsvRequested ->
            ( model, Select.file [] CsvSelected )

        CsvSelected file ->
            ( model
            , Http.post
                { url = "http://localhost:5000/upload_image"
                , body = Http.multipartBody [ Http.filePart "uploadFile" file ]
                , expect = Http.expectJson Uploaded uploadImageResponseDecoder
                }
            )

        Uploaded result ->
            case result of
                Ok img ->
                    ( { model | image = Just img }, Cmd.none )

                Err err ->
                    ( { model | image = Nothing }, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


view : Model -> Html Msg
view model =
    div []
        [ button [ onClick CsvRequested ] [ text "Upload Image" ]
        , img [ src (image2Url model.image) ] []
        ]


type alias Image =
    { taskId : String
    , id : String
    }


uploadImageResponseDecoder : Decoder Image
uploadImageResponseDecoder =
    field "result" (field "image" imageDecoder)


imageDecoder : Decoder Image
imageDecoder =
    map2 Image
        (field "task_id" string)
        (field "id" string)


image2Url : Maybe Image -> String
image2Url image =
    case image of
        Just img ->
            "http://localhost:5000/static/task/" ++ img.taskId ++ "/" ++ img.id ++ ".jpg"

        Nothing ->
            ""
