import QtQuick          2.3
import QtQuick.Window 2.2
import QtQuick.Controls 1.2
import QtQuick.Layouts  1.2
import QtQuick.Dialogs  1.2

import QGroundControl                   1.0
import QGroundControl.ScreenTools       1.0
import QGroundControl.Controls          1.0
import QGroundControl.FactControls      1.0
import QGroundControl.Palette           1.0

// Toolbar for Plan View
Rectangle {
    id:                 _root
    width:             parent.width
    height:           Screen.width * 0.08
    color:            qgcPal.window


    property var    planMasterController

    property var    _activeVehicle:         QGroundControl.multiVehicleManager.activeVehicle
    property real   _controllerProgressPct: planMasterController.missionController.progressPct
     property int toolBarTextSize : Screen.width / 125

    /// Bottom single pixel divider
    Rectangle {
        anchors.left:   parent.left
        anchors.right:  parent.right
        anchors.bottom: parent.bottom
        height:         1
        color:          "black"
        visible:        qgcPal.globalTheme === QGCPalette.Light
    }
    RowLayout {
          id:                     viewButtonRow
          anchors.bottomMargin:   1
          anchors.top:            parent.top
          anchors.bottom:         parent.bottom
          spacing:                ScreenTools.defaultFontPixelWidth / 2

        QGCToolBarButton {
            id:                  currentButton
            Layout.fillHeight:  true
            icon.source:        "/qmlimages/PaperPlane.svg"
            checked:            false
            onClicked: {
                checked = false
                mainWindow.showFlyView()
            }
        }

        QGCToolBarButton {
           id:                     settingsButton
           Layout.preferredHeight: viewButtonRow.height
           icon.source:           "/res/gear-white.svg"
           logo:                   true
           onClicked:             mainWindow.showSettingsTool()
       }

        QGCToolBarButton {
           id:                     folderButton
           Layout.preferredHeight: viewButtonRow.height
           icon.source:           "/InstrumentValueIcons/folder-white.svg"
           logo:                   true
           onClicked: folderSettingsDialog.visible = !folderSettingsDialog.visible
       }

        QGCButton {
            text:               qsTr("Lojistik")
            Layout.fillWidth:   true
            onClicked:{ currentMissionMode = 0
                        console.log(currentMissionMode)
            }


        }

        QGCButton {
            text:               qsTr("Gözlem")
            Layout.fillWidth:   true
            onClicked: {currentMissionMode = 1
                       console.log(currentMissionMode)
             }
        }



        Loader {
            source:             "PlanToolBarIndicators.qml"
            Layout.fillWidth:   true
            Layout.fillHeight:  true
        }
    }
}

