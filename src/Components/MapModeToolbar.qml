pragma ComponentBehavior: Bound

import Agc.Style
import QtQuick

Column {
	id: root

	property int mapMode: 0
	property bool followSelectedDrone: false
	property bool canFollowSelectedDrone: false
	property string activePlanningTool: "edit"
	property string activeTrackingTool: ""
	property bool returnHomeAfterMission: false
	property bool landAfterMission: false
	property bool canReturnFromSelectedWaypoint: false

	signal mapModeRequested(int mode)
	signal planningToolRequested(string tool)
	signal followSelectedDroneRequested(bool follow)
	signal trackingToolRequested(string tool)

	spacing: Style.sectionSpacing
	width: childrenRect.width

	ButtonGroup {
		title: "MODE"
		IconButton {
			iconName: "compass"
			label: "Explore"
			checked: root.mapMode === 0
			onClicked: root.mapModeRequested(0)
		}
		IconButton {
			iconName: "flightmode-on"
			label: "Fly"
			checked: root.mapMode === 2
			onClicked: root.mapModeRequested(2)
		}
		IconButton {
			iconName: "routeplanning"
			label: "Plan"
			checked: root.mapMode === 1
			onClicked: root.mapModeRequested(1)
		}
	}

	ButtonGroup {
		title: "TOOLS"
		visible: root.mapMode === 1
		opacity: visible ? 1 : 0
		Behavior on opacity {
			NumberAnimation {
				duration: 150
			}
		}

		IconButton {
			iconName: "edit-select"
			label: "Edit"
			checkable: true
			checked: root.activePlanningTool === "edit"
			onClicked: root.planningToolRequested("edit")
		}
		IconButton {
			iconName: "flag-black"
			label: "WP"
			checkable: true
			checked: root.activePlanningTool === "waypoint"
			onClicked: root.planningToolRequested("waypoint")
		}
		IconButton {
			iconName: "edit-clear"
			label: "Clear"
			onClicked: root.planningToolRequested("clear")
		}
		IconButton {
			// Tri-state end-of-mission action: Normal → Return → Land → Normal
			iconName: root.landAfterMission ? "flightmode-on" : "go-home-large"
			label: root.returnHomeAfterMission ? "Return" : root.landAfterMission ? "Land" : "End: Off"
			checkable: true
			checked: root.returnHomeAfterMission || root.landAfterMission
			enabled: root.canReturnFromSelectedWaypoint
			onClicked: root.planningToolRequested("endaction")
		}
	}

	ButtonGroup {
		title: "TRACK"
		visible: root.mapMode === 2
		opacity: visible ? 1 : 0
		Behavior on opacity {
			NumberAnimation {
				duration: 150
			}
		}

		IconButton {
			iconName: "crosshairs"
			label: "Follow"
			checkable: true
			checked: root.followSelectedDrone
			enabled: root.canFollowSelectedDrone
			onClicked: root.followSelectedDroneRequested(checked)
		}
		IconButton {
			iconName: "mark-location"
			label: "Go\nTarget"
			onClicked: root.trackingToolRequested("focus-go")
		}
		IconButton {
			iconName: "transform-rotate"
			label: "Look\nTarget"
			onClicked: root.trackingToolRequested("focus-look")
		}
		IconButton {
			iconName: "go-home-large"
			label: "Home"
			onClicked: root.trackingToolRequested("focus-home")
		}
	}
}
