module FileUpload exposing (image2Url, main)

import Browser
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Events as Events
import Element.Font as Font exposing (center)
import Element.Input as Input
import Env exposing (apiEndpoint)
import File exposing (File)
import File.Select as Select
import Html exposing (Html)
import Http
import Json.Decode exposing (Decoder, field, float, list, map2, map3, string)
import Json.Encode as Encode


main : Program () Model Msg
main =
    Browser.document
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
    | SelectImage Image


type FilterResult
    = UploadImageResult Image
    | GrayscaleResult Image
    | ThresholdResult ImageWithThreshold
    | FaceDetectionResult ImageWithFaces
    | OcrResult ImageWithTexts


type alias Model =
    { history : List FilterResult
    , current : Maybe FilterResult
    , currentImage : Maybe Image
    , threshold : String -- INPUT VALUE
    }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { history = []
      , current = Nothing
      , currentImage = Nothing
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
                        , currentImage = Just img
                      }
                    , Cmd.none
                    )

                Err _ ->
                    ( model, Cmd.none )

        Grayscale ->
            case model.currentImage of
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
                        , currentImage = Just img
                      }
                    , Cmd.none
                    )

                Err _ ->
                    ( model, Cmd.none )

        ChangeThreshold value ->
            ( { model | threshold = value }, Cmd.none )

        Threshold ->
            case model.currentImage of
                Just img ->
                    ( model
                    , Http.post
                        { url = apiEndpoint ++ "/threshold"
                        , body =
                            Http.jsonBody
                                (imageEncoderWithThreashold
                                    img
                                    model.threshold
                                )
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
                        , currentImage = Just img.image
                      }
                    , Cmd.none
                    )

                Err _ ->
                    ( model, Cmd.none )

        FaceDetection ->
            case model.currentImage of
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
                        , currentImage = Just img.image
                      }
                    , Cmd.none
                    )

                Err _ ->
                    ( model, Cmd.none )

        Ocr ->
            case model.currentImage of
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
                        , currentImage = Just img.image
                      }
                    , Cmd.none
                    )

                Err _ ->
                    ( model, Cmd.none )

        SelectImage image ->
            ( { model | currentImage = Just image }, Cmd.none )


filterResult2Image : FilterResult -> Image
filterResult2Image result =
    case result of
        UploadImageResult image ->
            image

        GrayscaleResult image ->
            image

        ThresholdResult image ->
            image.image

        FaceDetectionResult image ->
            image.image

        OcrResult image ->
            image.image


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none


view : Model -> Browser.Document Msg
view model =
    { title = "Example"
    , body =
        [ Element.layout
            [ explain Debug.todo ]
            (rootView model)
        ]
    }


rootView : Model -> Element Msg
rootView model =
    row [ width fill, height fill, spacing 30 ]
        [ controlView model.threshold
        , mainView model.current model.currentImage
        , historyView model.history
        ]


colors =
    { background = rgb255 0xFF 0xFF 0xFE
    , headline = rgb255 0x18 0x18 0x18
    , paragraph = rgb255 0x2E 0x2E 0x2E
    , button = rgb255 0x4F 0xC4 0xCF
    , buttonText = rgb255 0x18 0x18 0x18
    , stroke = rgb255 0x18 0x18 0x18
    , main = rgb255 0xF2 0xEE 0xF5
    , highlight = rgb255 0x4F 0xC4 0xCF
    , secondary = rgb255 0x99 0x4F 0xF3
    , tertialy = rgb255 0xFB 0xDD 0x74
    }


buttonStyle =
    [ Background.color colors.button
    , Font.color colors.buttonText
    , Border.rounded 3
    , padding 30
    , width fill
    , center
    ]


controlView : String -> Element Msg
controlView threshold =
    column [ alignTop, spacing 20 ]
        [ Input.button buttonStyle
            { onPress = Just CsvRequested
            , label = text "Upload Image"
            }
        , Input.button buttonStyle
            { onPress = Just Grayscale
            , label = text "Grayscale"
            }
        , column [ width fill ]
            [ Input.text []
                { onChange = ChangeThreshold
                , text = threshold
                , placeholder = Nothing
                , label = Input.labelHidden ""
                }
            , Input.button buttonStyle
                { onPress = Just Threshold
                , label = text "Threshold"
                }
            ]
        , Input.button buttonStyle
            { onPress = Just FaceDetection
            , label = text "Face detection"
            }
        , Input.button buttonStyle
            { onPress = Just Ocr
            , label = text "OCR"
            }
        ]


mainView : Maybe FilterResult -> Maybe Image -> Element Msg
mainView result selected =
    case result of
        Just res ->
            el [ width fill, alignTop ]
                (case res of
                    UploadImageResult image ->
                        imageView image

                    GrayscaleResult image ->
                        imageView image

                    ThresholdResult image ->
                        thresholdResultView image

                    FaceDetectionResult image ->
                        faceDetectionResultView image

                    OcrResult image ->
                        ocrResultView image
                )

        Nothing ->
            el [ width fill, alignTop ]
                (text "Nothing")


imageView : Image -> Element Msg
imageView img =
    image [ Events.onClick (SelectImage img) ]
        { src = image2Url img
        , description = ""
        }


thresholdResultView : ImageWithThreshold -> Element Msg
thresholdResultView image =
    column []
        [ imageView image.image
        , row []
            [ text "THRESHOLD:"
            , text image.threshold
            ]
        ]


faceDetectionResultView : ImageWithFaces -> Element Msg
faceDetectionResultView image =
    row []
        [ imageView image.image
        , column [] (List.map imageView image.faces)
        ]


ocrResultView : ImageWithTexts -> Element Msg
ocrResultView image =
    row []
        [ imageView image.image
        , column [] (List.map imageTextView image.texts)
        ]


imageTextView : ImageText -> Element Msg
imageTextView image =
    column []
        [ imageView image.image
        , text image.text
        , text ("(" ++ String.fromFloat image.score ++ ")")
        ]


historyView : List FilterResult -> Element Msg
historyView history =
    column [ alignTop ]
        (List.map
            historyItemView
            history
        )


historyItemView : FilterResult -> Element Msg
historyItemView result =
    case result of
        UploadImageResult image ->
            text "UPLAOD IMAGE"

        GrayscaleResult image ->
            text "GRASCALE"

        ThresholdResult image ->
            text "THRESHOLD"

        FaceDetectionResult image ->
            text "FACE DETECTION"

        OcrResult image ->
            text "OCR"



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


image2Url : Image -> String
image2Url image =
    apiEndpoint ++ "/static/task/" ++ image.taskId ++ "/" ++ image.id ++ ".jpg"


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
