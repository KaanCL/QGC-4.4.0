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
import QGroundControl.Controllers   1.0
import QGroundControl.Controls      1.0
import QGroundControl.FactSystem    1.0
import QGroundControl.FlightDisplay 1.0
import QGroundControl.FlightMap     1.0
import QGroundControl.Palette       1.0
import QGroundControl.ScreenTools   1.0
import QGroundControl.Vehicle       1.0

// To implement a custom overlay copy thi code to your own control in your custom code source. Then override the
// FlyViewCustomLayer.qml resource with your own qml. See the custom example and documentation for details.
Rectangle {
    id:headerBar
    color:  Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.9)
    property int currentToolbar: flyViewToolbar
    readonly property int flyViewToolbar:   0
    readonly property int planViewToolbar:  1
    readonly property int simpleToolbar:    2

     property var    _activeVehicle:   QGroundControl.multiVehicleManager.activeVehicle
    property bool   _communicationLost: _activeVehicle ? _activeVehicle.vehicleLinkManager.communicationLost : false

    property color  _mainStatusBGColor: qgcPal.brandingPurple

    QGCPalette { id: qgcPal }

    property var parentToolInsets               // These insets tell you what screen real estate is available for positioning the controls in your overlay
    property var totalToolInsets:   _toolInsets // These are the insets for your custom overlay additions
    property var mapControl

    property string alttitudeVehicle: "..."
    property int toolBarTextSize : Screen.width / 110
    property int toolBarIconSize : Screen.width * 0.03
    property int percent:  _activeVehicle ? _activeVehicle.rcRSSI : 0


    Component {
        id: batteryValuesAvailableComponent

        QtObject {
            property bool functionAvailable:         battery.function.rawValue !== MAVLink.MAV_BATTERY_FUNCTION_UNKNOWN
            property bool showFunction:              functionAvailable && battery.function.rawValue != MAVLink.MAV_BATTERY_FUNCTION_ALL
            property bool temperatureAvailable:      !isNaN(battery.temperature.rawValue)
            property bool currentAvailable:          !isNaN(battery.current.rawValue)
            property bool mahConsumedAvailable:      !isNaN(battery.mahConsumed.rawValue)
            property bool timeRemainingAvailable:    !isNaN(battery.timeRemaining.rawValue)
            property bool percentRemainingAvailable: !isNaN(battery.percentRemaining.rawValue)
            property bool chargeStateAvailable:      battery.chargeState.rawValue !== MAVLink.MAV_BATTERY_CHARGE_STATE_UNDEFINED
        }
    }


    property var batteryValuesAvailable: batteryValuesAvailableLoader.item

    Loader {
        id:                 batteryValuesAvailableLoader
        sourceComponent:    batteryValuesAvailableComponent


    }

    function getSignalIcon() {
        if (percent < 20)
            return "/qmlimages/Signal0.svg"
        if (percent < 40)
            return "/qmlimages/Signal20.svg"
        if (percent < 60)
            return "/qmlimages/Signal40.svg"
        if (percent < 80)
            return "/qmlimages/Signal60.svg"
        if (percent < 95)
            return "/qmlimages/Signal80.svg"
        return "/qmlimages/Signal100.svg"

    }


    // since this file is a placeholder for the custom layer in a standard build, we will just pass through the parent insets
    QGCToolInsets {
        id:                     _toolInsets
        leftEdgeTopInset:       parentToolInsets.leftEdgeTopInset
        leftEdgeCenterInset:    parentToolInsets.leftEdgeCenterInset
        leftEdgeBottomInset:    parentToolInsets.leftEdgeBottomInset
        rightEdgeTopInset:      parentToolInsets.rightEdgeTopInset
        rightEdgeCenterInset:   parentToolInsets.rightEdgeCenterInset
        rightEdgeBottomInset:   parentToolInsets.rightEdgeBottomInset
        topEdgeLeftInset:       parentToolInsets.topEdgeLeftInset
        topEdgeCenterInset:     parentToolInsets.topEdgeCenterInset
        topEdgeRightInset:      parentToolInsets.topEdgeRightInset
        bottomEdgeLeftInset:    parentToolInsets.bottomEdgeLeftInset
        bottomEdgeCenterInset:  parentToolInsets.bottomEdgeCenterInset
        bottomEdgeRightInset:   parentToolInsets.bottomEdgeRightInset
    }

    QGCColoredImage{
        id:                 _signal
        width:              toolBarIconSize
        height: toolBarIconSize
        anchors.left:parent.left
        anchors.leftMargin:15
        anchors.top:        parent.top
        anchors.bottom:     parent.bottom
        source: getSignalIcon()
        fillMode: Image.PreserveAspectFit
        color:qgcPal.buttonText

    }

    QGCColoredImage {
        id:                 gpsIcon
        width:   toolBarIconSize
        height: toolBarIconSize
        anchors.leftMargin: Screen.width * 0.010
        anchors.left: _signal.right
        source:             "/qmlimages/Gps.svg"
        fillMode:           Image.PreserveAspectFit
        sourceSize.height:  height
        visible: _activeVehicle
        anchors.verticalCenter:parent.verticalCenter
        opacity:            (_activeVehicle && _activeVehicle.gps.count.value >= 0) ? 1 : 0.5
        color:              qgcPal.buttonText
    }


        Repeater {
            id:     col2Repeater
            model:  _activeVehicle ? _activeVehicle.batteries : 0

          Row {
              id:batteryRow
              anchors.left: gpsIcon.right
              anchors.top:        headerBar.top
              anchors.bottom:     headerBar.bottom
               anchors.leftMargin: Screen.width * 0.010
                visible: _activeVehicle

                property var batteryValuesAvailable: valueAvailableLoader.item
                Loader {
                    id:                 valueAvailableLoader
                    sourceComponent:    batteryValuesAvailableComponent

                    property var battery: object

                }


                QGCColoredImage {
                       id: vehicleChargeImage
                       width:   toolBarIconSize
                       height: toolBarIconSize
                       source:"/qmlimages/Battery.svg"
                       fillMode:           Image.PreserveAspectFit
                       color:              qgcPal.buttonText
                       anchors.verticalCenter:parent.verticalCenter
                   }

                   QGCLabel {
                       id:vehicleChargeText
                       text:object.percentRemaining.valueString + "%"
                       color:{
                           if( parseInt(object.percentRemaining.valueString,10) >= 60 && parseInt(object.percentRemaining.valueString,10) <=100 ){
                          return "#33FF00"}
                           else if(parseInt(object.percentRemaining.valueString,10) > 20 && parseInt(object.percentRemaining.valueString,10) <60){
                           return "yellow"
                           }
                           else if(parseInt(object.percentRemaining.valueString,10) > 1 && parseInt(object.percentRemaining.valueString,10) <=20){
                           return "red"
                           }
                           else{
                           "red"
                           }
                       }
                       font.pointSize: toolBarTextSize
                      anchors.verticalCenter:parent.verticalCenter
                       anchors.left:vehicleChargeImage.right
                       anchors.leftMargin:2
                       font.weight: Font.Medium
                   }
                   QGCLabel {
                       id:vehicleChargeVoltageText
                       text:object.voltage.valueString + " " + object.voltage.units
                       color:"white"
                       font.pointSize: toolBarTextSize
                       anchors.verticalCenter:parent.verticalCenter
                       anchors.left:vehicleChargeText.right
                       anchors.leftMargin:3
                       font.weight: Font.Medium
                   }


            }
        }



    QGCColoredImage {
        id: deviceCharge
        width:   toolBarIconSize
        height: toolBarIconSize
        anchors.right:  parent.right
        anchors.top:    parent.top
        anchors.bottom: parent.bottom
        anchors.rightMargin: parent.width * 0.12
        source:"/qmlimages/Battery.svg"
        fillMode:           Image.PreserveAspectFit
        color:              qgcPal.buttonText

    }
    QGCLabel {
        id:deviceChargeText
        text: systemInfo.sys_Battery.toString()+"%"
        color:{
            if( systemInfo.sys_Battery >= 50 && systemInfo.sys_Battery <=100 ){
           return "#33FF00"}
            else if(systemInfo.sys_Battery > 20 && systemInfo.sys_Battery <50){
            return "yellow"
            }
            else if(systemInfo.sys_Battery > 1 && systemInfo.sys_Battery <=20){
            return "red"
            }
            else{
            "red"
            }
        }
        font.pointSize: toolBarTextSize
        anchors.verticalCenter:parent.verticalCenter
        anchors.left:deviceCharge.right
        anchors.leftMargin:2
        font.weight: Font.Medium
    }




    QGCLabel {
        id: time_setting
        text: systemInfo.sys_Time
        color: "#D9D9D9"
        font.pointSize: toolBarTextSize
         anchors.right: deviceCharge.left
         anchors.verticalCenter:parent.verticalCenter
        anchors.rightMargin: Screen.width * 0.010
        font.weight: Font.Medium
    }

}
