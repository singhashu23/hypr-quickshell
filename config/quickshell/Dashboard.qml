 import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io

Popup {
    id: root

    property var colors: null
    property var runner: null
    property bool netActive: false
    property string netIcon: ""
    property string netStatus: ""
    property bool btActive: false
    property string btIcon: ""
    property string vol: "0"
    property string bright: "0"

    focus: true
    modal: false
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    x: 60
    y: parent.height - height - 20
    width: 340
    height: 500
    padding: 20

    background: Rectangle {
        color: root.colors ? root.colors.bg : "#1a1b26"
        radius: 24
        border.color: root.colors ? root.colors.surface : "#24283b"
        border.width: 2
    }

    contentItem: ColumnLayout {
        spacing: 15

        Text {
            text: "Quick Settings"
            color: root.colors ? root.colors.fg : "white"
            font.bold: true
            font.pixelSize: 18
            Layout.bottomMargin: 5
        }

        GridLayout {
            columns: 2
            rowSpacing: 10
            columnSpacing: 10
            Layout.fillWidth: true

            Rectangle {
                Layout.fillWidth: true; implicitHeight: 60; radius: 12
                color: netActive ? (root.colors ? root.colors.blue : "blue") : (root.colors ? root.colors.surface : "grey")
                RowLayout {
                    anchors.fill: parent; anchors.margins: 10; spacing: 10
                    Text { text: netIcon; font.pixelSize: 18; color: netActive ? "black" : "white" }
                    Column {
                        Text { text: netIcon === "󰈀" ? "Ethernet" : "WiFi"; font.bold: true; color: netActive ? "black" : "white" }
                        Text { text: netStatus; font.pixelSize: 10; color: netActive ? "black" : "white"; opacity: 0.8 }
                    }
                }
                MouseArea { anchors.fill: parent; onClicked: runner.run(["nmcli", "radio", "wifi", netIcon === "󰖪" ? "on" : "off"]) }
            }

            Rectangle {
                Layout.fillWidth: true; implicitHeight: 60; radius: 12
                color: btActive ? (root.colors ? root.colors.blue : "blue") : (root.colors ? root.colors.surface : "grey")
                RowLayout {
                    anchors.fill: parent; anchors.margins: 10; spacing: 10
                    Text { text: btIcon; font.pixelSize: 18; color: btActive ? "black" : "white" }
                    Column {
                        Text { text: "Bluetooth"; font.bold: true; color: btActive ? "black" : "white" }
                        Text { text: btActive ? "On" : "Off"; font.pixelSize: 10; color: btActive ? "black" : "white"; opacity: 0.8 }
                    }
                }
                MouseArea { anchors.fill: parent; onClicked: runner.run(["bluetoothctl", "power", btActive ? "off" : "on"]) }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true; spacing: 10
            RowLayout {
                spacing: 12
                Text { text: "󰕾"; color: root.colors ? root.colors.blue : "white"; font.pixelSize: 18 }
                Slider {
                    Layout.fillWidth: true; from: 0; to: 100; value: Number(vol)
                    onMoved: runner.run(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", (value / 100).toFixed(2)])
                }
            }
            RowLayout {
                spacing: 12
                Text { text: "󰃠"; color: root.colors ? root.colors.yellow : "white"; font.pixelSize: 18 }
                Slider {
                    Layout.fillWidth: true; from: 0; to: 100; value: Number(bright)
                    onMoved: runner.run(["brightnessctl", "s", Math.round(value) + "%"])
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true; implicitHeight: 100; radius: 16; color: root.colors ? root.colors.surface : "grey"
            RowLayout {
                anchors.fill: parent; anchors.margins: 15; spacing: 15
                Rectangle { width: 60; height: 60; radius: 8; color: "black"; Text { anchors.centerIn: parent; text: "󰎆"; color: "white"; font.pixelSize: 24 } }
                ColumnLayout {
                    Text { text: "System Audio"; color: root.colors ? root.colors.fg : "white"; font.bold: true }
                    RowLayout { spacing: 15; Text { text: "󰒮"; color: "white" }
                    Text { text: "󰐊"; color: "white"; font.pixelSize: 22 }
                    Text { text: "󰒭"; color: "white" } }
                }
            }
        }
    }
}
