module FileUploadTest exposing (..)

import Expect
import FileUpload exposing (image2Url)
import Test exposing (..)


suite : Test
suite =
    describe "FileUpload Test"
        [ describe "image2Url"
            [ test "args is Noothing" <|
                \_ ->
                    Expect.equal "" (image2Url Nothing)
            , test "args is Not Nothing" <|
                \_ ->
                    Just { taskId = "a", id = "b" }
                        |> image2Url
                        |> Expect.equal "http://localhost:5000/static/task/a/b.jpg"
            ]
        ]
