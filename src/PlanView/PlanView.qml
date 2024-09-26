/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick          2.3
import QtQuick.Controls 2.15
import QtQuick.Dialogs  1.2
import QtLocation       5.3
import QtPositioning    5.3
import QtQuick.Layouts  1.2
import QtQuick.Window   2.2

import QGroundControl                   1.0
import QGroundControl.FlightMap         1.0
import QGroundControl.ScreenTools       1.0
import QGroundControl.Controls          1.0
import QGroundControl.FactSystem        1.0
import QGroundControl.FactControls      1.0
import QGroundControl.Palette           1.0
import QGroundControl.Controllers       1.0
import QGroundControl.ShapeFileHelper   1.0

Item {
    id: _root

    property bool planControlColapsed: false

    readonly property int   _decimalPlaces:             8
    readonly property real  _margin:                    ScreenTools.defaultFontPixelHeight * 0.5
    readonly property real  _toolsMargin:               ScreenTools.defaultFontPixelWidth * 0.75
    readonly property real  _radius:                    ScreenTools.defaultFontPixelWidth  * 0.5
    readonly property real  _rightPanelWidth:           Math.min(parent.width / 3, ScreenTools.defaultFontPixelWidth * 35)
    readonly property var   _defaultVehicleCoordinate:  QtPositioning.coordinate(37.803784, -122.462276)
    readonly property bool  _waypointsOnlyMode:         QGroundControl.corePlugin.options.missionWaypointsOnly

    property var    _planMasterController:              planMasterController
    property var    _missionController:                 _planMasterController.missionController
    property var    _geoFenceController:                _planMasterController.geoFenceController
    property var    _rallyPointController:              _planMasterController.rallyPointController
    property var    _visualItems:                       _missionController.visualItems
    property bool   _lightWidgetBorders:                editorMap.isSatelliteMap
    property bool   _addROIOnClick:                     false
    property bool   _singleComplexItem:                 _missionController.complexMissionItemNames.length === 1
    property int    _editingLayer:                      layerTabBar.currentIndex ? _layers[layerTabBar.currentIndex] : _layerMission
    property int    _toolStripBottom:                   toolStrip.height + toolStrip.y
    property var    _appSettings:                       QGroundControl.settingsManager.appSettings
    property var    _planViewSettings:                  QGroundControl.settingsManager.planViewSettings
    property bool   _promptForPlanUsageShowing:         false
     property var    missionItems:               _controllerValid ? _planMasterController.missionController.visualItems : undefined
    property real   missionDistance:            _controllerValid ? _planMasterController.missionController.missionDistance : NaN
    property real   missionTime:                _controllerValid ? _planMasterController.missionController.missionTime : 0
    property bool   _missionValid:              missionItems !== undefined
    readonly property var       _layers:                [_layerMission, _layerGeoFence, _layerRallyPoints]
    readonly property var       _missionModeLayers:      [_logisticsMission , _observationMission]

    property real   _missionDistance:           _missionValid ? missionDistance : NaN
    property real   _missionTime:               _missionValid ? missionTime : 0

    readonly property int       _layerMission:              1
    readonly property int       _layerGeoFence:             2
    readonly property int       _layerRallyPoints:          3

    property var currentVisualItem : _missionController.currentPlanViewItem

      property string _missionDistanceText:       isNaN(_missionDistance) ?       "-.-" : QGroundControl.unitsConversion.metersToAppSettingsHorizontalDistanceUnits(_missionDistance).toFixed(0) + " " + QGroundControl.unitsConversion.appSettingsHorizontalDistanceUnitsString

    property bool   _controllerValid:           _planMasterController !== undefined && _planMasterController !== null
    property bool   _controllerOffline:         _controllerValid ? _planMasterController.offline : true
    property var    _controllerDirty:           _controllerValid ? _planMasterController.dirty : false
    property var    _controllerSyncInProgress:  _controllerValid ? _planMasterController.syncInProgress : false

    property int currentMissionMode: 0

    property bool missionModesRowVisible:!currentVisualItem.isSurveyItem

    property int buttonSize: Screen.width * 0.07
    property int buttonImageSize : buttonSize - 30

    property int buttonRadius: Screen.width * 0.01

    property int telemetryFontSize:  Screen.width / 135

    readonly property string    _armedVehicleUploadPrompt:  qsTr("Vehicle is currently armed. Do you want to upload the mission to the vehicle?")

    function mapCenter() {
        var coordinate = editorMap.center
        coordinate.latitude  = coordinate.latitude.toFixed(_decimalPlaces)
        coordinate.longitude = coordinate.longitude.toFixed(_decimalPlaces)
        coordinate.altitude  = coordinate.altitude.toFixed(_decimalPlaces)
        return coordinate
    }


    function getMissionTime() {

        if (!_missionTime) {
            return "00:00:00"
        }
        var t = new Date(2021, 0, 0, 0, 0, Number(_missionTime))
        var days = Qt.formatDateTime(t, 'dd')
        var complete

        if (days == 31) {
            days = '0'
            complete = Qt.formatTime(t, 'hh:mm:ss')
        } else {
            complete = days + " days " + Qt.formatTime(t, 'hh:mm:ss')
        }
        return complete
    }



    property bool _firstMissionLoadComplete:    false
    property bool _firstFenceLoadComplete:      false
    property bool _firstRallyLoadComplete:      false
    property bool _firstLoadComplete:           false
    property real   _controllerProgressPct:     _controllerValid ? _planMasterController.missionController.progressPct : 0

    MapFitFunctions {
        id:                         mapFitFunctions  // The name for this id cannot be changed without breaking references outside of this code. Beware!
        map:                        editorMap
        usePlannedHomePosition:     true
        planMasterController:       _planMasterController
    }

    onVisibleChanged: {
        if(visible) {
            editorMap.zoomLevel = QGroundControl.flightMapZoom
            editorMap.center    = QGroundControl.flightMapPosition
            if (!_planMasterController.containsItems) {
                toolStrip.simulateClick(toolStrip.fileButtonIndex)
            }
        }
    }

    Connections {
        target: _appSettings ? _appSettings.defaultMissionItemAltitude : null
        function onRawValueChanged() {
            if (_visualItems.count > 1) {
                mainWindow.showMessageDialog(qsTr("Apply new altitude"),
                                             qsTr("You have changed the default altitude for mission items. Would you like to apply that altitude to all the items in the current mission?"),
                                             StandardButton.Yes | StandardButton.No,
                                             function() { _missionController.applyDefaultMissionAltitude() })
            }
        }
    }

    Component {
        id: promptForPlanUsageOnVehicleChangePopupComponent
        QGCPopupDialog {
            title:      _planMasterController.managerVehicle.isOfflineEditingVehicle ? qsTr("Plan View - Vehicle Disconnected") : qsTr("Plan View - Vehicle Changed")
            buttons:    StandardButton.NoButton

            ColumnLayout {
                QGCLabel {
                    Layout.maximumWidth:    parent.width
                    wrapMode:               QGCLabel.WordWrap
                    text:                   _planMasterController.managerVehicle.isOfflineEditingVehicle ?
                                                qsTr("The vehicle associated with the plan in the Plan View is no longer available. What would you like to do with that plan?") :
                                                qsTr("The plan being worked on in the Plan View is not from the current vehicle. What would you like to do with that plan?")
                }

                QGCButton {
                    Layout.fillWidth:   true
                    text:               _planMasterController.dirty ?
                                            (_planMasterController.managerVehicle.isOfflineEditingVehicle ?
                                                 qsTr("Discard Unsaved Changes") :
                                                 qsTr("Discard Unsaved Changes, Load New Plan From Vehicle")) :
                                            qsTr("Load New Plan From Vehicle")
                    onClicked: {
                        _planMasterController.showPlanFromManagerVehicle()
                        _promptForPlanUsageShowing = false
                        close();
                    }
                }

                QGCButton {
                    Layout.fillWidth:   true
                    text:               _planMasterController.managerVehicle.isOfflineEditingVehicle ?
                                            qsTr("Keep Current Plan") :
                                            qsTr("Keep Current Plan, Don't Update From Vehicle")
                    onClicked: {
                        if (!_planMasterController.managerVehicle.isOfflineEditingVehicle) {
                            _planMasterController.dirty = true
                        }
                        _promptForPlanUsageShowing = false
                        close()
                    }
                }
            }
        }
    }
    PlanMasterController {
        id:         planMasterController
        flyView:    false

        Component.onCompleted: {
            _planMasterController.start()
            _missionController.setCurrentPlanViewSeqNum(0, true)
            globals.planMasterControllerPlanView = _planMasterController
        }

        onPromptForPlanUsageOnVehicleChange: {
            if (!_promptForPlanUsageShowing) {
                _promptForPlanUsageShowing = true
                promptForPlanUsageOnVehicleChangePopupComponent.createObject(mainWindow).open()
            }
        }

        function waitingOnIncompleteDataMessage(save) {
            var saveOrUpload = save ? qsTr("Save") : qsTr("Upload")
            mainWindow.showMessageDialog(qsTr("Unable to %1").arg(saveOrUpload), qsTr("Plan has incomplete items. Complete all items and %1 again.").arg(saveOrUpload))
        }

        function waitingOnTerrainDataMessage(save) {
            var saveOrUpload = save ? qsTr("Save") : qsTr("Upload")
            mainWindow.showMessageDialog(qsTr("Unable to %1").arg(saveOrUpload), qsTr("Plan is waiting on terrain data from server for correct altitude values."))
        }

        function checkReadyForSaveUpload(save) {
            if (readyForSaveState() == VisualMissionItem.NotReadyForSaveData) {
                waitingOnIncompleteDataMessage(save)
                return false
            } else if (readyForSaveState() == VisualMissionItem.NotReadyForSaveTerrain) {
                waitingOnTerrainDataMessage(save)
                return false
            }
            return true
        }

        function upload() {
            if (!checkReadyForSaveUpload(false /* save */)) {
                return
            }
            switch (_missionController.sendToVehiclePreCheck()) {
                case MissionController.SendToVehiclePreCheckStateOk:
                    sendToVehicle()
                    break
                case MissionController.SendToVehiclePreCheckStateActiveMission:
                    mainWindow.showMessageDialog(qsTr("Send To Vehicle"), qsTr("Current mission must be paused prior to uploading a new Plan"))
                    break
                case MissionController.SendToVehiclePreCheckStateFirwmareVehicleMismatch:
                    mainWindow.showMessageDialog(qsTr("Plan Upload"),
                                                 qsTr("This Plan was created for a different firmware or vehicle type than the firmware/vehicle type of vehicle you are uploading to. " +
                                                      "This can lead to errors or incorrect behavior. " +
                                                      "It is recommended to recreate the Plan for the correct firmware/vehicle type.\n\n" +
                                                      "Click 'Ok' to upload the Plan anyway."),
                                                 StandardButton.Ok | StandardButton.Cancel,
                                                 function() { _planMasterController.sendToVehicle() })
                    break
            }
        }

        function loadFromSelectedFile() {
            fileDialog.title =          qsTr("Select Plan File")
            fileDialog.planFiles =      true
            fileDialog.selectExisting = true
            fileDialog.nameFilters =    _planMasterController.loadNameFilters
            fileDialog.openForLoad()
        }

        function saveToSelectedFile() {
            if (!checkReadyForSaveUpload(true /* save */)) {
                return
            }
            fileDialog.title =          qsTr("Save Plan")
            fileDialog.planFiles =      true
            fileDialog.selectExisting = false
            fileDialog.nameFilters =    _planMasterController.saveNameFilters
            fileDialog.openForSave()
        }

        function fitViewportToItems() {
            mapFitFunctions.fitMapViewportToMissionItems()
        }

        function saveKmlToSelectedFile() {
            if (!checkReadyForSaveUpload(true /* save */)) {
                return
            }
            fileDialog.title =          qsTr("Save KML")
            fileDialog.planFiles =      false
            fileDialog.selectExisting = false
            fileDialog.nameFilters =    ShapeFileHelper.fileDialogKMLFilters
            fileDialog.openForSave()
        }
    }

    Connections {
        target: _missionController

        function onNewItemsFromVehicle() {
            if (_visualItems && _visualItems.count !== 1) {
                mapFitFunctions.fitMapViewportToMissionItems()
            }
            _missionController.setCurrentPlanViewSeqNum(0, true)
        }
    }

    function insertSimpleItemAfterCurrent(coordinate) {
        var nextIndex = _missionController.currentPlanViewVIIndex + 1
        _missionController.insertSimpleMissionItem(coordinate, nextIndex, true /* makeCurrentItem */)
    }

    function insertROIAfterCurrent(coordinate) {
        var nextIndex = _missionController.currentPlanViewVIIndex + 1
        _missionController.insertROIMissionItem(coordinate, nextIndex, true /* makeCurrentItem */)
    }

    function insertCancelROIAfterCurrent() {
        var nextIndex = _missionController.currentPlanViewVIIndex + 1
        _missionController.insertCancelROIMissionItem(nextIndex, true /* makeCurrentItem */)
    }

    function insertComplexItemAfterCurrent(complexItemName) {
        var nextIndex = _missionController.currentPlanViewVIIndex + 1
        _missionController.insertComplexMissionItem(complexItemName, mapCenter(), nextIndex, true /* makeCurrentItem */)
    }

    function insertTakeItemAfterCurrent() {
        var nextIndex = _missionController.currentPlanViewVIIndex + 1
        _missionController.insertTakeoffItem(mapCenter(), nextIndex, true /* makeCurrentItem */)
        addWaypointRallyPointAction.checked =true
    }

    function insertLandItemAfterCurrent() {
        var nextIndex = _missionController.currentPlanViewVIIndex + 1
        _missionController.insertLandItem(mapCenter(), nextIndex, true /* makeCurrentItem */)
    }


    function selectNextNotReady() {
        var foundCurrent = false
        for (var i=0; i<_missionController.visualItems.count; i++) {
            var vmi = _missionController.visualItems.get(i)
            if (vmi.readyForSaveState === VisualMissionItem.NotReadyForSaveData) {
                _missionController.setCurrentPlanViewSeqNum(vmi.sequenceNumber, true)
                break
            }
        }
    }

    QGCFileDialog {
        id:             fileDialog
        folder:         _appSettings ? _appSettings.missionSavePath : ""

        property bool planFiles: true    ///< true: working with plan files, false: working with kml file

        onAcceptedForSave: {
            if (planFiles) {
                _planMasterController.saveToFile(file)
            } else {
                _planMasterController.saveToKml(file)
            }
            close()
        }

        onAcceptedForLoad: {
            _planMasterController.loadFromFile(file)
            _planMasterController.fitViewportToItems()
            _missionController.setCurrentPlanViewSeqNum(0, true)
            close()
        }
    }




    Item {
        id:             panel
        anchors.left:   parent.left
        anchors.right:  parent.right
        anchors.top:    parent.top
        anchors.bottom: parent.bottom

        RowLayout{
            id:missionModesRow
            anchors.top: parent.top
            anchors.topMargin: Screen.width * 0.01
            // anchors.right: rightToolStrip.right
             anchors.horizontalCenter: parent.horizontalCenter
            visible :_editingLayer == _layerMission
            z: 3
            spacing: 4

            QGCButton {
                text:               qsTr("Lojistik")
                Layout.fillWidth:   true
                layerInfo: currentMissionMode
                backRadius : 5
                opacity: 0.8
                buttonIndex: 0
                onClicked:{ currentMissionMode = 0
                            console.log(currentMissionMode)
                }
            }

            QGCButton {
                text:               qsTr("Gözlem")
                Layout.fillWidth:   true
                layerInfo: currentMissionMode
                backRadius : 5
                opacity: 0.8
                buttonIndex: 1
                onClicked: {currentMissionMode = 1
                           console.log(currentMissionMode)
                 }
            }

        }

        Rectangle{
            id:  rightControls
            width: ScreenTools.defaultFontPixelWidth * 35
            anchors.right:      uploadPanel.right
            anchors.top:        uploadPanel.visible ? uploadPanel.bottom : parent.top
            anchors.topMargin: Screen.width * 0.01
            z: 3

            Column {
                spacing:            ScreenTools.defaultFontPixelHeight * 0.5
                anchors.left:       parent.left
                anchors.right:      parent.right
                anchors.top:        parent.top
                //-------------------------------------------------------
                // Mission Controls (Expanded)
                QGCTabBar {
                    id:         layerTabBar
                    width:      parent.width
                    visible:    QGroundControl.corePlugin.options.enablePlanViewSelector
                    Component.onCompleted: currentIndex = 0
                    QGCTabButton {
                        text:       qsTr("Görev")
                    }
                    QGCTabButton {
                        text:       qsTr("Sınır")
                        enabled:    _geoFenceController.supported
                    }
                    // QGCTabButton {
                    //     text:       qsTr("Rally")
                    //     enabled:    _rallyPointController.supported
                    // }
                }
            }
    }

        Rectangle{
          id:flightPlan
          width: Screen.width * 0.1
          anchors.top:parent.top
          anchors.left:parent.left
          anchors.leftMargin: Screen.width * 0.01
         anchors.topMargin: Screen.width * 0.01
          height: Screen.width * 0.095
          radius: buttonRadius
           z: 3
          color :"#7A7500"
          opacity: 0.8


          MouseArea{
          anchors.fill: parent
          onClicked:  mainWindow.showFlyView()

          }


          Image {
              id: flightPlanImage
              source:  "/qmlimages/PaperPlane.svg"
              width: buttonImageSize
              sourceSize.height: buttonImageSize
              anchors.horizontalCenter:parent.horizontalCenter
              //fillMode:Image.PreserveAspectFit
              anchors.verticalCenter: parent.verticalCenter

          }

          Text {
              id: flightPlanText
              text: qsTr("Uçuş Ekranı")
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



        FlightMap {
            id:                         editorMap
            anchors.fill:               parent
            mapName:                    "MissionEditor"
            allowGCSLocationCenter:     true
            allowVehicleLocationCenter: true
            planView:                   true

            zoomLevel:                  QGroundControl.flightMapZoom
            center:                     QGroundControl.flightMapPosition

            // This is the center rectangle of the map which is not obscured by tools
            property rect centerViewport:   Qt.rect(_leftToolWidth + _margin,  _margin, editorMap.width - _leftToolWidth - _rightToolWidth - (_margin * 2), (terrainStatus.visible ? terrainStatus.y : height - _margin) - _margin)

            property real _leftToolWidth:       toolStrip.x + toolStrip.width
            property real _rightToolWidth:      rightPanel.width + rightPanel.anchors.rightMargin
            property real _nonInteractiveOpacity:  0.5

            // Initial map position duplicates Fly view position
            Component.onCompleted: editorMap.center = QGroundControl.flightMapPosition

            QGCMapPalette { id: mapPal; lightColors: editorMap.isSatelliteMap }

            onZoomLevelChanged: {
                QGroundControl.flightMapZoom = zoomLevel
            }
            onCenterChanged: {
                QGroundControl.flightMapPosition = center
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    // Take focus to close any previous editing
                    editorMap.focus = true
                    var coordinate = editorMap.toCoordinate(Qt.point(mouse.x, mouse.y), false /* clipToViewPort */)
                    coordinate.latitude = coordinate.latitude.toFixed(_decimalPlaces)
                    coordinate.longitude = coordinate.longitude.toFixed(_decimalPlaces)
                    coordinate.altitude = coordinate.altitude.toFixed(_decimalPlaces)

                    switch (_editingLayer) {
                    case _layerMission:
                        if (addWaypointRallyPointAction.checked) {
                            insertSimpleItemAfterCurrent(coordinate)
                        } else if (_addROIOnClick) {
                            insertROIAfterCurrent(coordinate)
                            _addROIOnClick = false
                        }

                        break
                    case _layerRallyPoints:
                        if (_rallyPointController.supported && addWaypointRallyPointAction.checked) {
                            _rallyPointController.addPoint(coordinate)
                        }
                        break
                    }   

                }
            }

            // Add the mission item visuals to the map
            Repeater {
                model: _missionController.visualItems
                delegate: MissionItemMapVisual {
                    map:         editorMap
                    onClicked:   _missionController.setCurrentPlanViewSeqNum(sequenceNumber, false)
                    opacity:     _editingLayer == _layerMission ? 1 : editorMap._nonInteractiveOpacity
                    interactive: _editingLayer == _layerMission
                    vehicle:     _planMasterController.controllerVehicle
                }
            }

            // Add lines between waypoints
            MissionLineView {
                showSpecialVisual:  _missionController.isROIBeginCurrentItem
                model:              _missionController.simpleFlightPathSegments
                opacity:            _editingLayer == _layerMission ? 1 : editorMap._nonInteractiveOpacity
            }

            // Direction arrows in waypoint lines
            MapItemView {
                model: _editingLayer == _layerMission ? _missionController.directionArrows : undefined

                delegate: MapLineArrow {
                    fromCoord:      object ? object.coordinate1 : undefined
                    toCoord:        object ? object.coordinate2 : undefined
                    arrowPosition:  3
                    z:              QGroundControl.zOrderWaypointLines + 1
                }
            }

            // Incomplete segment lines
            MapItemView {
                model: _missionController.incompleteComplexItemLines

                delegate: MapPolyline {
                    path:       [ object.coordinate1, object.coordinate2 ]
                    line.width: 1
                    line.color: "red"
                    z:          QGroundControl.zOrderWaypointLines
                    opacity:    _editingLayer == _layerMission ? 1 : editorMap._nonInteractiveOpacity
                }
            }

            // UI for splitting the current segment
            MapQuickItem {
                id:             splitSegmentItem
                anchorPoint.x:  sourceItem.width / 2
                anchorPoint.y:  sourceItem.height / 2
                z:              QGroundControl.zOrderWaypointLines + 1
                visible:        _editingLayer == _layerMission

                sourceItem: SplitIndicator {
                    onClicked:  _missionController.insertSimpleMissionItem(splitSegmentItem.coordinate,
                                                                           _missionController.currentPlanViewVIIndex,
                                                                           true /* makeCurrentItem */)
                }

                function _updateSplitCoord() {
                    if (_missionController.splitSegment) {
                        var distance = _missionController.splitSegment.coordinate1.distanceTo(_missionController.splitSegment.coordinate2)
                        var azimuth = _missionController.splitSegment.coordinate1.azimuthTo(_missionController.splitSegment.coordinate2)
                        splitSegmentItem.coordinate = _missionController.splitSegment.coordinate1.atDistanceAndAzimuth(distance / 2, azimuth)
                    } else {
                        coordinate = QtPositioning.coordinate()
                    }
                }

                Connections {
                    target:                 _missionController
                    function onSplitSegmentChanged()  { splitSegmentItem._updateSplitCoord() }
                }

                Connections {
                    target:                 _missionController.splitSegment
                    function onCoordinate1Changed()   { splitSegmentItem._updateSplitCoord() }
                    function onCoordinate2Changed()   { splitSegmentItem._updateSplitCoord() }
                }
            }

            // Add the vehicles to the map
            MapItemView {
                model: QGroundControl.multiVehicleManager.vehicles
                delegate: VehicleMapItem {
                    vehicle:        object
                    coordinate:     object.coordinate
                    map:            editorMap
                    size:           ScreenTools.defaultFontPixelHeight * 3
                    z:              QGroundControl.zOrderMapItems - 1
                }
            }

            GeoFenceMapVisuals {
                map:                    editorMap
                myGeoFenceController:   _geoFenceController
                interactive:            _editingLayer == _layerGeoFence
                homePosition:           _missionController.plannedHomePosition
                planView:               true
                opacity:                _editingLayer != _layerGeoFence ? editorMap._nonInteractiveOpacity : 1
            }

            RallyPointMapVisuals {
                map:                    editorMap
                myRallyPointController: _rallyPointController
                interactive:            _editingLayer == _layerRallyPoints
                planView:               true
                opacity:                _editingLayer != _layerRallyPoints ? editorMap._nonInteractiveOpacity : 1
            }
        }

        ToolStrip {
            id:                 toolStrip
            anchors.margins:    _toolsMargin
            anchors.left:       parent.left
            anchors.top:        flightPlan.bottom
            anchors.topMargin:  Screen.width * 0.01
            z:                  QGroundControl.zOrderWidgets
            maxHeight:          parent.height - toolStrip.y

            readonly property int flyButtonIndex:       0
            readonly property int fileButtonIndex:      1
            readonly property int takeoffButtonIndex:   2
            readonly property int waypointButtonIndex:  3
            readonly property int roiButtonIndex:       4
            readonly property int patternButtonIndex:   5
            readonly property int landButtonIndex:      6
            readonly property int centerButtonIndex:    7

            property bool _isRallyLayer:    _editingLayer == _layerRallyPoints
            property bool _isMissionLayer:  _editingLayer == _layerMission

            ToolStripActionList {
                id: toolStripActionList
                model: [
                    // ToolStripAction {
                    //     text:           qsTr("Fly")
                    //     iconSource:     "/qmlimages/PaperPlane.svg"
                    //     onTriggered:    mainWindow.showFlyView()
                    // },

                    ToolStripAction {
                        text:       qsTr("Kalkış"/*"Takeoff"*/)
                        iconSource: "/res/takeoff.svg"
                        enabled:    _missionController.isInsertTakeoffValid
                        visible:    toolStrip._isMissionLayer && !_planMasterController.controllerVehicle.rover
                        onTriggered: {
                            toolStrip.allAddClickBoolsOff()
                            insertTakeItemAfterCurrent()
                        }
                    },
                    ToolStripAction {
                        id:                 addWaypointRallyPointAction
                        text:                _editingLayer == _layerRallyPoints ? qsTr("İniş "/*"Rally Point"*/) : qsTr("Yer işareti"/*"Waypoint"*/)
                        iconSource:         "/qmlimages/MapAddMission.svg"
                        enabled:            toolStrip._isRallyLayer ? true : _missionController.flyThroughCommandsAllowed
                        visible:            toolStrip._isRallyLayer || (toolStrip._isMissionLayer && currentMissionMode == 0)
                        checkable:          true
                    },
                    ToolStripAction {
                        text:                 qsTr("Gözlem") //_singleComplexItem ? _missionController.complexMissionItemNames[0] : qsTr("Şablon"/*"Pattern"*/)
                        iconSource:         "/qmlimages/MapDrawShape.svg"
                        enabled:            _missionController.flyThroughCommandsAllowed
                        visible:            toolStrip._isMissionLayer && currentMissionMode == 1
                        dropPanelComponent: _singleComplexItem ? undefined : patternDropPanel
                        onTriggered: {
                            toolStrip.allAddClickBoolsOff()
                            if (_singleComplexItem){
                                insertComplexItemAfterCurrent(_missionController.complexMissionItemNames[0])
                            }
                        }
                    },
                    // ToolStripAction {
                    //     text:               _missionController.isROIActive ? qsTr("Cancel ROI") : qsTr("ROI")
                    //     iconSource:         "/qmlimages/MapAddMission.svg"
                    //     enabled:            !_missionController.onlyInsertTakeoffValid
                    //     visible:            toolStrip._isMissionLayer && _planMasterController.controllerVehicle.roiModeSupported
                    //     checkable:          !_missionController.isROIActive
                    //     onCheckedChanged:   _addROIOnClick = checked
                    //     onTriggered: {
                    //         if (_missionController.isROIActive) {
                    //             toolStrip.allAddClickBoolsOff()
                    //             insertCancelROIAfterCurrent()
                    //         }
                    //     }
                    //     property bool myAddROIOnClick: _addROIOnClick
                    //     onMyAddROIOnClickChanged: checked = _addROIOnClick
                    // },
                    ToolStripAction {
                        text:      _planMasterController.controllerVehicle.multiRotor ? qsTr("Dönüş"/*"Return"*/) : qsTr("İniş"/*"Land"*/)
                        iconSource: "/res/rtl.svg"
                        enabled:    _missionController.isInsertLandValid
                        visible:    toolStrip._isMissionLayer && currentMissionMode == 0
                        onTriggered: {
                            toolStrip.allAddClickBoolsOff()
                            insertLandItemAfterCurrent()
                        }
                    },
                    // ToolStripAction {
                    //     text:               qsTr("Ortala"/*"Center"*/)
                    //     iconSource:         "/qmlimages/MapCenter.svg"
                    //     enabled:            true
                    //     visible:            true
                    //     // dropPanelComponent: centerMapDropPanel
                    //     onTriggered: {
                    //         editorMap.center = mapFitFunctions.fitHomePosition()

                    //     }
                    // },
                    ToolStripAction {
                        text:                     qsTr("Dosya"/*"File"*/)
                        enabled:                !_planMasterController.syncInProgress
                        visible:                toolStrip._isMissionLayer
                        showAlternateIcon:      _planMasterController.dirty
                        iconSource:             "/InstrumentValueIcons/folder-white.svg"
                        alternateIconSource:    "/InstrumentValueIcons/folder-white.svg"
                        dropPanelComponent:     syncDropPanel
                    }
                ]
            }

            model: toolStripActionList.model

             function allAddClickBoolsOff() {
                _addROIOnClick =        false
             addWaypointRallyPointAction.checked = false
            }

            onDropped: allAddClickBoolsOff()
        }

        ToolStrip{
            id:rightToolStrip
            anchors.margins:    _toolsMargin
            anchors.right:       parent.right
            anchors.top:        flightPlan.bottom
            anchors.topMargin:  Screen.width * 0.01
            z:  QGroundControl.zOrderWidgets
            visible:_editingLayer == _layerMission ||  _editingLayer == _layerGeoFence
            maxHeight:          parent.height - toolStrip.y

            property bool _isRallyLayer:    _editingLayer == _layerRallyPoints
            property bool _isMissionLayer:  _editingLayer == _layerMission

            ToolStripActionList{
               id: rightToolStripActionList
                 model:[
                     ToolStripAction{
                        text:qsTr("Tümünü\nSil")
                        iconSource: "/res/TrashDelete.svg"
                        enabled:  _geoFenceController.supported
                        visible: _editingLayer == _layerMission

                        onTriggered: {
                            onClicked:   _missionController.removeAll()
                        }
                     },
                     ToolStripAction{
                        text:qsTr("Çokgen")
                        iconSource: "/InstrumentValueIcons/vector_polygon.svg"
                        enabled:  _geoFenceController.supported
                        visible: _editingLayer == _layerGeoFence
                        onTriggered: {
                            var rect = Qt.rect(editorMap.centerViewport.x, editorMap.centerViewport.y, editorMap.centerViewport.width, editorMap.centerViewport.height)
                            var topLeftCoord = editorMap.toCoordinate(Qt.point(rect.x, rect.y), false /* clipToViewPort */)
                            var bottomRightCoord = editorMap.toCoordinate(Qt.point(rect.x + rect.width, rect.y + rect.height), false /* clipToViewPort */)
                            _geoFenceController.addInclusionPolygon(topLeftCoord, bottomRightCoord)

                        }
                     },
                     ToolStripAction{
                        text:qsTr("Dairesel")
                        iconSource: "/InstrumentValueIcons/rec.svg"
                        enabled:  _geoFenceController.supported
                        visible: _editingLayer == _layerGeoFence
                        onTriggered: {
                            var rect = Qt.rect(editorMap.centerViewport.x, editorMap.centerViewport.y, editorMap.centerViewport.width, editorMap.centerViewport.height)
                            var topLeftCoord = editorMap.toCoordinate(Qt.point(rect.x, rect.y), false /* clipToViewPort */)
                            var bottomRightCoord = editorMap.toCoordinate(Qt.point(rect.x + rect.width, rect.y + rect.height), false /* clipToViewPort */)
                           _geoFenceController.addInclusionCircle(topLeftCoord, bottomRightCoord)

                        }
                     }

                 ]
            }
             model: rightToolStripActionList.model
        }



        Rectangle{
         property real fontSize : Screen.width / 185
         id:fenceEditorPanel
         width: ScreenTools.defaultFontPixelWidth * 30
         height:fenceColumn.y + fenceColumn.height + (_margin * 2)
         anchors.right: rightToolStrip.right
         anchors.top: rightToolStrip.bottom
         anchors.topMargin : 4
         color: qgcPal.windowShadeDark
         z:3
         visible :_editingLayer == _layerGeoFence &&
                  (_geoFenceController.circles.count > 0 || _geoFenceController.polygons.count > 0)

         Flickable{
             id: flickable
             width: parent.width
            height: parent.height
            contentWidth: parent.width
            contentHeight: fenceColumn.implicitHeight
              clip: true

         Column{
             id:                 fenceColumn
             anchors.margins:    _margin
             anchors.top:        parent.top
             anchors.left:       parent.left
             anchors.right:      parent.right
             spacing:            _margin

         SectionHeader {
             id:             polygonSection
             anchors.left:   parent.left
             anchors.right:  parent.right
             text:           qsTr("Polygon Fences")
         }

         GridLayout {
             Layout.fillWidth:   true
             columns:            3
             flow:               GridLayout.TopToBottom
             visible:            polygonSection.checked && _geoFenceController.polygons.count > 0

             QGCLabel {
                 text:               qsTr("Inclusion")
                 Layout.column:      0
                 fontPointSize : fenceEditorPanel.fontSize
                 Layout.alignment:   Qt.AlignHCenter
             }

             Repeater {
                 model: _geoFenceController.polygons

                 QGCCheckBox {
                     checked:            object.inclusion
                     onClicked:          object.inclusion = checked
                     Layout.alignment:   Qt.AlignHCenter
                 }
             }

             QGCLabel {
                 text:               qsTr("Edit")
                 Layout.column:      1
                 fontPointSize : fenceEditorPanel.fontSize
                 Layout.alignment:   Qt.AlignHCenter
             }

             Repeater {
                 model: _geoFenceController.polygons

                 QGCRadioButton {
                     checked:            _interactive
                     Layout.alignment:   Qt.AlignHCenter

                     property bool _interactive: object.interactive

                     on_InteractiveChanged: checked = _interactive

                     onClicked: {
                         _geoFenceController.clearAllInteractive()
                         object.interactive = checked
                     }
                 }
             }

             QGCLabel {
                 text:               qsTr("Delete")
                 Layout.column:      2
                 fontPointSize : fenceEditorPanel.fontSize
                 Layout.alignment:   Qt.AlignHCenter
             }

             Repeater {
                 model: _geoFenceController.polygons

                 QGCButton {
                     text:               qsTr("Del")
                     Layout.alignment:   Qt.AlignHCenter
                     onClicked:          _geoFenceController.deletePolygon(index)
                 }
             }
         }
         SectionHeader {
             id:             circleSection
             anchors.left:   parent.left
             anchors.right:  parent.right
             text:           qsTr("Circular Fences")
         }


         GridLayout {
             anchors.left:       parent.left
             anchors.right:      parent.right
             columns:            4
             flow:               GridLayout.TopToBottom
             visible:            circleSection.checked && _geoFenceController.circles.count > 0

             QGCLabel {
                 text:               qsTr("Inclusion")
                 Layout.column:      0
                 fontPointSize : fenceEditorPanel.fontSize
                 Layout.alignment:   Qt.AlignHCenter
             }

             Repeater {
                 model: _geoFenceController.circles

                 QGCCheckBox {
                     checked:            object.inclusion
                     onClicked:          object.inclusion = checked
                     Layout.alignment:   Qt.AlignHCenter
                 }
             }

             QGCLabel {
                 text:               qsTr("Edit")
                 Layout.column:      1
                 fontPointSize : fenceEditorPanel.fontSize
                 Layout.alignment:   Qt.AlignHCenter
             }

             Repeater {
                 model: _geoFenceController.circles

                 QGCRadioButton {
                     checked:            _interactive
                     Layout.alignment:   Qt.AlignHCenter

                     property bool _interactive: object.interactive

                     on_InteractiveChanged: checked = _interactive

                     onClicked: {
                         _geoFenceController.clearAllInteractive()
                         object.interactive = checked
                     }
                 }
             }

             QGCLabel {
                 text:               qsTr("Delete")
                 Layout.column:      3
                 fontPointSize : fenceEditorPanel.fontSize
                 Layout.alignment:   Qt.AlignHCenter
             }

             Repeater {
                 model: _geoFenceController.circles

                 QGCButton {
                     text:               qsTr("Del")
                     Layout.alignment:   Qt.AlignHCenter
                     onClicked:          _geoFenceController.deleteCircle(index)
                 }
             }
         }

      }

         ScrollBar.vertical: ScrollBar {
             parent: flickable.parent
             anchors.top: flickable.top
             anchors.left: flickable.right
             anchors.bottom: flickable.bottom
                }
    }
}

        Rectangle{
            id:uploadPanel
            anchors.top: parent.top
            anchors.right: rightToolStrip.right
            width:Screen.width * 0.18
            height:Screen.height * 0.1
            color:qgcPal.windowShadeDark
            anchors.topMargin: Screen.width * 0.01
            //anchors.horizontalCenter: parent.horizontalCenter
            visible: !_controllerOffline && !_controllerSyncInProgress

        QGCButton {
            id:          uploadButton
            text:        _controllerDirty ? qsTr("Yükleme Gerekli") : qsTr("Görev Yükle")
            enabled:     !_controllerSyncInProgress
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            onClicked:   _planMasterController.upload()
            visible:     !_controllerOffline && !_controllerSyncInProgress && !uploadCompleteText.visible

            PropertyAnimation on opacity {
                easing.type:    Easing.OutQuart
                from:           0.5
                to:             1
                loops:          Animation.Infinite
                running:        _controllerDirty && !_controllerSyncInProgress
                alwaysRunToEnd: true
                duration:       2000
            }
        }

        QGCLabel {
            id:                     uploadCompleteText
            anchors.fill:           parent
            font.pointSize:         ScreenTools.largeFontPointSize
            horizontalAlignment:    Text.AlignHCenter
            verticalAlignment:      Text.AlignVCenter
            text:                   qsTr("Başarılı")
            visible:                false
        }


        Rectangle {
            id:             progressBar
            anchors.left:   parent.left
            anchors.bottom: parent.bottom
            height:         4
            width:          _controllerProgressPct * parent.width
            color:          qgcPal.colorGreen
            visible:        false
        }


    }

        Connections {
            target: _controllerValid ? _planMasterController.missionController : null
            onProgressPctChanged: {
                if (_controllerProgressPct === 1) {
                    uploadCompleteText.visible = true
                    progressBar.visible = false
                    resetProgressTimer.start()
                } else if (_controllerProgressPct > 0) {
                    progressBar.visible = true
                }
            }
        }

        Timer {
            id:             resetProgressTimer
            interval:       5000
            onTriggered: {
                uploadCompleteText.visible = false
            }
        }


        //-----------------------------------------------------------
        // Right pane for mission editing controls
        Rectangle {
            id:                 rightPanel
            height:             parent.height
            width:              _rightPanelWidth
            color:              qgcPal.window
            opacity:            0//layerTabBar.visible ? 0.2 : 0
            anchors.bottom:     parent.bottom
            anchors.top: parent.top
            visible: false
            anchors.topMargin:Screen.width * 0.01
            anchors.right:      parent.right
            anchors.rightMargin: _toolsMargin
        }
        //-------------------------------------------------------
        // Right Panel Controls
        Item {
            anchors.fill:           rightPanel
            anchors.topMargin:      _toolsMargin
            z:3
            visible: false
            DeadMouseArea {
                anchors.fill:   parent
            }
            // Column {
            //     id:                 rightControls
            //     spacing:            ScreenTools.defaultFontPixelHeight * 0.5
            //     anchors.left:       parent.left
            //     anchors.right:      parent.right
            //     anchors.top:        parent.top
            //     //-------------------------------------------------------
            //     // Mission Controls (Expanded)
            //     QGCTabBar {
            //         id:         layerTabBar
            //         width:      parent.width
            //         visible:    QGroundControl.corePlugin.options.enablePlanViewSelector
            //         Component.onCompleted: currentIndex = 0
            //         QGCTabButton {
            //             text:       qsTr("Mission")
            //         }
            //         QGCTabButton {
            //             text:       qsTr("Fence")
            //             enabled:    _geoFenceController.supported
            //         }
            //         QGCTabButton {
            //             text:       qsTr("Rally")
            //             enabled:    _rallyPointController.supported
            //         }
            //     }
            // }
            //-------------------------------------------------------
            // Mission Item Editor
            Item {

                id:                     missionItemEditor
                anchors.left:           parent.left
                anchors.right:          parent.right
                anchors.top:            rightControls.bottom
                anchors.topMargin:      ScreenTools.defaultFontPixelHeight * 0.25
                anchors.bottom:         parent.bottom
                anchors.bottomMargin:   ScreenTools.defaultFontPixelHeight * 0.25
                visible:                _editingLayer == _layerMission && !planControlColapsed


                QGCListView {
                    id:                 missionItemEditorListView
                    anchors.fill:       parent
                    spacing:            ScreenTools.defaultFontPixelHeight / 4
                    orientation:        ListView.Vertical
                    model:               _missionController.visualItems //currentVisualItem
                    cacheBuffer:        Math.max(height * 2, 0)
                    clip:               true
                    currentIndex:       _missionController.currentPlanViewSeqNum
                    highlightMoveDuration: 250
                    visible:            _editingLayer == _layerMission && !planControlColapsed
                    //-- List Elements
                    delegate: MissionItemEditor {
                        id:missionItemEditorListViewObject
                        map:  editorMap
                        masterController:  _planMasterController
                        missionItem:   object
                        width:          missionItemEditorListView.width
                        readOnly:       false
                        onClicked:     {
                         _missionController.setCurrentPlanViewSeqNum(object.sequenceNumber, false)
                        }
                        onRemove: {
                            var removeVIIndex =index
                            _missionController.removeVisualItem(indexToRemove)
                            if (removeVIIndex >= _missionController.visualItems.count) {
                                removeVIIndex--
                            }
                        }
                        onSelectNextNotReadyItem:   selectNextNotReady()
                    }
                }
            }
            // GeoFence Editor
            GeoFenceEditor {
                anchors.top:            rightControls.bottom
                anchors.topMargin:      ScreenTools.defaultFontPixelHeight * 0.25
                anchors.bottom:         parent.bottom
                anchors.left:           parent.left
                anchors.right:          parent.right
                myGeoFenceController:   _geoFenceController
                flightMap:             editorMap
                visible:                _editingLayer == _layerGeoFence
            }

            // Rally Point Editor
            RallyPointEditorHeader {
                id:                     rallyPointHeader
                anchors.top:            rightControls.bottom
                anchors.topMargin:      ScreenTools.defaultFontPixelHeight * 0.25
                anchors.left:           parent.left
                anchors.right:          parent.right
                visible:                _editingLayer == _layerRallyPoints
                controller:             _rallyPointController
            }
            RallyPointItemEditor {
                id:                     rallyPointEditor
                anchors.top:            rallyPointHeader.bottom
                anchors.topMargin:      ScreenTools.defaultFontPixelHeight * 0.25
                anchors.left:           parent.left
                anchors.right:          parent.right
                visible:                _editingLayer == _layerRallyPoints && _rallyPointController.points.count
                rallyPoint:             _rallyPointController.currentRallyPoint
                controller:             _rallyPointController
            }
        }

        QGCLabel {
            // Elevation provider notice on top of terrain plot
            readonly property string _licenseString: QGroundControl.elevationProviderNotice

            id:                         licenseLabel
            visible:                    terrainStatus.visible && _licenseString !== ""
            anchors.bottom:             terrainStatus.top
            anchors.horizontalCenter:   terrainStatus.horizontalCenter
            anchors.bottomMargin:       ScreenTools.defaultFontPixelWidth * 0.5
            font.pointSize:             ScreenTools.smallFontPointSize
            text:                       qsTr("Powered by %1").arg(_licenseString)
        }


        Rectangle{
           id:missionInfos
           width: ScreenTools.defaultFontPixelWidth * 25
           height: Screen.width *0.08
           anchors.bottom: missionPanel.bottom//removeAll.visible ? removeAll.top : missionPanel.top
           anchors.right: missionPanel.left
           anchors.rightMargin: Screen.width * 0.01
           color:qgcPal.windowShadeDark
           opacity: 0.8
           visible: _editingLayer == _layerMission && !planControlColapsed
           DeadMouseArea {
               anchors.fill:   parent
           }
           Column{
               spacing:Screen.width * 0.01
               QGCLabel {
                   id: distanceInfoText
                   text: qsTr("Mesafe: " + _missionDistanceText + "m")
                   font.pointSize:         Screen.Width / 155

               }
                QGCLabel {
                   id: timeInfoText
                   text: qsTr("Zaman: " + getMissionTime() )
                   font.pointSize:         Screen.Width / 155 //ScreenTools.largeFontPointSize

               }

           }


        }

        // Rectangle{
        //     id:removeAll
        //     width: missionInfos.width
        //     height: Screen.width *0.04
        //     anchors.right: missionPanel.right
        //     anchors.bottom: missionPanel.top
        //     anchors.bottomMargin: Screen.width * 0.01
        //     color:qgcPal.windowShadeDark
        //     visible: (_editingLayer == _layerMission && !planControlColapsed) &&_visualItems.count > 1
        //     DeadMouseArea {
        //         anchors.fill:   parent
        //     }
        //     RowLayout{
        //         anchors.left: parent.left
        //         anchors.verticalCenter: parent.verticalCenter
        //         spacing: 2
        //         QGCColoredImage{
        //         id:deleteAll
        //         width: Screen.width * 0.04
        //         height: Screen.width * 0.04
        //         source:"/res/TrashDelete.svg"
        //         QGCMouseArea {
        //             fillItem:   parent
        //             onClicked:   _missionController.removeAll()
        //         }
        //         }
        //         QGCLabel{
        //         text:qsTr("Tümünü Sil")
        //         font.pointSize:         ScreenTools.largeFontPointSize
        //         }
        //     }

        // }


       Item{
           id:missionPanel
           width: ScreenTools.defaultFontPixelWidth * 35
           height: {
               if(currentVisualItem.isTakeoffItem){
                  return  Screen.width * 0.15 //ScreenTools.defaultFontPixelHeight * 5
               }
                   else if (currentVisualItem.isSimpleItem){
                   return Screen.width * 0.15 //ScreenTools.defaultFontPixelHeight * 5
                   }
                       else if (currentVisualItem.isSurveyItem && !currentVisualItem.wizardMode){
                       return Screen.width * 0.24//ScreenTools.defaultFontPixelHeight * 10
                       }
                           else if (currentVisualItem.wizardMode ){
                           return Screen.width * 0.15 //ScreenTools.defaultFontPixelHeight * 4
                           }
                               else if (currentVisualItem.isLandCommand ){
                               return Screen.width * 0.15//ScreenTools.defaultFontPixelHeight * 3
                               }
                                   else{
                                   return Screen.width * 0.18
                                   }
           }
           anchors.bottom:    parent.bottom
           anchors.bottomMargin: Screen.width * 0.01
           anchors.rightMargin: Screen.width * 0.01
           anchors.right: parent.right
           visible:                _editingLayer == _layerMission && !planControlColapsed
           QGCListView {
               id:                 missionItemEditorListViewPanel
               orientation:        ListView.Vertical
               anchors.fill:       parent
               model:               currentVisualItem
               cacheBuffer:        Math.max(height * 2, 0)
               clip:               true
               currentIndex:       _missionController.currentPlanViewSeqNum
               highlightMoveDuration: 250
               visible:            _editingLayer == _layerMission && !planControlColapsed
               //-- List Elements
               delegate: MissionItemEditor {
                   map:            editorMap
                   masterController:  _planMasterController
                   missionItem:    currentVisualItem
                   width:          missionItemEditorListViewPanel.width
                   readOnly:       false
                   onClicked:     {}//_missionController.setCurrentPlanViewSeqNum(currentVisualItem.sequenceNumber, false)
                   onRemove: {
                       _missionController.removeVisualItem(_missionController.getVisualItemIndex(currentVisualItem))
                       if (removeVIIndex >= _missionController.visualItems.count) {
                             removeVIIndex--
                       }
                       }

                   onSelectNextNotReadyItem:   selectNextNotReady()
               }
           }

       }

       ToolStrip{
          id:mapCenterStrip
          anchors.left: toolStrip.right
          anchors.bottom: parent.bottom
          anchors.bottomMargin: Screen.width * 0.01
          z:  QGroundControl.zOrderWidgets
          maxHeight:          parent.height - toolStrip.y

          property bool _isRallyLayer:    _editingLayer == _layerRallyPoints
          property bool _isMissionLayer:  _editingLayer == _layerMission

          ToolStripActionList{
            id:mapCenterStripAction
            model:[
                ToolStripAction {
                    text:               qsTr("Ortala"/*"Center"*/)
                    iconSource:         "/qmlimages/MapCenter.svg"
                    enabled:            true
                    visible:            true
                    // dropPanelComponent: centerMapDropPanel
                    onTriggered: {
                        editorMap.center = mapFitFunctions.fitHomePosition()

                    }
                }

            ]
          }
          model:mapCenterStripAction.model

       }


       TerrainStatus {
                id:                 terrainStatus
                anchors.margins:    _toolsMargin
                anchors.leftMargin: 0
                anchors.left:       parent.left
                anchors.right:      rightToolStrip.right
                anchors.bottom:     parent.bottom
                height:             ScreenTools.defaultFontPixelHeight * 4.5
                missionController:  _missionController
                visible:           false// _internalVisible && _editingLayer === _layerMission && QGroundControl.corePlugin.options.showMissionStatus

            onSetCurrentSeqNum: _missionController.setCurrentPlanViewSeqNum(seqNum, true)

            property bool _internalVisible: _planViewSettings.showMissionItemStatus.rawValue

            function toggleVisible() {
                _internalVisible = !_internalVisible
                _planViewSettings.showMissionItemStatus.rawValue = _internalVisible
            }
        }

        MapScale {
            id:                     mapScale
            anchors.margins:        _toolsMargin
            anchors.top: toolStrip.top
           // anchors.bottom:         terrainStatus.visible ? terrainStatus.top : parent.bottom
            anchors.left:          toolStrip.right// toolStrip.y + toolStrip.height + _toolsMargin > mapScale.y ? toolStrip.right: parent.left
            mapControl:             editorMap
            buttonsOnLeft:          true
            terrainButtonVisible:   _editingLayer === _layerMission
            terrainButtonChecked:   terrainStatus.visible
            onTerrainButtonClicked: terrainStatus.toggleVisible()
        }
    }

    function showLoadFromFileOverwritePrompt(title) {
        mainWindow.showMessageDialog(title,
                                     qsTr("You have unsaved/unsent changes. Loading from a file will lose these changes. Are you sure you want to load from a file?"),
                                     StandardButton.Yes | StandardButton.Cancel,
                                     function() { _planMasterController.loadFromSelectedFile() } )
    }

    Component {
        id: createPlanRemoveAllPromptDialog

        QGCSimpleMessageDialog {
            title:      qsTr("Create Plan")
            text:       qsTr("Are you sure you want to remove current plan and create a new plan? ")
            buttons:    StandardButton.Yes | StandardButton.No

            property var mapCenter
            property var planCreator

            onAccepted: planCreator.createPlan(mapCenter)
        }
    }

    function clearButtonClicked() {
        mainWindow.showMessageDialog(qsTr("Clear"),
                                     qsTr("Are you sure you want to remove all mission items and clear the mission from the vehicle?"),
                                     StandardButton.Yes | StandardButton.Cancel,
                                     function() { _planMasterController.removeAllFromVehicle(); _missionController.setCurrentPlanViewSeqNum(0, true) })
    }

    //- ToolStrip DropPanel Components

    Component {
        id: centerMapDropPanel

        CenterMapDropPanel {
            map:            editorMap
            fitFunctions:   mapFitFunctions
        }
    }

    Component {
        id: patternDropPanel

        ColumnLayout {
            spacing:    ScreenTools.defaultFontPixelWidth * 0.5

            QGCLabel { text: qsTr("Create complex pattern:") }

            Repeater {
                model: _missionController.complexMissionItemNames

                QGCButton {
                    text:               modelData
                    Layout.fillWidth:   true

                    onClicked: {
                        insertComplexItemAfterCurrent(modelData)
                        dropPanel.hide()
                    }
                }
            }
        } // Column
    }

    function downloadClicked(title) {
        if (_planMasterController.dirty) {
            mainWindow.showMessageDialog(title,
                                         qsTr("You have unsaved/unsent changes. Loading from the Vehicle will lose these changes. Are you sure you want to load from the Vehicle?"),
                                         StandardButton.Yes | StandardButton.Cancel,
                                         function() { _planMasterController.loadFromVehicle() })
        } else {
            _planMasterController.loadFromVehicle()
        }
    }

    Component {
        id: syncDropPanel

        ColumnLayout {
            id:         columnHolder
            spacing:    _margin

            property string _overwriteText: qsTr("Plan overwrite")

            QGCLabel {
                id:                 unsavedChangedLabel
                Layout.fillWidth:   true
                wrapMode:           Text.WordWrap
                text:               globals.activeVehicle ?
                                        qsTr("Kaydedilmemiş değişiklikleriniz var. Aracınıza yüklemeli veya bir dosyaya kaydetmelisiniz."/*"You have unsaved changes. You should upload to your vehicle, or save to a file."*/) :
                                         qsTr("Kaydedilmemiş değişiklikleriniz var."/*"You have unsaved changes."*/)
                visible:            _planMasterController.dirty
            }

            // SectionHeader {
            //     id:                 createSection
            //     Layout.fillWidth:   true
            //     text:               qsTr("Create Plan")
            //     showSpacer:         false
            // }

            // GridLayout {
            //     columns:            2
            //     columnSpacing:      _margin
            //     rowSpacing:         _margin
            //     Layout.fillWidth:   true
            //     visible:            createSection.visible

            //     Repeater {
            //         model: _planMasterController.planCreators

            //         Rectangle {
            //             id:     button
            //             width:  ScreenTools.defaultFontPixelHeight * 7
            //             height: planCreatorNameLabel.y + planCreatorNameLabel.height
            //             color:  button.pressed || button.highlighted ? qgcPal.buttonHighlight : qgcPal.button

            //             property bool highlighted: mouseArea.containsMouse
            //             property bool pressed:     mouseArea.pressed

            //             Image {
            //                 id:                 planCreatorImage
            //                 anchors.left:       parent.left
            //                 anchors.right:      parent.right
            //                 source:             object.imageResource
            //                 sourceSize.width:   width
            //                 fillMode:           Image.PreserveAspectFit
            //                 mipmap:             true
            //             }

            //             QGCLabel {
            //                 id:                     planCreatorNameLabel
            //                 anchors.top:            planCreatorImage.bottom
            //                 anchors.left:           parent.left
            //                 anchors.right:          parent.right
            //                 horizontalAlignment:    Text.AlignHCenter
            //                 text:                   object.name
            //                 color:                  button.pressed || button.highlighted ? qgcPal.buttonHighlightText : qgcPal.buttonText
            //             }

            //             QGCMouseArea {
            //                 id:                 mouseArea
            //                 anchors.fill:       parent
            //                 hoverEnabled:       true
            //                 preventStealing:    true
            //                 onClicked:          {
            //                     if (_planMasterController.containsItems) {
            //                         createPlanRemoveAllPromptDialog.createObject(mainWindow, { mapCenter: _mapCenter(), planCreator: object }).open()
            //                     } else {
            //                         object.createPlan(_mapCenter())
            //                     }
            //                     dropPanel.hide()
            //                 }

            //                 function _mapCenter() {
            //                     var centerPoint = Qt.point(editorMap.centerViewport.left + (editorMap.centerViewport.width / 2), editorMap.centerViewport.top + (editorMap.centerViewport.height / 2))
            //                     return editorMap.toCoordinate(centerPoint, false /* clipToViewPort */)
            //                 }
            //             }
            //         }
            //     }
            // }

            SectionHeader {
                id:                 storageSection
                Layout.fillWidth:   true
                text:               qsTr("Storage")
            }

            GridLayout {
                columns:            3
                rowSpacing:         _margin
                columnSpacing:      ScreenTools.defaultFontPixelWidth
                visible:            storageSection.visible

                QGCButton {
                    text:               qsTr("Aç"/*"Open..."*/)
                    Layout.fillWidth:   true
                    enabled:            !_planMasterController.syncInProgress
                    onClicked: {
                        dropPanel.hide()
                        if (_planMasterController.dirty) {
                            showLoadFromFileOverwritePrompt(columnHolder._overwriteText)
                        } else {
                            _planMasterController.loadFromSelectedFile()
                        }
                    }
                }

                QGCButton {
                    text:               qsTr("Kaydet"/*"Save"*/)
                    Layout.fillWidth:   true
                    enabled:            !_planMasterController.syncInProgress && _planMasterController.currentPlanFile !== ""
                    onClicked: {
                        dropPanel.hide()
                        if(_planMasterController.currentPlanFile !== "") {
                            _planMasterController.saveToCurrent()
                        } else {
                            _planMasterController.saveToSelectedFile()
                        }
                    }
                }

                QGCButton {
                    text:               qsTr("Farklı Kaydet"/*"Save As..."*/)
                    Layout.fillWidth:   true
                    enabled:            !_planMasterController.syncInProgress && _planMasterController.containsItems
                    onClicked: {
                        dropPanel.hide()
                        _planMasterController.saveToSelectedFile()
                    }
                }

                // QGCButton {
                //     Layout.columnSpan:  3
                //     Layout.fillWidth:   true
                //     text:               qsTr("Save Mission Waypoints As KML...")
                //     enabled:            !_planMasterController.syncInProgress && _visualItems.count > 1
                //     onClicked: {
                //         // First point does not count
                //         if (_visualItems.count < 2) {
                //             mainWindow.showMessageDialog(qsTr("KML"), qsTr("You need at least one item to create a KML."))
                //             return
                //         }
                //         dropPanel.hide()
                //         _planMasterController.saveKmlToSelectedFile()
                //     }
                // }
            }

            // SectionHeader {
            //     id:                 vehicleSection
            //     Layout.fillWidth:   true
            //     text:               qsTr("Vehicle")
            // }

            // RowLayout {
            //     Layout.fillWidth:   true
            //     spacing:            _margin
            //     visible:            vehicleSection.visible

            //     QGCButton {
            //         text:               qsTr("Upload")
            //         Layout.fillWidth:   true
            //         enabled:            !_planMasterController.offline && !_planMasterController.syncInProgress && _planMasterController.containsItems
            //         visible:            !QGroundControl.corePlugin.options.disableVehicleConnection
            //         onClicked: {
            //             dropPanel.hide()
            //             _planMasterController.upload()
            //         }
            //     }

            //     QGCButton {
            //         text:               qsTr("Download")
            //         Layout.fillWidth:   true
            //         enabled:            !_planMasterController.offline && !_planMasterController.syncInProgress
            //         visible:            !QGroundControl.corePlugin.options.disableVehicleConnection

            //         onClicked: {
            //             dropPanel.hide()
            //             downloadClicked(columnHolder._overwriteText)
            //         }
            //     }

            //     QGCButton {
            //         text:               qsTr("Clear")
            //         Layout.fillWidth:   true
            //         Layout.columnSpan:  2
            //         enabled:            !_planMasterController.offline && !_planMasterController.syncInProgress
            //         visible:            !QGroundControl.corePlugin.options.disableVehicleConnection
            //         onClicked: {
            //             dropPanel.hide()
            //             clearButtonClicked()
            //         }
            //     }
            // }
        }
    }


}
