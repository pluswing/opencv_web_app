module Style exposing (..)

import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input exposing (button)


main =
    Element.layout [ explain Debug.todo ]
        rootView


rootView : Element msg
rootView =
    row [ width fill, height fill, spacing 30 ]
        [ controlView
        , mainView
        , historyView
        ]


controlView : Element msg
controlView =
    column [ alignTop ]
        [ button []
            { onPress = Nothing
            , label = text "My Button"
            }
        , text "BUTTON 02"
        , text "BUTTON 03"
        , text "BUTTON 04"
        ]


mainView : Element msg
mainView =
    el [ width fill, alignTop ]
        (text "MAIN")


historyView : Element msg
historyView =
    column [ alignTop ]
        [ text "HISTORY 01"
        , text "HISTORY 02"
        , text "HISTORY 03"
        ]
