import QtQuick
import QtQuick.Controls
import qs.Common
import qs.Widgets

FocusScope {
    id: root

    property var pluginService: null

    implicitHeight: settingsColumn.implicitHeight
    height: implicitHeight

    function saveSettings(key, value) {
        if (pluginService)
            pluginService.savePluginData("dankCalc", key, value)
    }

    function loadSettings(key, defaultValue) {
        if (pluginService)
            return pluginService.loadPluginData("dankCalc", key, defaultValue)
        return defaultValue
    }

    Column {
        id: settingsColumn
        anchors.fill: parent
        anchors.margins: 16
        spacing: Theme.spacingL

        Text {
            text: "Kalkylator"
            font.pixelSize: 18
            font.weight: Font.Bold
            color: "#FFFFFF"
        }

        Text {
            text: "Skriv ett uttryck i launchern så visas svaret överst. Enter kopierar resultatet, Shift+Enter klistrar in det i fönstret under."
            font.pixelSize: 14
            color: "#CCFFFFFF"
            wrapMode: Text.WordWrap
            width: parent.width - 32
        }

        Rectangle {
            width: parent.width - 32
            height: 1
            color: "#30FFFFFF"
        }

        Column {
            spacing: Theme.spacingM
            width: parent.width - 32

            Text {
                text: "Trigger"
                font.pixelSize: 16
                font.weight: Font.Medium
                color: "#FFFFFF"
            }

            Text {
                text: "Lämna tomt för att räkna direkt utan prefix, som Spotlight. Sätt ett prefix om du hellre vill att kalkylatorn bara vaknar när du ber om det."
                font.pixelSize: 12
                color: "#CCFFFFFF"
                wrapMode: Text.WordWrap
                width: parent.width
            }

            Row {
                spacing: Theme.spacingM

                Text {
                    text: "Prefix:"
                    font.pixelSize: 14
                    color: "#FFFFFF"
                    anchors.verticalCenter: parent.verticalCenter
                }

                DankTextField {
                    id: triggerField
                    width: 120
                    height: 40
                    text: root.loadSettings("trigger", "")
                    placeholderText: "(tomt)"
                    backgroundColor: "#30FFFFFF"
                    textColor: "#FFFFFF"

                    onTextEdited: {
                        var t = text.trim()
                        root.saveSettings("trigger", t)
                        root.saveSettings("noTrigger", t === "")
                    }
                }

                Text {
                    text: "t.ex. = eller c"
                    font.pixelSize: 12
                    color: "#AAFFFFFF"
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        Rectangle {
            width: parent.width - 32
            height: 1
            color: "#30FFFFFF"
        }

        Column {
            spacing: Theme.spacingS
            width: parent.width - 32
            bottomPadding: 24

            Text {
                text: "Vad den klarar"
                font.pixelSize: 14
                font.weight: Font.Medium
                color: "#FFFFFF"
            }

            Column {
                spacing: Theme.spacingXS
                leftPadding: 16

                Text {
                    text: "• Räknesätt och parenteser:  (2+3)*4 → 20"
                    font.pixelSize: 12
                    color: "#CCFFFFFF"
                }

                Text {
                    text: "• Potens, högerassociativ:  2^3^2 → 512"
                    font.pixelSize: 12
                    color: "#CCFFFFFF"
                }

                Text {
                    text: "• Procent som man förväntar sig:  200+10% → 220"
                    font.pixelSize: 12
                    color: "#CCFFFFFF"
                }

                Text {
                    text: "• Funktioner:  sqrt, ln, log, sin, cos, tan, min, max, mod, abs, round ..."
                    font.pixelSize: 12
                    color: "#CCFFFFFF"
                }

                Text {
                    text: "• Konstanter:  pi, e, tau"
                    font.pixelSize: 12
                    color: "#CCFFFFFF"
                }

                Text {
                    text: "• Hex och binärt:  0x1f → 31,  0b1010 → 10"
                    font.pixelSize: 12
                    color: "#CCFFFFFF"
                }

                Text {
                    text: "• Svensk decimalkomma:  1,5*2 → 3"
                    font.pixelSize: 12
                    color: "#CCFFFFFF"
                }
            }
        }
    }
}
