import Agc.Style
import QtQuick

Rectangle {
	id: root

	property string title: ""
	property string suffix: ""
	property real value: 0
	property real minimumValue: -1000000
	property real maximumValue: 1000000
	property int decimals: 0

	signal valueEdited(real value)

	implicitWidth: 54
	implicitHeight: 44
	color: "#141820"
	radius: Style.iconBtnRadius
	border.color: input.activeFocus ? Style.iconBtnCheckedBg : "#2a2f3a"
	border.width: 1

	function formatValue(number) {
		return Number(number).toFixed(decimals);
	}

	function commit() {
		let number = Number(input.text);
		if (isNaN(number))
			number = root.value;
		number = Math.max(root.minimumValue, Math.min(root.maximumValue, number));
		input.text = root.formatValue(number);
		root.valueEdited(number);
	}

	onValueChanged: {
		if (!input.activeFocus)
			input.text = formatValue(value);
	}

	Column {
		anchors.fill: parent
		anchors.margins: 4
		spacing: 2

		Text {
			anchors.horizontalCenter: parent.horizontalCenter
			text: root.title
			color: Style.sectionLabelColor
			font.pixelSize: Style.sectionLabelSize
			font.letterSpacing: 1
		}

		TextInput {
			id: input
			anchors.horizontalCenter: parent.horizontalCenter
			width: parent.width
			horizontalAlignment: TextInput.AlignHCenter
			text: root.formatValue(root.value)
			color: Style.iconBtnLabelColor
			selectedTextColor: "#ffffff"
			selectionColor: Style.iconBtnCheckedBg
			font.pixelSize: 12
			validator: DoubleValidator {
				bottom: root.minimumValue
				top: root.maximumValue
				decimals: root.decimals
			}
			onEditingFinished: root.commit()
			onAccepted: root.commit()
		}

		Text {
			anchors.horizontalCenter: parent.horizontalCenter
			text: root.suffix
			color: Style.sectionLabelColor
			font.pixelSize: 8
			visible: root.suffix !== ""
		}
	}
}
