import QtQuick                  2.3
import QtQuick.Controls         2.12
import QtQuick.Controls.Styles  1.4

import QGroundControl.Palette 1.0
import QGroundControl.ScreenTools 1.0

Button {
    id:             control
    hoverEnabled:   !ScreenTools.isMobile
    topPadding:     _verticalPadding
    bottomPadding:  _verticalPadding
    leftPadding:    _horizontalPadding
    rightPadding:   _horizontalPadding
    focusPolicy:    Qt.ClickFocus

    property bool   primary:        false                               ///< primary button for a group of buttons
    property real   pointSize:      ScreenTools.defaultFontPointSize    ///< Point size for button text
    property bool   showBorder:     qgcPal.globalTheme === QGCPalette.Light
    property bool   iconLeft:       false
    property real   backRadius:     0
    property real   heightFactor:   0.5
    property real layerInfo
    property real   buttonIndex:   -1
    property real   fontWeight:     Font.Normal // default for qml Text
    property string iconSource

    property alias wrapMode:            text.wrapMode
    property alias horizontalAlignment: text.horizontalAlignment

    property bool   _showHighlight:     pressed | hovered | checked

    property int _horizontalPadding:    ScreenTools.defaultFontPixelWidth
    property int _verticalPadding:      Math.round(ScreenTools.defaultFontPixelHeight * heightFactor)

    QGCPalette { id: qgcPal; colorGroupEnabled: enabled }

    background: Rectangle {
        id:             backRect
        implicitWidth:  ScreenTools.implicitButtonWidth
        implicitHeight: ScreenTools.implicitButtonHeight
        radius:         backRadius
        border.width:   showBorder ? 1 : 0
        border.color:   qgcPal.buttonText
        color:
            if(buttonIndex !=-1){
                if((layerInfo == 0 && buttonIndex == 0 ) || (layerInfo == 1 && buttonIndex == 1)){
                     qgcPal.buttonHighlight
                }
                else{
                     qgcPal.windowShadeDark
                }
            }
             else{
             _showHighlight ? qgcPal.buttonHighlight : (primary ? qgcPal.primaryButton : qgcPal.button)
             }

    }

    contentItem: Item {
        implicitWidth:  text.implicitWidth + icon.width
        implicitHeight: text.implicitHeight
        baselineOffset: text.y + text.baselineOffset

        QGCColoredImage {
            id:                     icon
            source:                 control.iconSource
            height:                 source === "" ? 0 : text.height
            width:                  height
            color:                  text.color
            fillMode:               Image.PreserveAspectFit
            sourceSize.height:      height
            anchors.left:           control.iconLeft ? parent.left : undefined
            anchors.leftMargin:     control.iconLeft ? ScreenTools.defaultFontPixelWidth : undefined
            anchors.right:          !control.iconLeft ? parent.right : undefined
            anchors.rightMargin:    !control.iconLeft ? ScreenTools.defaultFontPixelWidth : undefined
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            id:                     text
            anchors.centerIn:       parent
            antialiasing:           true
            text:                   control.text
            font.pointSize:         pointSize
            font.family:            ScreenTools.normalFontFamily
            font.weight:            fontWeight
            color:
                if(buttonIndex !=-1){
                    if((layerInfo == 0 && buttonIndex == 0 ) || (layerInfo == 1 && buttonIndex == 1)){
                       qgcPal.windowShadeDark
                    }
                    else{
                         "white"
                    }
                }
                else{_showHighlight ? qgcPal.buttonHighlightText :(primary ? qgcPal.primaryButtonText : "white")
          }
        }
    }
}
