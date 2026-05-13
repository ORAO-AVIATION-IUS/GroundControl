import QtMultimedia
import QtQuick

Rectangle {
	id: root

	required property string playerId
	objectName: playerId

	property alias mediaPlayer: player
	property alias videoOutput: video

	anchors.fill: parent
	color: "black"

	MediaPlayer {
		id: player
		videoOutput: video
	}

	VideoOutput {
		id: video
		anchors.fill: parent
	}
}
