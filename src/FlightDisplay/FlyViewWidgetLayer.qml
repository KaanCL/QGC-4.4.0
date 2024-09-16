/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick                  2.12
import QtQuick.Controls         2.4
import QtQuick.Dialogs          1.3
import QtQuick.Layouts          1.12

import QtLocation               5.3
import QtPositioning            5.3
import QtQuick.Window           2.2
import QtQml.Models             2.1



import QGroundControl               1.0
import QGroundControl.Palette       1.0
import QGroundControl.Controls      1.0
import QGroundControl.Controls      1.0
import QGroundControl.Controllers   1.0
import QGroundControl.FlightMap     1.0
import QGroundControl.FlightDisplay 1.0
import QGroundControl.ScreenTools   1.0


// This is the ui overlay layer for the widgets/tools for Fly View
Item {
    id: _root


   QGCPalette { id: qgcPal }

    property var  vehicle:              globals.activeVehicle
    property real altitude:             vehicle.altitudeRelative.value
    property real groundSpeed:          vehicle.groundSpeed.rawValue
    property var    parentToolInsets
    property var    totalToolInsets:        _totalToolInsets
    property var    mapControl
    property bool   isViewer3DOpen:         false
    property var    palette:           QGCPalette { colorGroupEnabled: true }
    property var    enabledPalette:    QGCPalette { colorGroupEnabled: true }
    property var    disabledPalette:   QGCPalette { colorGroupEnabled: false }
    property var    _activeVehicle:    QGroundControl.multiVehicleManager.activeVehicle
    property var    _vehicleInAir:      _activeVehicle ? _activeVehicle.flying || _activeVehicle.landing : false
    property bool   _vtolInFWDFlight:   _activeVehicle ? _activeVehicle.vtolInFwdFlight : false
    property bool   _armed:             _activeVehicle ? _activeVehicle.armed : false
    property var    _planMasterController:  globals.planMasterControllerFlyView
    property bool   _communicationLost: _activeVehicle ? _activeVehicle.vehicleLinkManager.communicationLost : false
    property bool   _healthAndArmingChecksSupported: _activeVehicle ? _activeVehicle.healthAndArmingCheckReport.supported : false
    property var    _missionController:     _planMasterController.missionController
    property var    _geoFenceController:    _planMasterController.geoFenceController
    property var    _rallyPointController:  _planMasterController.rallyPointController
    property var    _guidedController:      globals.guidedControllerFlyView
    property real   _margins:               ScreenTools.defaultFontPixelWidth / 2
    property real   _toolsMargin:           ScreenTools.defaultFontPixelWidth * 0.75
    property rect   _centerViewport:        Qt.rect(0, 0, width, height)
    property real   _rightPanelWidth:       ScreenTools.defaultFontPixelWidth * 30
    property alias  _gripperMenu:           gripperOptions
    property real   _layoutMargin:          ScreenTools.defaultFontPixelWidth * 0.75
    property bool   _layoutSpacing:         ScreenTools.defaultFontPixelWidth
    property bool   _showSingleVehicleUI:   true
    property color  _mainStatusBGColor: "#6C0000"

    property bool utmspActTrigger

    QGCToolInsets {
        id:                     _totalToolInsets
        leftEdgeTopInset:       toolStrip.leftEdgeTopInset
        leftEdgeCenterInset:    toolStrip.leftEdgeCenterInset
        leftEdgeBottomInset:    virtualJoystickMultiTouch.visible ? virtualJoystickMultiTouch.leftEdgeBottomInset : parentToolInsets.leftEdgeBottomInset
        rightEdgeTopInset:      topRightColumnLayout.rightEdgeTopInset
        rightEdgeCenterInset:   topRightColumnLayout.rightEdgeCenterInset
        rightEdgeBottomInset:   bottomRightRowLayout.rightEdgeBottomInset
        topEdgeLeftInset:       toolStrip.topEdgeLeftInset
        topEdgeCenterInset:     mapScale.topEdgeCenterInset
        topEdgeRightInset:      topRightColumnLayout.topEdgeRightInset
        bottomEdgeLeftInset:    virtualJoystickMultiTouch.visible ? virtualJoystickMultiTouch.bottomEdgeLeftInset : parentToolInsets.bottomEdgeLeftInset
        bottomEdgeCenterInset:  bottomRightRowLayout.bottomEdgeCenterInset
        bottomEdgeRightInset:   virtualJoystickMultiTouch.visible ? virtualJoystickMultiTouch.bottomEdgeRightInset : bottomRightRowLayout.bottomEdgeRightInset
    }


    property bool screenTheme : qgcPal.globalTheme === QGCPalette.Light
    property string hand_left:  "/InstrumentValueIcons/Hand-" + (screenTheme ? "Black-Left.svg" : "White-Left.svg")
    property string hand_right: "/InstrumentValueIcons/Hand-" + (screenTheme ? "Black-Right.svg" : "White-Right.svg")
    property int fontSizeTelemetry: Screen.width / 80 < 1 ? 1 : Screen.width / 80
    property int buttonSize: Screen.width * 0.07
    property int buttonImageSize : buttonSize - 20
    property color selectVehicleBackgroundColor: "red"
    property int modNumbers: 5
    property bool handPoss : false
    property int telemetryRecSize: Screen.width * 0.15
    property int telemetryImageSize : Screen.width * 0.02
    property int telemetryFontSize:  Screen.width / 125
    property int buttonRadius: Screen.width * 0.01
    property bool flagCommunicationLost: false
    property bool guidedType :_guidedController.showTakeoff || !_guidedController.showLand



    property string _commLostText:      qsTr("İletişim Kayboldu"/*"Communication Lost"*/)
    property string _readyToFlyText:    qsTr("Uçuşa Hazır"/*"Ready To Fly"*/)
    property string _notReadyToFlyText: qsTr("Hazır Değil"/*"Not Ready"*/)
    property string _disconnectedText:  qsTr("Bağlantı Yok"/*"Disconnected - Click to manually connect"*/)
    property string _armedText:         qsTr("Armed")
    property string _flyingText:        qsTr("Uçuşta"/*"Flying"*/)
    property string _landingText:       qsTr("İnişte"/*"Landing"*/)



    function mainStatusText() {
        var statusText
        if (_activeVehicle) {
            if (_communicationLost) {
                _mainStatusBGColor = "#910303"
                return _commLostText
            }
            if (_activeVehicle.armed) {
                _mainStatusBGColor = "#13730B"

                if (_healthAndArmingChecksSupported) {
                    if (_activeVehicle.healthAndArmingCheckReport.canArm) {
                        if (_activeVehicle.healthAndArmingCheckReport.hasWarningsOrErrors) {
                            _mainStatusBGColor = "#7A7500"
                        }
                    } else {
                        _mainStatusBGColor = "#6C0000"
                    }
                }

                if (_activeVehicle.flying) {
                    return _flyingText
                } else if (_activeVehicle.landing) {
                    return _landingText
                } else {
                    return _armedText
                }
            } else {
                if (_healthAndArmingChecksSupported) {
                    if (_activeVehicle.healthAndArmingCheckReport.canArm) {
                        if (_activeVehicle.healthAndArmingCheckReport.hasWarningsOrErrors) {
                            _mainStatusBGColor = "#7A7500"
                        } else {
                            _mainStatusBGColor = "#13730B"
                        }
                        return _readyToFlyText
                    } else {
                        _mainStatusBGColor = "#6C0000"
                        return _notReadyToFlyText
                    }
                } else if (_activeVehicle.readyToFlyAvailable) {
                    if (_activeVehicle.readyToFly) {
                        _mainStatusBGColor = "#13730B"
                        return _readyToFlyText
                    } else {
                        _mainStatusBGColor = "#7A7500"
                        return _notReadyToFlyText
                    }
                } else {

                    if (_activeVehicle.allSensorsHealthy && _activeVehicle.autopilot.setupComplete) {
                        _mainStatusBGColor = "#13730B"
                        return _readyToFlyText
                    } else {
                        _mainStatusBGColor = "#7A7500"
                        return _notReadyToFlyText
                    }
                }
            }
        } else {
            _mainStatusBGColor = "#6C0000"
            return _disconnectedText
        }
    }

    FlyViewCustomLayer{
    id: _header
    width:Screen.width * 0.5
    visible: true
    height: Screen.width * 0.05
    anchors.top:parent.top
    radius: buttonRadius
   anchors.left: vehicleStatus.right
   // anchors.right: instrumentPanel.left
    anchors.topMargin: Screen.width  * 0.01
    anchors.leftMargin: Screen.width  * 0.01
    anchors.horizontalCenter:parent.horizontalCenter
    }


    Rectangle{
      id:vehicleStatus
      width: Screen.width * 0.2
      height: Screen.width * 0.05
      anchors.left: leftCol.left
      anchors.top: parent.top
      anchors.topMargin: Screen.width  * 0.01
      radius:  buttonRadius//width / 25
      color: _mainStatusBGColor
      opacity: 0.8

      MouseArea{
         anchors.fill: parent
         onClicked: mainWindow.showToolSelectDialog()
      }

      Text{
       id: mainStatusLabel
       text: mainStatusText()
       color:"white"
       font.weight: Font.Medium
       font.pointSize:telemetryFontSize
       anchors.verticalCenter: parent.verticalCenter
        anchors.left: _comnLostButton.visible ? parent.left : undefined
        anchors.horizontalCenter:  _comnLostButton.visible ?   undefined : parent.horizontalCenter
        anchors.leftMargin:  _comnLostButton.visible ? Screen.width * 0.01 : 0
}
      Rectangle{
          id:_comnLostButton
          width: Screen.width * 0.08
          radius: 3
          height: Screen.width * 0.035
          anchors.right: parent.right
          color:"#363636"
          anchors.rightMargin: Screen.width * 0.01
          anchors.verticalCenter: parent.verticalCenter
          visible: _activeVehicle && _communicationLost


          Text {
              text: qsTr("Bağlantıyı Kes")
              anchors.verticalCenter: parent.verticalCenter
              anchors.centerIn: parent
              color:"white"
              font.pointSize:  Screen.width / 150

          }

        MouseArea{
        anchors.fill: parent
        onClicked: {_activeVehicle.closeVehicle() ; mainStatusLabel.anchors.horizontalCenter = parent.horizontalCenter}
        }

      }


    }


   Rectangle{
       id:modeStatus
       width: Screen.width * 0.15
       height: vehicleStatus.height
       anchors.left: leftCol.left
       anchors.top:vehicleStatus.bottom
       anchors.topMargin: Screen.width * 0.01
       radius:  buttonRadius
       color: "#222222"
       visible: _activeVehicle
       opacity: 0.8

       Column{
           anchors.top: parent.top
           anchors.bottom: parent.bottom
           anchors.horizontalCenter: parent.horizontalCenter
           anchors.topMargin: 1



        Image{
          id:modeStatusImage
          source:"/qmlimages/FlightModesComponentIcon.png"
          fillMode:Image.PreserveAspectFit
          width: Screen.width * 0.03
          height: width
        }

        Text{
          id:modeStatusText
          text:_activeVehicle ? _activeVehicle.flightMode : "N/A"
          font.weight: Font.Medium
          font.pointSize:telemetryFontSize
          anchors.horizontalCenter: modeStatusImage.horizontalCenter
          color:"white"
        }

       }

   }


    Rectangle{
      id:flightPlan
      width: Screen.width * 0.1
      anchors.top:_activeVehicle ? modeStatus.bottom : vehicleStatus.bottom
      anchors.left:parent.left
     anchors.topMargin: Screen.width * 0.01
      height: Screen.width * 0.095
      radius: buttonRadius
       anchors.leftMargin: 30
      color :"#7A7500"
      opacity: 0.8


      MouseArea{
      anchors.fill: parent
      onClicked:  mainWindow.showPlanView()

      }


      Image {
          id: flightPlanImage
          source:  "/qmlimages/Plan.svg"
          width: buttonImageSize
          sourceSize.height: buttonImageSize
          anchors.horizontalCenter:parent.horizontalCenter
          //fillMode:Image.PreserveAspectFit
          anchors.verticalCenter: parent.verticalCenter

      }

      Text {
          id: flightPlanText
          text: qsTr("Uçuş Planla")
          anchors.top: flightPlanImage.bottom
          anchors.bottom: parent.bottom
          anchors.verticalCenter: flightPlanImage.verticalCenter
           anchors.horizontalCenter:flightPlanImage.horizontalCenter
           anchors.topMargin: 5
          color: "white"
          font.weight: Font.Medium
          font.pointSize: telemetryFontSize



      }

    }


Column{
id:leftCol
 spacing:Screen.width * 0.015
 anchors.top:flightPlan.bottom
 anchors.left:flightPlan.left
 anchors.topMargin: Screen.width * 0.04


 Rectangle{
 id:generalSettings
 color: Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.9)
 width: buttonSize
 height: buttonSize
 radius : buttonSize / 2
 anchors.left:parent.left
 MouseArea        {
     anchors.fill: parent
     onClicked:{
         mainWindow.showSettingsTool()
        // mainWindow.toolDrawermapVisible()
     }
 }
 Image{
   id:generalSettingsImage
   source: "/res/gear-" + (screenTheme ? "black.svg" : "white.svg")
   width: buttonImageSize
   height: buttonImageSize
   anchors.horizontalCenter:parent.horizontalCenter
   anchors.verticalCenter: parent.verticalCenter
 }
}

 Rectangle{
   id:map
   color: Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.9)
   width: buttonSize
   height: buttonSize
   radius : buttonSize / 2
 anchors.left:parent.left

    MouseArea{
        anchors.fill:parent
        onClicked:{mainWindow.showMapSettings()}
    }

    Image{
      id:mapImage
      source: "/InstrumentValueIcons/map-" + (screenTheme ? "black.png" : "white.png")
      width: buttonImageSize
      height: buttonImageSize
      anchors.horizontalCenter:parent.horizontalCenter
      anchors.verticalCenter: parent.verticalCenter
    }
 }

}

