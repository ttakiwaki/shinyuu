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
            anchors.centerIn: parent
        }

        FileView {
            id: stateFile
            path: "/home/taki/.config/shinyuu/state.json"
            onLoaded: {
                const cfg = JSON.parse(text())
                anim.source = "file://" + cfg.gif
                anim.scale = cfg.scale
            }
        }
    }
}
