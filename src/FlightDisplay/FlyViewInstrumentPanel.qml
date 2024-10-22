/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick 2.12

import QGroundControl               1.0
import QGroundControl.Controls      1.0
import QGroundControl.ScreenTools   1.0

// This control contains the instruments as well and the instrument pages which include values, camera, ...
Column {
    id:         _root
    spacing:    0//_toolsMargin
    z:          QGroundControl.zOrderWidgets

    property real availableHeight

    FlightDisplayViewWidgets {
        id:                 flightDisplayViewWidgets
        width:              parent.width
        missionController:  _missionController
    }
}
