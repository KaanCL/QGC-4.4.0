import QtQuick                  2.12
import QtQuick.Controls         2.12

import QGroundControl.Palette       1.0
import QGroundControl.ScreenTools   1.0
import QtQuick.Window 2.15

Text {

    property var fontPointSize

    font.family:    ScreenTools.normalFontFamily
    color:          qgcPal.text
    antialiasing:   true
    fontPointSize:  fontPointSize
    wrapMode: Text.Wrap
     horizontalAlignment: Text.AlignHCenter

    QGCPalette { id: qgcPal; colorGroupEnabled: enabled }
}
