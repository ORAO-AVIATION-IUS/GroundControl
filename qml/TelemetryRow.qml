import QtQuick 2.15
import QtQuick.Layouts 1.15

RowLayout {
    property string label: ""
    property string value: ""
    width: parent.width

    Text {
        text: label
        color: "#bdc3c7"
        font.pixelSize: 14
        Layout.fillWidth: true
    }
    Text {
        text: value
        color: "#ffffff"
        font.pixelSize: 14
        font.bold: true
    }
}