Column{
    id:rightCol
     spacing:Screen.width * 0.015
     visible: _activeVehicle
     anchors.verticalCenter: leftCol.verticalCenter
     anchors.right: parent.right
     anchors.rightMargin: 30

     Rectangle{
     id:takeoff
     color: Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.9)
     width: buttonSize
     height: buttonSize
     radius: buttonSize / 2
     anchors.right:parent.right

     MouseArea{
     anchors.fill: parent
     onClicked: {
         _guidedController.closeAll()
         if(guidedType ){
        _guidedController.confirmAction(_guidedController.actionTakeoff)}
         else{
         _guidedController.confirmAction(_guidedController.actionLand)
             }

     }
     }

     Image{
       id:takeoffImage
       source:guidedType ? "/InstrumentValueIcons/takeoff2-white.svg" : "/res/land.svg"
       width: buttonImageSize
       anchors.horizontalCenter:parent.horizontalCenter
       fillMode:Image.PreserveAspectFit
       anchors.verticalCenter: parent.verticalCenter
      sourceSize.height:buttonImageSize
     }
     }

     Rectangle {
       id:returnHome
       color: Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.9)
       width: buttonSize
       height: buttonSize
       radius : buttonSize / 2
       anchors.right: parent.right

       MouseArea{
           anchors.fill: parent
           onClicked: {_guidedController.closeAll()
                        _guidedController.confirmAction(_guidedController.actionRTL)
                }

     }

       Image{
        id:returnImage
        source:"/InstrumentValueIcons/rtl-white.svg"
        width: buttonImageSize
        height: buttonImageSize
        anchors.horizontalCenter:parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
       }
}

 }
