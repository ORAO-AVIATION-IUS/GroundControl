import QtQuick
import QtQuick.Effects

Item {
	id: root

	property double roll: 0
	property double pitch: 0

	readonly property double pitchScale: 2
	readonly property double pixelPerDegree: pitchScale * (face.height / 250.0)
	readonly property double clampedPitch: Math.max(-90, Math.min(90, pitch))

	readonly property double deltaFaceX: pixelPerDegree * clampedPitch * Math.sin(Math.PI * roll / 180.0)
	readonly property double deltaFaceY: pixelPerDegree * clampedPitch * Math.cos(Math.PI * roll / 180.0)

	Item {
		id: face
		anchors.centerIn: parent
		width: Math.min(root.width, root.height)
		height: width

		Rectangle {
			id: circleMask
			anchors.fill: parent
			radius: width / 2
			visible: false
			layer.enabled: true
		}

		Item {
			id: horizonContent
			anchors.fill: parent
			visible: false
			layer.enabled: true

			Image {
				id: horizonBg
				source: "qrc:/resources/assets/attitude_back.svg"
				width: parent.width * 2.5
				height: parent.height * 3
				sourceSize.width: width * 2
				sourceSize.height: height * 2
				fillMode: Image.PreserveAspectCrop
				asynchronous: true
				antialiasing: true
				x: parent.width / 2 - width / 2 + root.deltaFaceX
				y: parent.height / 2 - height / 2 + root.deltaFaceY
				transform: Rotation {
					origin.x: horizonBg.width / 2
					origin.y: horizonBg.height / 2
					angle: -root.roll
				}
			}
		}

		MultiEffect {
			anchors.fill: parent
			source: horizonContent
			maskEnabled: true
			maskSource: circleMask
		}

		Image {
			id: crosshairImg
			source: "qrc:/resources/assets/attitude_pointer.svg"
			anchors.centerIn: parent
			width: parent.width * 0.8
			height: parent.height * 0.8
			fillMode: Image.PreserveAspectFit
			asynchronous: true
			antialiasing: true
			sourceSize.width: width * 2
			sourceSize.height: height * 2
			z: 1
		}

		Image {
			id: frameImg
			source: "qrc:/resources/assets/attitude_frame.svg"
			anchors.fill: parent
			fillMode: Image.PreserveAspectFit
			asynchronous: true
			antialiasing: true
			sourceSize.width: width * 2
			sourceSize.height: height * 2
			z: 2
		}

		Item {
			id: trianglePivot
			anchors.centerIn: parent
			width: parent.width
			height: parent.height
			rotation: root.roll
			z: 3

			Image {
				id: triangleImg
				source: "qrc:/resources/assets/attitude_triangle.svg"
				width: parent.width * 0.1
				height: width
				fillMode: Image.PreserveAspectFit
				asynchronous: true
				antialiasing: true
				sourceSize.width: width * 2
				sourceSize.height: height * 2
				anchors.horizontalCenter: parent.horizontalCenter
				anchors.top: parent.top
				anchors.topMargin: 2
			}
		}
	}
}
