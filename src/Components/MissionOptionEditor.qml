import Agc.Style
import QtQuick
import QtQuick.Controls

Item {
	id: root

	property string title: ""
	property string suffix: ""
	property real value: 0
	property bool optionEnabled: false
	property real minimumValue: -1000000
	property real maximumValue: 1000000
	property int decimals: 0

	signal optionEnabledEdited(bool enabled)
	signal valueEdited(real value)

	implicitWidth: 150
	implicitHeight: 24

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

	Row {
		anchors.fill: parent
		spacing: 3

		CheckBox {
			id: toggle
			anchors.verticalCenter: parent.verticalCenter
			width: 22
			height: 22
			checked: root.optionEnabled
			onToggled: root.optionEnabledEdited(checked)
		}

		Text {
			anchors.verticalCenter: parent.verticalCenter
			width: 58
			text: root.title + ":"
			color: root.optionEnabled ? Style.iconBtnLabelColor : Style.sectionLabelColor
			font.pixelSize: 10
		}

		TextInput {
			id: input
			anchors.verticalCenter: parent.verticalCenter
			width: 42
			horizontalAlignment: TextInput.AlignRight
			text: root.formatValue(root.value)
			enabled: root.optionEnabled
			color: root.optionEnabled ? Style.iconBtnLabelColor : Style.sectionLabelColor
			selectedTextColor: "#ffffff"
			selectionColor: Style.iconBtnCheckedBg
			font.pixelSize: 10
			validator: DoubleValidator {
				bottom: root.minimumValue
				top: root.maximumValue
				decimals: root.decimals
			}
			onEditingFinished: root.commit()
			onAccepted: root.commit()
		}

		Text {
			anchors.verticalCenter: parent.verticalCenter
			text: root.suffix
			color: Style.sectionLabelColor
			font.pixelSize: 8
			visible: root.suffix !== ""
		}
	}
}
