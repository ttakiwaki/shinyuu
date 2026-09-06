// qmllint disable uncreatable-type

import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick

ShellRoot {
    PanelWindow {
        id: window
        visible: true
        anchors {
            bottom: true
            right: true
        }
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.exclusionMode: ExclusionMode.Ignore
        mask: Region {}

        implicitWidth: anim.implicitWidth * anim.scale
        implicitHeight: anim.implicitHeight * anim.scale

        AnimatedImage {
            id: anim
            source: "preview.gif"
            scale: 0.5
            anchors.centerIn: parent
        }
    }
}
