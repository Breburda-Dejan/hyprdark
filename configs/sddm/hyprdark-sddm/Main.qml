// hyprdark — minimal monochrome SDDM theme
// Pure QtQuick (no Controls styles): works on Qt5 and Qt6 sddm builds.
import QtQuick 2.15

Rectangle {
    id: root
    color: "#060607"

    property int sessionIndex: sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0

    // ── background ──────────────────────────────────────────────────────────
    Image {
        anchors.fill: parent
        source: config.background
        fillMode: Image.PreserveAspectCrop
        smooth: true
    }
    Rectangle {          // darken for contrast
        anchors.fill: parent
        color: "#000000"
        opacity: 0.42
    }

    // ── clock ───────────────────────────────────────────────────────────────
    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: parent.height * 0.14
        spacing: 6

        Text {
            id: clock
            anchors.horizontalCenter: parent.horizontalCenter
            color: "#e8e8e8"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 84
            font.bold: true
            text: Qt.formatTime(new Date(), "HH:mm")
        }
        Text {
            id: dateText
            anchors.horizontalCenter: parent.horizontalCenter
            color: "#9a9a9a"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 18
            text: Qt.formatDate(new Date(), "dddd, d MMMM")
        }
    }
    Timer {
        interval: 1000; running: true; repeat: true
        onTriggered: {
            clock.text = Qt.formatTime(new Date(), "HH:mm")
            dateText.text = Qt.formatDate(new Date(), "dddd, d MMMM")
        }
    }

    // ── login card ──────────────────────────────────────────────────────────
    Rectangle {
        id: card
        width: 340
        height: col.height + 48
        anchors.centerIn: parent
        anchors.verticalCenterOffset: parent.height * 0.12
        radius: 16
        color: Qt.rgba(0.047, 0.047, 0.051, 0.88)
        border.color: "#2e2e2e"
        border.width: 2

        Column {
            id: col
            width: parent.width - 48
            anchors.centerIn: parent
            spacing: 14

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                color: "#e8e8e8"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 15
                text: "  " + (userField.text.length > 0 ? userField.text : "login")
            }

            // username
            Rectangle {
                width: parent.width; height: 44; radius: 10
                color: "#141414"
                border.color: userField.activeFocus ? "#e8e8e8" : "#2e2e2e"
                border.width: 1.5
                TextInput {
                    id: userField
                    anchors.fill: parent
                    anchors.margins: 12
                    verticalAlignment: TextInput.AlignVCenter
                    color: "#e8e8e8"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 14
                    clip: true
                    selectByMouse: true
                    text: userModel.lastUser
                    KeyNavigation.tab: passField
                    KeyNavigation.down: passField
                    Keys.onReturnPressed: passField.forceActiveFocus()
                    Keys.onEnterPressed: passField.forceActiveFocus()
                }
            }

            // password
            Rectangle {
                width: parent.width; height: 44; radius: 10
                color: "#141414"
                border.color: passField.activeFocus ? "#e8e8e8" : "#2e2e2e"
                border.width: 1.5
                TextInput {
                    id: passField
                    anchors.fill: parent
                    anchors.margins: 12
                    verticalAlignment: TextInput.AlignVCenter
                    color: "#ffffff"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 14
                    clip: true
                    selectByMouse: true
                    echoMode: TextInput.Password
                    passwordCharacter: "•"
                    KeyNavigation.tab: userField
                    KeyNavigation.up: userField
                    Keys.onReturnPressed: root.tryLogin()
                    Keys.onEnterPressed: root.tryLogin()
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    visible: passField.text.length === 0 && !passField.activeFocus
                    color: "#5a5a5a"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 14
                    text: "password…"
                }
            }

            // login button
            Rectangle {
                id: loginBtn
                width: parent.width; height: 44; radius: 10
                color: loginArea.containsMouse ? "#ffffff" : "#e8e8e8"
                Text {
                    anchors.centerIn: parent
                    color: "#0a0a0a"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 14
                    font.bold: true
                    text: "login  ↵"
                }
                MouseArea {
                    id: loginArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.tryLogin()
                }
            }

            Text {
                id: message
                anchors.horizontalCenter: parent.horizontalCenter
                color: "#ffffff"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 12
                text: " "
            }
        }
    }

    // ── session name, bottom-left ───────────────────────────────────────────
    Text {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: 26
        color: "#6a6a6a"
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 13
        text: sessionModel.data(sessionModel.index(root.sessionIndex, 0), Qt.UserRole + 4) || "session"
    }

    // ── power buttons, bottom-right ─────────────────────────────────────────
    Row {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 22
        spacing: 10

        Rectangle {
            width: 42; height: 42; radius: 10
            color: rebootArea.containsMouse ? "#e8e8e8" : Qt.rgba(0.047, 0.047, 0.051, 0.88)
            border.color: "#2e2e2e"; border.width: 1.5
            visible: sddm.canReboot
            Text {
                anchors.centerIn: parent
                color: rebootArea.containsMouse ? "#0a0a0a" : "#e8e8e8"
                font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 17
                text: ""
            }
            MouseArea { id: rebootArea; anchors.fill: parent; hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor; onClicked: sddm.reboot() }
        }
        Rectangle {
            width: 42; height: 42; radius: 10
            color: powerArea.containsMouse ? "#e8e8e8" : Qt.rgba(0.047, 0.047, 0.051, 0.88)
            border.color: "#2e2e2e"; border.width: 1.5
            visible: sddm.canPowerOff
            Text {
                anchors.centerIn: parent
                color: powerArea.containsMouse ? "#0a0a0a" : "#e8e8e8"
                font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 17
                text: "⏻"
            }
            MouseArea { id: powerArea; anchors.fill: parent; hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor; onClicked: sddm.powerOff() }
        }
    }

    // ── behavior ────────────────────────────────────────────────────────────
    function tryLogin() {
        message.text = " "
        sddm.login(userField.text, passField.text, root.sessionIndex)
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            message.text = "login failed — try again"
            passField.text = ""
            passField.forceActiveFocus()
        }
    }

    Component.onCompleted: {
        if (userField.text.length > 0) passField.forceActiveFocus()
        else userField.forceActiveFocus()
    }
}
