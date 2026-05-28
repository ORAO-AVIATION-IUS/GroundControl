/*
  Dark-themed TabBar for KDDockWidgets.
  Tabs fill available space. Float & close buttons overlay the active tab.
  Buttons are placed as siblings of TabBarBase's drag MouseArea (z:10)
  at z:20 so they receive clicks.
*/

import QtQuick 2.9
import QtQuick.Controls 2.9 as Controls
import com.kdab.dockwidgets 2.0

TabBarBase {
    id: root

    function getInternalListView(): Item {
        for (var i = 0; i < tabBar.children.length; ++i) {
            if (tabBar.children[i].toString().startsWith("QQuickListView"))
                return tabBar.children[i];
        }

        console.warn("Couldn't find the internal ListView");
        return null;
    }

    function getTabAtIndex(index) {
        var listView = getInternalListView();
        var content = listView.children[0];

        var curr = 0;
        for (var i = 0; i < content.children.length; ++i) {
            var candidate = content.children[i];
            if (typeof candidate.tabIndex == "undefined") {
                continue;
            }

            if (curr == index)
                return candidate;

            curr++;
        }

        if (index < listView.children.length)
            return listView.children[0].children[index];

        return null;
    }

    function getTabIndexAtPosition(globalPoint) {
        var listView = getInternalListView();
        var content = listView.children[0];

        for (var i = 0; i < content.children.length; ++i) {
            var candidate = content.children[i];
            if (typeof candidate.tabIndex == "undefined") {
                continue;
            }

            var localPt = candidate.mapFromGlobal(globalPoint.x, globalPoint.y);
            if (candidate.contains(localPt)) {
                return i;
            }
        }

        return tabBar.currentIndex;
    }

    implicitHeight: tabBar.implicitHeight

    onCurrentTabIndexChanged: {
        tabBar.currentIndex = root.currentTabIndex;
    }

    Controls.TabBar {
        id: tabBar

        width: parent.width
        position: (root.groupCpp && root.groupCpp.tabsAtBottom) ? Controls.TabBar.Footer : Controls.TabBar.Header

        background: Rectangle {
            color: "#161b22"
        }

        onCurrentIndexChanged: {
            root.currentTabIndex = this.currentIndex;
        }

        Repeater {
            model: root.groupCpp ? root.groupCpp.tabBar.dockWidgetModel : 0
            Controls.TabButton {
                required property int index
                required property string title
                readonly property int tabIndex: index
                text: title

                background: Rectangle {
                    color: index === tabBar.currentIndex ? "#21262d" : "#161b22"

                    Rectangle {
                        visible: index === tabBar.currentIndex
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 2
                        color: "#1f6feb"
                    }
                }

                contentItem: Item {
                    implicitHeight: 28
                    implicitWidth: tabLabel.implicitWidth + 48

                    Text {
                        id: tabLabel
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: 8
                        anchors.rightMargin: 44
                        anchors.verticalCenter: parent.verticalCenter
                        text: title
                        color: index === tabBar.currentIndex ? "#ffffff" : "#e6edf3"
                        font.pixelSize: 12
                        font.bold: index === tabBar.currentIndex
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }

    // Overlay buttons — placed as direct children of TabBarBase root
    // at z:20 so they sit above the drag MouseArea (z:10)
    Row {
        z: 20
        anchors.right: parent.right
        anchors.rightMargin: 4
        anchors.verticalCenter: tabBar.verticalCenter
        spacing: 2
        visible: root.groupCpp && root.count > 0

        // Float button
        Controls.Button {
            width: 22
            height: 22
            padding: 0
            topPadding: 0
            bottomPadding: 0
            leftPadding: 0
            rightPadding: 0

            background: Rectangle {
                color: parent.hovered ? "#292e36" : "transparent"
                radius: 3
            }

            contentItem: Item {
                Rectangle {
                    anchors.centerIn: parent
                    width: 9
                    height: 9
                    radius: 1
                    color: "transparent"
                    border.color: "#e6edf3"
                    border.width: 1.5
                }
            }

            onClicked: {
                // Float/dock current tab
            }
        }

        // Close button
        Controls.Button {
            width: 22
            height: 22
            padding: 0
            topPadding: 0
            bottomPadding: 0
            leftPadding: 0
            rightPadding: 0

            background: Rectangle {
                color: parent.hovered ? "#f8514940" : "transparent"
                radius: 3
            }

            contentItem: Text {
                text: "✕"
                color: parent.hovered ? "#f85149" : "#e6edf3"
                font.pixelSize: 11
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            onClicked: {
                if (root.groupCpp)
                    root.groupCpp.tabBar.closeAtIndex(root.currentTabIndex);
            }
        }
    }
}