FlyViewInstrumentPanel {
      id:                         instrumentPanel
      anchors.margins:            _toolsMargin
      anchors.top:                 parent.top
      anchors.right:              rightCol.right
      width:                      _rightPanelWidth
      spacing:                    _toolsMargin
       anchors.topMargin: Screen.width  * 0.01
      visible:                   false// QGroundControl.corePlugin.options.flyView.showInstrumentPanel && multiVehiclePanelSelector.showSingleVehiclePanel
      availableHeight:            parent.height - y - _toolsMargin

  }


    Row{
     id:telemetryBar
     anchors.bottom: parent.bottom
     anchors.horizontalCenter:parent.horizontalCenter
     anchors.bottomMargin: 30
     spacing:Screen.width * 0.010
     //visible: _activeVehicle

     Rectangle{
        id:speedValue
        width:telemetryRecSize
        radius: buttonRadius
        height: Screen.width * 0.04
        color:Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.9)

        Row{
          anchors.left:parent.left
          anchors.horizontalCenter:parent.horizontalCenter
          anchors.verticalCenter: parent.verticalCenter
          anchors.leftMargin: Screen.width * 0.01
          spacing: 4

          QGCColoredImage{
          id: speedImage
          source:"/InstrumentValueIcons/arrow-simple-right.svg"
          fillMode:Image.PreserveAspectFit
          width :telemetryImageSize
          height:telemetryImageSize
          }

          QGCLabel {
              id: speedText
              text: "Hız: " + (_activeVehicle ? groundSpeed.toFixed(1) +  "m/s" : "0.0m/s")
              color:"white"
              font.weight: Font.Medium
              font.pointSize:telemetryFontSize
              anchors.verticalCenter: speedImage.verticalCenter


          }
        }
     }

    Rectangle{
        id:altitudeValue
        width:telemetryRecSize
        radius: buttonRadius
        height: Screen.width * 0.04
        color:Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.9)

        Row{
          anchors.left:parent.left
          anchors.horizontalCenter:parent.horizontalCenter
          anchors.verticalCenter: parent.verticalCenter
          anchors.leftMargin: Screen.width * 0.01
          spacing: 4

          QGCColoredImage{
          id: altitudeImage
          source:"/InstrumentValueIcons/alttitude.svg"
          fillMode:Image.PreserveAspectFit
          width : telemetryImageSize
          height:telemetryImageSize
          }

          QGCLabel {
              id: altitudeText
              text: "Yükseklik: " + (_activeVehicle ? altitude.toFixed(1) +  "m":  "0.0")
              color:"white"
              font.weight: Font.Medium
              font.pointSize: telemetryFontSize
              anchors.verticalCenter:  altitudeImage.verticalCenter
          }

        }

     }
     Rectangle{
        id:durationValue
        width:telemetryRecSize
        radius: buttonRadius
        height: Screen.width * 0.04
        color:Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.9)

        Row{
          anchors.left:parent.left
          anchors.horizontalCenter:parent.horizontalCenter
          anchors.verticalCenter: parent.verticalCenter
          anchors.leftMargin: Screen.width * 0.01
          spacing: 4

          QGCColoredImage{
          id: durationImage
          source:"/InstrumentValueIcons/timer.svg"
          fillMode:Image.PreserveAspectFit
          width : telemetryImageSize
          height:telemetryImageSize
          }

          QGCLabel {
              id: durationText
              text:"Süre:" + (_activeVehicle ?  vehicle.flightTime : "00:00:00" )
              color:"white"
              font.weight: Font.Medium
              font.pointSize:telemetryFontSize
              anchors.verticalCenter: durationImage.verticalCenter
          }

        }

     }
    }



    FlyViewMissionCompleteDialog {
        missionController:      _missionController
        geoFenceController:     _geoFenceController
        rallyPointController:   _rallyPointController
    }

    GuidedActionConfirm {
        anchors.margins:            _toolsMargin
        anchors.bottom:              telemetryBar.top
        anchors.bottomMargin: 3
        anchors.horizontalCenter:   parent.horizontalCenter
        z:                          QGroundControl.zOrderTopMost
        guidedController:           _guidedController
        guidedValueSlider:          _guidedValueSlider
    }

    //-- Virtual Joystick
    Loader {
        id:                         virtualJoystickMultiTouch
        z:                          QGroundControl.zOrderTopMost + 1
        anchors.right:              parent.right
        anchors.rightMargin:        anchors.leftMargin
        height:                     Math.min(parent.height * 0.25, ScreenTools.defaultFontPixelWidth * 16)
        visible:                    _virtualJoystickEnabled && !QGroundControl.videoManager.fullScreen && !(_activeVehicle ? _activeVehicle.usingHighLatencyLink : false)
        anchors.bottom:             parent.bottom
        anchors.bottomMargin:       bottomLoaderMargin
        anchors.left:               parent.left
        anchors.leftMargin:         ( y > toolStrip.y + toolStrip.height ? toolStrip.width / 2 : toolStrip.width * 1.05 + toolStrip.x)
        source:                     "qrc:/qml/VirtualJoystick.qml"
        active:                     _virtualJoystickEnabled && !(_activeVehicle ? _activeVehicle.usingHighLatencyLink : false)

        property real bottomEdgeLeftInset:     parent.height-y
        property bool autoCenterThrottle:      QGroundControl.settingsManager.appSettings.virtualJoystickAutoCenterThrottle.rawValue
        property bool _virtualJoystickEnabled: QGroundControl.settingsManager.appSettings.virtualJoystick.rawValue
        property real bottomEdgeRightInset:    parent.height-y
        property var  _pipViewMargin:          _pipView.visible ? parentToolInsets.bottomEdgeLeftInset + ScreenTools.defaultFontPixelHeight * 2 :
                                               bottomRightRowLayout.height + ScreenTools.defaultFontPixelHeight * 1.5

        property var  bottomLoaderMargin:      _pipViewMargin >= parent.height / 2 ? parent.height / 2 : _pipViewMargin

        // Width is difficult to access directly hence this hack which may not work in all circumstances
        property real leftEdgeBottomInset:  visible ? bottomEdgeLeftInset + width/18 - ScreenTools.defaultFontPixelHeight*2 : 0
        property real rightEdgeBottomInset: visible ? bottomEdgeRightInset + width/18 - ScreenTools.defaultFontPixelHeight*2 : 0

        //Loader status logic
        onLoaded:           virtualJoystickMultiTouch.visible ?  virtualJoystickMultiTouch.item.calibration = true : virtualJoystickMultiTouch.item.calibration = false
    }

    FlyViewToolStrip { //Sol üst widget layeri ( plan takeoff menu )
        id:                     toolStrip
        anchors.leftMargin:     _toolsMargin + parentToolInsets.leftEdgeCenterInset
        anchors.topMargin:      _toolsMargin + parentToolInsets.topEdgeLeftInset
        anchors.left:           parent.left
        anchors.top:            parent.top
        z:                      QGroundControl.zOrderWidgets
        maxHeight:              parent.height - y - parentToolInsets.bottomEdgeLeftInset - _toolsMargin
        visible:                false//!QGroundControl.videoManager.fullScreen

        onDisplayPreFlightChecklist: preFlightChecklistPopup.createObject(mainWindow).open()


        property real topEdgeLeftInset:     visible ? y + height : 0
        property real leftEdgeTopInset:     visible ? x + width : 0
        property real leftEdgeCenterInset:  leftEdgeTopInset
    }

    GripperMenu {
        id: gripperOptions
    }

    VehicleWarnings {
        anchors.centerIn:   parent
        z:                  QGroundControl.zOrderTopMost
    }

    MapScale {
        id:                 mapScale
        anchors.margins:    _toolsMargin
        anchors.left:        flightPlan.right
        anchors.top:         flightPlan.top
        mapControl:         _mapControl
        buttonsOnLeft:      true
        visible:           !ScreenTools.isTinyScreen && QGroundControl.corePlugin.options.flyView.showMapScale && !isViewer3DOpen && mapControl.pipState.state === mapControl.pipState.fullState

        property real topEdgeCenterInset: visible ? y + height : 0
    }

    Component {
        id: preFlightChecklistPopup
        FlyViewPreFlightChecklistPopup {
        }
    }
}
