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
    = ImageUpload
    | ImageSelected File
    | ImageUploadResponse (Result Http.Error Image)
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
    | SelectLayer FilterResult
    | Contours
    | ContoursResponse (Result Http.Error ImageWithExtracted)
    | BitwiseNot
    | BitwiseNotResponse (Result Http.Error Image)


type FilterResult
    = UploadImageResult Image
    | GrayscaleResult Image
    | ThresholdResult ImageWithThreshold
    | FaceDetectionResult ImageWithFaces
    | OcrResult ImageWithTexts
    | ContoursResult ImageWithExtracted
    | BitwiseNotResult Image


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

        ContoursResult image ->
            image.image

        BitwiseNotResult image ->
            image


type alias Model =
    { history : List FilterResult
    , current : Maybe FilterResult
    , currentImage : Maybe Image
    , threshold : String -- INPUT VALUE
    }


type alias Image =
    { taskId : String
    , id : String
    }


image2Url : Image -> String
image2Url image =
    apiEndpoint ++ "/static/task/" ++ image.taskId ++ "/" ++ image.id ++ ".jpg"


imageDecoder : Decoder Image
imageDecoder =
    map2 Image
        (field "task_id" string)
        (field "id" string)


imageEncoder : Image -> Encode.Value
imageEncoder image =
    Encode.object
        [ ( "task_id", Encode.string image.taskId )
        , ( "id", Encode.string image.id )
        ]


type alias ImageWithExtracted =
    { image : Image
    , extracted : List Image
    }


type alias ImageText =
    { image : Image
    , text : String
    , score : Float
    }


imageTextDecoder : Decoder ImageText
imageTextDecoder =
    map3 ImageText
        (field "image" imageDecoder)
        (field "text" string)
        (field "score" float)


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
        ImageUpload ->
            imageUpload model

        ImageSelected file ->
            imageSelected model file

        ImageUploadResponse result ->
            imageUploadResponse model result

        Grayscale ->
            grayscale model

        GrayscaleResponse result ->
            grayscaleResponse model result

        ChangeThreshold value ->
            changeThreshold model value

        Threshold ->
            threshold model

        ThresholdResponse result ->
            thresholdResponse model result

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

        SelectLayer result ->
            ( { model | current = Just result, currentImage = Just (filterResult2Image result) }, Cmd.none )

        Contours ->
            case model.currentImage of
                Just img ->
                    ( model
                    , Http.post
                        { url = apiEndpoint ++ "/contours"
                        , body =
                            Http.jsonBody (imageEncoder img)
                        , expect = Http.expectJson ContoursResponse contoursResponseDecoder
                        }
                    )

                Nothing ->
                    ( model, Cmd.none )

        ContoursResponse result ->
            case result of
                Ok img ->
                    ( { model
                        | history = model.history ++ [ ContoursResult img ]
                        , current = Just (ContoursResult img)
                        , currentImage = Just img.image
                      }
                    , Cmd.none
                    )

                Err _ ->
                    ( model, Cmd.none )

        BitwiseNot ->
            case model.currentImage of
                Just img ->
                    ( model
                    , Http.post
                        { url = apiEndpoint ++ "/bitwise_not"
                        , body =
                            Http.jsonBody (imageEncoder img)
                        , expect = Http.expectJson BitwiseNotResponse bitwiseNotResponseDecoder
                        }
                    )

                Nothing ->
                    ( model, Cmd.none )

        BitwiseNotResponse result ->
            case result of
                Ok img ->
                    ( { model
                        | history = model.history ++ [ BitwiseNotResult img ]
                        , current = Just (BitwiseNotResult img)
                        , currentImage = Just img
                      }
                    , Cmd.none
                    )

                Err _ ->
                    ( model, Cmd.none )


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
    row
        [ width fill
        , height fill
        , spacing 30
        , Background.color colors.main
        ]
        [ controlView model.threshold
        , mainView model.current model.currentImage
        , historyView model.history model.current
        ]


colors : { background : Color, headline : Color, paragraph : Color, button : Color, buttonText : Color, stroke : Color, main : Color, highlight : Color, secondary : Color, tertialy : Color }
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


buttonStyle : List (Attr () msg)
buttonStyle =
    [ Background.color colors.button
    , Font.color colors.buttonText
    , Border.rounded 3
    , padding 30
    , width fill
    , center
    ]


