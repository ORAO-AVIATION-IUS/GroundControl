import QtQuick
import QtMultimedia

Rectangle {
    id: root

    required property string playerId
    objectName: playerId

    property alias mediaPlayer: player
    property alias videoOutput: video

    width: parent.parent.width;
    height: parent.parent.height;
    color: "black"

    MediaPlayer {
        id: player
        videoOutput: video
        playbackRate: 0
    }

    VideoOutput {
        id: video
        anchors.fill: parent
    }
}