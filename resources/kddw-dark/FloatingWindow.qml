/*
  Dark-themed FloatingWindow for KDDockWidgets.
  Based on the original with dark border.
*/

import QtQuick 2.9

import com.kdab.dockwidgets 2.0
import "." as KDDW

Rectangle {
    id: root
    readonly property FloatingWindowView floatingWindowCpp: parent // qmllint disable incompatible-type
    readonly property TitleBarView titleBarCpp: floatingWindowCpp ? floatingWindowCpp.titleBar : null
    readonly property DropAreaView dropAreaCpp: floatingWindowCpp ? floatingWindowCpp.dropArea : null
    readonly property int titleBarHeight: titleBar.heightWhenVisible
    property int margins: 4

    anchors.fill: parent

    color: "transparent"
    border {
        color: "#30363d"
        width: 1
    }

    onTitleBarHeightChanged: {
        if (floatingWindowCpp)
            floatingWindowCpp.geometryUpdated();
    }

    Loader {
        id: titleBar
        readonly property TitleBarView titleBarCpp: root.titleBarCpp
        readonly property int heightWhenVisible: item.heightWhenVisible // qmllint disable missing-property
        source: Singletons.widgetFactory.titleBarFilename()

        anchors {
            top: parent ? parent.top : undefined
            left: parent ? parent.left : undefined
            right: parent ? parent.right : undefined
            margins: root.margins
        }
    }

    KDDW.DropArea {
        id: dropArea
        dropAreaCpp: root.dropAreaCpp
        anchors {
            left: parent ? parent.left : undefined
            right: parent ? parent.right : undefined
            top: titleBar.bottom
            bottom: parent ? parent.bottom : undefined

            leftMargin: root.margins
            rightMargin: root.margins
            bottomMargin: root.margins
        }
    }

    onDropAreaCppChanged: {
        if (dropAreaCpp) {
            dropAreaCpp.parent = dropArea;
            dropAreaCpp.anchors.fill = dropArea;
        }
    }
}