controlView : String -> Element Msg
controlView thresholdValue =
    column [ alignTop, spacing 20 ]
        [ Input.button buttonStyle
            { onPress = Just ImageUpload
            , label = text "Upload Image"
            }
        , Input.button buttonStyle
            { onPress = Just Grayscale
            , label = text "Grayscale"
            }
        , column [ width fill ]
            [ Input.text []
                { onChange = ChangeThreshold
                , text = thresholdValue
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
        , Input.button buttonStyle
            { onPress = Just Contours
            , label = text "Contours"
            }
        , Input.button buttonStyle
            { onPress = Just BitwiseNot
            , label = text "BitwiseNot"
            }
        ]


mainView : Maybe FilterResult -> Maybe Image -> Element Msg
mainView result selected =
    case result of
        Just res ->
            el [ width fill, alignTop ]
                (case res of
                    UploadImageResult image ->
                        imageView selected image

                    GrayscaleResult image ->
                        imageView selected image

                    ThresholdResult image ->
                        thresholdResultView image selected

                    FaceDetectionResult image ->
                        faceDetectionResultView image selected

                    OcrResult image ->
                        ocrResultView image selected

                    ContoursResult image ->
                        contourResultView image selected

                    BitwiseNotResult image ->
                        imageView selected image
                )

        Nothing ->
            el [ width fill, alignTop ]
                (text "Nothing")


imageView : Maybe Image -> Image -> Element Msg
imageView selected img =
    image
        ([ padding 5
         , width fill
         , Events.onClick (SelectImage img)
         ]
            ++ (if selected == Just img then
                    [ Background.color colors.highlight ]

                else
                    []
               )
        )
        { src = image2Url img
        , description = ""
        }


type alias ImageWithThreshold =
    { image : Image
    , threshold : String
    }


thresholdResultView : ImageWithThreshold -> Maybe Image -> Element Msg
thresholdResultView image selected =
    column []
        [ imageView selected image.image
        , row []
            [ text "THRESHOLD:"
            , text image.threshold
            ]
        ]


thresholdResponseDecoder : Decoder ImageWithThreshold
thresholdResponseDecoder =
    map2 ImageWithThreshold
        (field "result" (field "image" imageDecoder))
        (field "result" (field "params" (field "threshold" string)))


imageEncoderWithThreashold : Image -> String -> Encode.Value
imageEncoderWithThreashold image thresholdValue =
    Encode.object
        [ ( "task_id", Encode.string image.taskId )
        , ( "id", Encode.string image.id )
        , ( "threshold", Encode.string thresholdValue )
        ]


changeThreshold : Model -> String -> ( Model, Cmd Msg )
changeThreshold model value =
    ( { model | threshold = value }, Cmd.none )


threshold : Model -> ( Model, Cmd Msg )
threshold model =
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


thresholdResponse : Model -> Result Http.Error ImageWithThreshold -> ( Model, Cmd Msg )
thresholdResponse model result =
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


faceDetectionResultView : ImageWithFaces -> Maybe Image -> Element Msg
faceDetectionResultView image selected =
    row []
        [ el [ width (fillPortion 2) ] (imageView selected image.image)
        , column [ width (fillPortion 3) ] (List.map (imageView selected) image.faces)
        ]


type alias ImageWithFaces =
    { image : Image
    , faces : List Image
    }


faceDetectionResponseDecoder : Decoder ImageWithFaces
faceDetectionResponseDecoder =
    map2 ImageWithFaces
        (field "result" (field "image" imageDecoder))
        (field "result" (field "params" (field "faces" (list imageDecoder))))


contourResultView : ImageWithExtracted -> Maybe Image -> Element Msg
contourResultView image selected =
    row []
        [ el [ width (fillPortion 2) ] (imageView selected image.image)
        , column [ width (fillPortion 3) ] (List.map (imageView selected) image.extracted)
        ]


contoursResponseDecoder : Decoder ImageWithExtracted
contoursResponseDecoder =
    map2 ImageWithExtracted
        (field "result" (field "image" imageDecoder))
        (field "result" (field "params" (field "extracted" (list imageDecoder))))


type alias ImageWithTexts =
    { image : Image
    , texts : List ImageText
    }


ocrResultView : ImageWithTexts -> Maybe Image -> Element Msg
ocrResultView image selected =
    row []
        [ el [ width (fillPortion 2) ] (imageView selected image.image)
        , column [ width (fillPortion 3) ] (List.map (imageTextView selected) image.texts)
        ]


ocrResponseDecoder : Decoder ImageWithTexts
ocrResponseDecoder =
    map2 ImageWithTexts
        (field "result" (field "image" imageDecoder))
        (field "result" (field "params" (field "texts" (list imageTextDecoder))))


imageTextView : Maybe Image -> ImageText -> Element Msg
imageTextView selected image =
    column []
        [ imageView selected image.image
        , text image.text
        , text ("(" ++ String.fromFloat image.score ++ ")")
        ]


historyView : List FilterResult -> Maybe FilterResult -> Element Msg
historyView history selected =
    column [ alignTop, spacing 5 ]
        (List.map
            (historyItemView selected)
            history
        )


historyItemView : Maybe FilterResult -> FilterResult -> Element Msg
historyItemView selected result =
    el
        ([ padding 10
         , width fill
         , Events.onClick (SelectLayer result)
         ]
            ++ (if selected == Just result then
                    [ Background.color colors.highlight ]

                else
                    [ Background.color colors.secondary ]
               )
        )
        (case result of
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

            ContoursResult image ->
                text "Contours"

            BitwiseNotResult image ->
                text "BitwiseNot"
        )


imageUploadResponseDecoder : Decoder Image
imageUploadResponseDecoder =
    field "result" (field "image" imageDecoder)


imageUpload : Model -> ( Model, Cmd Msg )
imageUpload model =
    ( model, Select.file [] ImageSelected )


imageSelected : Model -> File -> ( Model, Cmd Msg )
imageSelected model file =
    ( model
    , Http.post
        { url = apiEndpoint ++ "/upload_image"
        , body = Http.multipartBody [ Http.filePart "uploadFile" file ]
        , expect = Http.expectJson ImageUploadResponse imageUploadResponseDecoder
        }
    )


imageUploadResponse : Model -> Result Http.Error Image -> ( Model, Cmd Msg )
imageUploadResponse model result =
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


grayscaleResponseDecoder : Decoder Image
grayscaleResponseDecoder =
    imageUploadResponseDecoder


grayscale : Model -> ( Model, Cmd Msg )
grayscale model =
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


grayscaleResponse : Model -> Result Http.Error Image -> ( Model, Cmd Msg )
grayscaleResponse model result =
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


bitwiseNotResponseDecoder : Decoder Image
bitwiseNotResponseDecoder =
    imageUploadResponseDecoder
