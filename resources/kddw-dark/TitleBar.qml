import QtQuick 2.9
import QtQuick.Window 2.15
import com.kdab.dockwidgets 2.0

/**
  * Dark-themed title bar for KDDockWidgets.
  */
TitleBarBase {
    id: root

    color: "#161b22"
    heightWhenVisible: 30

    Text {
        id: title
        text: root.title
        color: root.isFocused ? "#ffffff" : "#e6edf3"
        anchors {
            left: parent ? parent.left : undefined
            leftMargin: 8
            verticalCenter: parent ? parent.verticalCenter : undefined
        }
        font.pixelSize: 12
        elide: Text.ElideRight
        anchors.right: buttonRow.left
        anchors.rightMargin: 4
    }

    Row {
        id: buttonRow
        anchors {
            verticalCenter: parent ? parent.verticalCenter : undefined
            right: parent ? parent.right : undefined
            rightMargin: 4
        }
        spacing: 2

        // Minimize
        Rectangle {
            visible: root.minimizeButtonVisible
            width: 24
            height: 24
            radius: 3
            color: minBtn.containsMouse ? "#292e36" : "transparent"

            Text {
                anchors.centerIn: parent
                text: "─"
                color: "#e6edf3"
                font.pixelSize: 14
            }

            MouseArea {
                id: minBtn
                anchors.fill: parent
                hoverEnabled: true
                onClicked: root.minimizeButtonClicked()
            }
        }

        // Float / Dock
        Rectangle {
            visible: root.floatButtonVisible
            width: 24
            height: 24
            radius: 3
            color: floatBtn.containsMouse ? "#292e36" : "transparent"

            Rectangle {
                anchors.centerIn: parent
                width: 10
                height: 10
                radius: 1
                color: "transparent"
                border.color: "#e6edf3"
                border.width: 1.5
            }

            MouseArea {
                id: floatBtn
                anchors.fill: parent
                hoverEnabled: true
                onClicked: root.floatButtonClicked()
            }
        }

        // Maximize
        Rectangle {
            visible: root.maximizeButtonVisible
            width: 24
            height: 24
            radius: 3
            color: maxBtn.containsMouse ? "#292e36" : "transparent"

            Rectangle {
                anchors.centerIn: parent
                width: 10
                height: 10
                radius: 1
                color: "transparent"
                border.color: "#e6edf3"
                border.width: 1.5
            }

            Rectangle {
                anchors.centerIn: parent
                width: 12
                height: 2
                color: "#e6edf3"
                y: parent.y - 1
            }

            MouseArea {
                id: maxBtn
                anchors.fill: parent
                hoverEnabled: true
                onClicked: root.maximizeButtonClicked()
            }
        }

        // Close
        Rectangle {
            width: 24
            height: 24
            radius: 3
            color: closeBtn.containsMouse ? "#f8514940" : "transparent"

            Text {
                anchors.centerIn: parent
                text: "✕"
                color: closeBtn.containsMouse ? "#f85149" : "#e6edf3"
                font.pixelSize: 12
            }

            MouseArea {
                id: closeBtn
                anchors.fill: parent
                hoverEnabled: true
                onClicked: root.closeButtonClicked()
            }
        }
    }
}
