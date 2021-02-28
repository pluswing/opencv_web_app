module FileUpload exposing (image2Url, main)

import Browser
import Env exposing (apiEndpoint)
import File exposing (File)
import File.Select as Select
import Html exposing (Html, button, div, img, input, text)
import Html.Attributes exposing (src, type_, value)
import Html.Events exposing (onClick, onInput)
import Http
import Json.Decode exposing (Decoder, field, float, list, map2, map3, string)
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
    | ThresholdResponse (Result Http.Error ImageWithThreshold)
    | FaceDetection
    | FaceDetectionResponse (Result Http.Error ImageWithFaces)
    | Ocr
    | OcrResponse (Result Http.Error ImageWithTexts)


type FilterResult
    = UploadImageResult Image
    | GrayscaleResult Image
    | ThresholdResult ImageWithThreshold
    | FaceDetectionResult ImageWithFaces
    | OcrResult ImageWithTexts


type alias Model =
    { history : List FilterResult
    , current : Maybe FilterResult
    , threshold : String -- INPUT VALUE
    }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { history = []
      , current = Nothing
      , threshold = ""
      }
    , Cmd.none
    )


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
                    ( { model
                        | history = model.history ++ [ UploadImageResult img ]
                        , current = Just (UploadImageResult img)
                      }
                    , Cmd.none
                    )

                Err _ ->
                    ( model, Cmd.none )

        Grayscale ->
            -- TODO 選択画像をもつModelのプロパティが必要。
            case model.current of
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
                    ( { model
                        | history = model.history ++ [ GrayscaleResult img ]
                        , current = Just (GrayscaleResult img)
                      }
                    , Cmd.none
                    )

                Err _ ->
                    ( model, Cmd.none )

        ChangeThreshold value ->
            ( { model | threshold = value }, Cmd.none )

        Threshold ->
            case model.image of
                Just img ->
                    ( model
                    , Http.post
                        { url = apiEndpoint ++ "/threshold"
                        , body =
                            Http.jsonBody (imageEncoderWithThreashold img model.threshold)
                        , expect = Http.expectJson ThresholdResponse thresholdResponseDecoder
                        }
                    )

                Nothing ->
                    ( model, Cmd.none )

        ThresholdResponse result ->
            case result of
                Ok img ->
                    ( { model
                        | history = model.history ++ [ ThresholdResult img ]
                        , current = Just (ThresholdResult img)
                      }
                    , Cmd.none
                    )

                Err _ ->
                    ( model, Cmd.none )

        FaceDetection ->
            case model.image of
                Just img ->
                    ( model
                    , Http.post
                        { url = apiEndpoint ++ "/face_detection"
                        , body =
                            Http.jsonBody (imageEncoder img)
                        , expect = Http.expectJson FaceDetectionResponse faceDetectionResponseDecoder
                        }
                    )

                Nothing ->
                    ( model, Cmd.none )

        FaceDetectionResponse result ->
            case result of
                Ok img ->
                    ( { model
                        | history = model.history ++ [ FaceDetectionResult img ]
                        , current = Just (FaceDetectionResult img)
                      }
                    , Cmd.none
                    )

                Err _ ->
                    ( model, Cmd.none )

        Ocr ->
            case model.image of
                Just img ->
                    ( model
                    , Http.post
                        { url = apiEndpoint ++ "/ocr"
                        , body =
                            Http.jsonBody (imageEncoder img)
                        , expect = Http.expectJson OcrResponse ocrResponseDecoder
                        }
                    )

                Nothing ->
                    ( model, Cmd.none )

        OcrResponse result ->
            case result of
                Ok img ->
                    ( { model
                        | history = model.history ++ [ OcrResult img ]
                        , current = Just (OcrResult img)
                      }
                    , Cmd.none
                    )

                Err _ ->
                    ( model, Cmd.none )


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
        , button [ onClick FaceDetection ] [ text "face detection" ]
        , button [ onClick Ocr ] [ text "OCR" ]
        , img [ src (image2Url model.image) ] []
        ]



-- -- main view
-- case model.current:
--   ImageUploaded img ->
--     imageUploadedView(img)
--   GrayScaleResult img ->
--     grayScaleView(img)
--     ...
-- -- side
-- for h in model.history:
--     historyListItem(img)


type alias Image =
    { taskId : String
    , id : String
    }


type alias ImageWithThreshold =
    { image : Image
    , threshold : String
    }


type alias ImageWithFaces =
    { image : Image
    , faces : List Image
    }


type alias ImageText =
    { image : Image
    , text : String
    , score : Float
    }


type alias ImageWithTexts =
    { image : Image
    , texts : List ImageText
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


thresholdResponseDecoder : Decoder ImageWithThreshold
thresholdResponseDecoder =
    map2 ImageWithThreshold
        (field "result" (field "image" imageDecoder))
        (field "result" (field "params" (field "threshold" string)))


faceDetectionResponseDecoder : Decoder ImageWithFaces
faceDetectionResponseDecoder =
    map2 ImageWithFaces
        (field "result" (field "image" imageDecoder))
        (field "result" (field "params" (field "faces" (list imageDecoder))))


ocrResponseDecoder : Decoder ImageWithTexts
ocrResponseDecoder =
    map2 ImageWithTexts
        (field "result" (field "image" imageDecoder))
        (field "result" (field "params" (field "texts" (list textImagedecoder))))


textImagedecoder : Decoder ImageText
textImagedecoder =
    map3 ImageText
        (field "image" imageDecoder)
        (field "text" string)
        (field "score" float)


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


imageEncoderWithThreashold : Image -> String -> Encode.Value
imageEncoderWithThreashold image threshold =
    Encode.object
        [ ( "task_id", Encode.string image.taskId )
        , ( "id", Encode.string image.id )
        , ( "threshold", Encode.string threshold )
        ]
