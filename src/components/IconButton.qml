import QtQuick 2.6
import "qrc:/src/theme"

Item {
	id: root
	width: Style.iconBtnSize
	height: Style.iconBtnSize + (label !== "" ? labelText.implicitHeight + 2 : 0)

	property string iconName: ""
	property string iconSource: ""
	property string label: ""
	property color labelColor: Style.iconBtnLabelColor
	property int labelSize: Style.iconBtnLabelSize

	signal clicked

	Image {
		id: iconImage
		width: Style.iconBtnSize
		height: Style.iconBtnSize
		anchors.horizontalCenter: parent.horizontalCenter
		fillMode: Image.PreserveAspectFit
		source: root.iconName !== "" ? "image://icon/" + root.iconName : root.iconSource
	}

	Text {
		id: labelText
		anchors.top: iconImage.bottom
		anchors.topMargin: 2
		anchors.horizontalCenter: parent.horizontalCenter
		text: root.label
		color: root.labelColor
		font.pixelSize: root.labelSize
		visible: root.label !== ""
	}

	MouseArea {
		anchors.fill: parent
		onClicked: root.clicked()
	}
}
