module FileUpload exposing (image2Url, main)

import Browser
import Env exposing (apiEndpoint)
import File exposing (File)
import File.Select as Select
import Html exposing (Html, button, div, img, input, text)
import Html.Attributes exposing (src, type_, value)
import Html.Events exposing (onClick, onInput)
import Http
import Json.Decode exposing (Decoder, field, map2, string)
import Json.Encode as Encode


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
    | Grayscale
    | GrayscaleResponse (Result Http.Error Image)
    | ChangeThreshold String
    | Threshold
    | ThresholdResponse (Result Http.Error Image)


type alias Model =
    { image : Maybe Image
    , threshold : String
    }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { image = Nothing, threshold = "" }, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        CsvRequested ->
            ( model, Select.file [] CsvSelected )

        CsvSelected file ->
            ( model
            , Http.post
                { url = apiEndpoint ++ "/upload_image"
                , body = Http.multipartBody [ Http.filePart "uploadFile" file ]
                , expect = Http.expectJson Uploaded uploadImageResponseDecoder
                }
            )

        Uploaded result ->
            case result of
                Ok img ->
                    ( { model | image = Just img }, Cmd.none )

                Err _ ->
                    ( { model | image = Nothing }, Cmd.none )

        Grayscale ->
            case model.image of
                Just img ->
                    ( model
                    , Http.post
                        { url = apiEndpoint ++ "/grayscale"
                        , body =
                            Http.jsonBody (imageEncoder img)
                        , expect = Http.expectJson GrayscaleResponse grayscaleResponseDecoder
                        }
                    )

                Nothing ->
                    ( model, Cmd.none )

        GrayscaleResponse result ->
            case result of
                Ok img ->
                    ( { model | image = Just img }, Cmd.none )

                Err _ ->
                    ( { model | image = Nothing }, Cmd.none )

        ChangeThreshold value ->
            ( { model | threshold = value }, Cmd.none )

        Threshold ->
            case model.image of
                Just img ->
                    ( model
                    , Http.post
                        { url = apiEndpoint ++ "/threshold"
                        , body =
                            -- TODO thresholdを渡す。
                            Http.jsonBody (imageEncoder img)
                        , expect = Http.expectJson ThresholdResponse thresholdResponseDecoder
                        }
                    )

                Nothing ->
                    ( model, Cmd.none )

        ThresholdResponse result ->
            case result of
                Ok img ->
                    ( { model | image = Just img }, Cmd.none )

                Err _ ->
                    ( { model | image = Nothing }, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none


view : Model -> Html Msg
view model =
    div []
        [ button [ onClick CsvRequested ] [ text "Upload Image" ]
        , button [ onClick Grayscale ] [ text "grayscale" ]
        , input [ type_ "text", value model.threshold, onInput ChangeThreshold ] []
        , button [ onClick Threshold ] [ text "threshold" ]
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


grayscaleResponseDecoder : Decoder Image
grayscaleResponseDecoder =
    uploadImageResponseDecoder


thresholdResponseDecoder : Decoder Image
thresholdResponseDecoder =
    -- TODO thresholdも返す
    uploadImageResponseDecoder


image2Url : Maybe Image -> String
image2Url image =
    case image of
        Just img ->
            apiEndpoint ++ "/static/task/" ++ img.taskId ++ "/" ++ img.id ++ ".jpg"

        Nothing ->
            ""


imageEncoder : Image -> Encode.Value
imageEncoder image =
    Encode.object
        [ ( "task_id", Encode.string image.taskId )
        , ( "id", Encode.string image.id )
        ]
