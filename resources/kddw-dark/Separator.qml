import QtQuick 2.6
import com.kdab.dockwidgets 2.0

Rectangle {
    id: root
    anchors.fill: parent
    color: "#30363d"

    readonly property SeparatorView kddwSeparator: parent // qmllint disable incompatible-type

    MouseArea {
        cursorShape: root.kddwSeparator ? (root.kddwSeparator.isVertical ? Qt.SizeVerCursor : Qt.SizeHorCursor) : Qt.SizeHorCursor
        anchors.fill: parent
        onPressed: {
            root.kddwSeparator.onMousePressed();
        }

        onReleased: {
            root.kddwSeparator.onMouseReleased();
        }

        onPositionChanged: mouse => {
            root.kddwSeparator.onMouseMoved(Qt.point(mouse.x, mouse.y));
        }

        onDoubleClicked: {
            root.kddwSeparator.onMouseDoubleClicked();
        }
    }
}
