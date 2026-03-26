import QtQuick
import QtQuick.Effects

Item {
	id: root
	width: 250
	height: 250

	property double roll: 0
	property double pitch: 0

	readonly property double pixelPerDegree: 2
	property double clampedPitch: Math.max(-40, Math.min(40, pitch))

	property double deltaFaceX: (horizonBg.width / 240) * pixelPerDegree * clampedPitch * Math.sin(Math.PI * roll / 180.0)
	property double deltaFaceY: (horizonBg.height / 240) * pixelPerDegree * clampedPitch * Math.cos(Math.PI * roll / 180.0)

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
			source: "qrc:/assets/attitude_back.svg"
			anchors.centerIn: parent
			width: parent.width * 1.45
			height: parent.height * 3.5
            sourceSize.width: width
            sourceSize.height: height
			fillMode: Image.PreserveAspectCrop
			asynchronous: true
			antialiasing: true

			transform: [
				Rotation {
					origin.x: horizonBg.width / 2
					origin.y: horizonBg.height / 2
					angle: -root.roll
				},
				Translate {
					x: root.deltaFaceX
					y: root.deltaFaceY
				}
			]
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
		source: "qrc:/assets/attitude_pointer.svg"
		anchors.centerIn: parent
		width: parent.width * 0.8
		height: parent.height * 0.8
		fillMode: Image.PreserveAspectFit
		asynchronous: true
		antialiasing: true
		z: 1
	}
	Image {
		id: frameImg
		source: "qrc:/assets/attitude_frame.svg"
		anchors.fill: parent
		fillMode: Image.PreserveAspectFit
		asynchronous: true
		antialiasing: true
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
			source: "qrc:/assets/attitude_triangle.svg"
			width: 25
			height: 25
			fillMode: Image.PreserveAspectFit
			asynchronous: true
			antialiasing: true

			anchors.horizontalCenter: parent.horizontalCenter
			anchors.top: parent.top
			anchors.topMargin: 2
		}
	}
}
