
import QtQuick
import QtQuick.Controls
import QtPositioning
import QtLocation

import gpsinfo

ApplicationWindow {
    visible: true

    PositionSource {
        id: positionSource

        active: true
        updateInterval: 3000
    }

    SatellitesModel {
        id: satellitesModel
    }

    property alias _position: positionSource.position
    property bool _altitudeAvailable: _position.altitudeValid  && !isNaN(_position.altitudeValid)
    property bool _speedAvailable: _position.speedValid && !isNaN(_position.speed)
    property bool _gpsAvailable: _position.longitudeValid &&
                                 _position.latitudeValid &&
                                 positionSource.valid;

    Flickable
    {
        id: flick
        anchors.fill: parent

        // The whole app is intentionally non-pannable: user-level pan
        // gestures conflict with interactive Map pinch/drag on touch
        // devices (the Flickable would grab the touch before the Map's
        // handlers could claim it). Layout still sizes content normally,
        // so large screens show everything; small screens simply clip.
        interactive: false

        contentWidth: parent.width
        contentHeight: column.implicitHeight

        Item {                          // container with margins
            anchors.fill: parent
            anchors.margins: 5

            Column {
                id: column

                width: parent.width

                spacing: 20

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter

                    text: _gpsAvailable? qsTr("GPS position acquired"): qsTr("no GPS available")
                    color: _gpsAvailable? "darkGreen": "red"
                }

                GroupBox {
                    width: parent.width

                    title: qsTr("Location") + ":"

                    Grid {

                        anchors.horizontalCenter: parent.horizontalCenter

                        columns: 2
                        spacing: 5
                        horizontalItemAlignment: Grid.AlignRight

                        Text {
                            text: qsTr("latitude") + ":"
                        }

                        Text {
                            text: _position.coordinate.latitude
                        }

                        Text {
                            text: qsTr("longitude") + ":"
                        }

                        Text {
                            text: _position.coordinate.longitude
                        }

                        Text {
                            text: qsTr("accuracy") + ":"
                            font.pixelSize: 14
                        }

                        Text {
                            text: _position.horizontalAccuracyValid?
                                _position.horizontalAccuracy.toFixed(1) + "m" :
                                "--"
                            font.pixelSize: 12
                        }

                        // spacing
                        Item {
                            height: 10
                            width: 10
                        }

                        Item {
                            height: 10
                            width: 10
                        }

                        Text {
                            text: qsTr("altitude") + ":"
                        }

                        Text {
                            text: _altitudeAvailable?
                                _position.coordinate.altitude.toFixed(0) + "m" :
                                "--"
                        }

                        Text {
                            text: qsTr("accuracy") + ":"
                            font.pixelSize: 14
                        }

                        Text {
                            text: _position.verticalAccuracyValid?
                                _position.verticalAccuracy.toFixed(1) + "m" :
                                "--"
                            font.pixelSize: 12
                        }

                        // spacing
                        Item {
                            height: 10
                            width: 10
                        }

                        Item {
                            height: 10
                            width: 10
                        }

                        Text {
                            text: qsTr("speed") + ":"
                        }

                        Text {
                            text: _speedAvailable?
                                (_position.speed * 3.6).toFixed(1) + " km/h" :
                                "--"
                        }
                    }
                }

                GroupBox {
                    width: parent.width

                    title: qsTr("Satellites information") + ":"

                    Grid {
                        anchors.horizontalCenter: parent.horizontalCenter

                        columns: 2
                        spacing: 5
                        horizontalItemAlignment: Grid.AlignRight

                        Text {
                            text: qsTr("Satellites in view") + ":"
                        }

                        Text {
                            text: satellitesModel.inViewSatellites
                        }

                        Text {
                            text: qsTr("Satellites in use") + ":"
                        }

                        Text {
                            text: satellitesModel.inUseSatellites
                        }
                    }
                }

                Plugin {
                    id: mapPlugin
                    name: "osm"
                }

                Map {
                    id: map

                    readonly property color _accent: "#2d7ef7"

                    width: parent.width
                    height: 300

                    plugin: mapPlugin
                    zoomLevel: 14

                    // When true, the map view auto-centers on every new GPS fix.
                    // User pan turns this off; the re-center button turns
                    // it back on. Zoom does not affect it.
                    property bool _followPosition: true

                    Connections {
                        target: positionSource
                        function onPositionChanged() {
                            if (map._followPosition && _gpsAvailable)
                                map.center = _position.coordinate;
                        }
                    }

                    PinchHandler {
                        target: null
                        // Allow this handler to claim the pinch gesture even
                        // if an ancestor (or the Map's internal gesture
                        // machinery on Android) tries to grab it first.
                        grabPermissions: PointerHandler.CanTakeOverFromAnything
                        onScaleChanged: (delta) => {
                            // `delta` is the multiplicative scale change since the
                            // last emission; log2 converts it into zoom-level units
                            // (where +1 = 2x zoom), matching Map.zoomLevel semantics.
                            map.zoomLevel += Math.log2(delta)
                        }
                    }

                    WheelHandler {
                        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                        rotationScale: 1/120
                        property: "zoomLevel"
                    }

                    DragHandler {
                        target: null
                        onActiveChanged: if (active) map._followPosition = false
                        onTranslationChanged: (delta) => {
                            map.pan(-delta.x, -delta.y)
                        }
                    }

                    // Marker showing current GPS position.
                    MapQuickItem {
                        visible: _gpsAvailable
                        coordinate: _position.coordinate
                        anchorPoint.x: marker.width / 2
                        anchorPoint.y: marker.height / 2
                        zoomLevel: 0   // keep constant pixel size regardless of map zoom

                        sourceItem: Rectangle {
                            id: marker
                            width: 18
                            height: 18
                            radius: width / 2
                            color: map._accent
                            border.color: "white"
                            border.width: 3
                            antialiasing: true
                        }
                    }

                    // Re-center button: round crosshair icon in the corner,
                    // as commonly seen in mapping apps.
                    Rectangle {
                        id: recenterButton

                        readonly property bool _inactive: map._followPosition || !_gpsAvailable

                        width: 44
                        height: 44
                        radius: width / 2
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.margins: 10

                        color: recenterMouse.pressed ? "#e0e0e0" : "white"
                        border.color: "#b0b0b0"
                        border.width: 1
                        antialiasing: true
                        opacity: _inactive ? 0.0 : 1.0

                        Behavior on opacity { NumberAnimation { duration: 150 } }

                        Canvas {
                            id: crosshair
                            anchors.fill: parent
                            anchors.margins: 10

                            readonly property color strokeColor: map._accent

                            onPaint: {
                                const ctx = getContext("2d");
                                ctx.reset();
                                const w = width;
                                const h = height;
                                const cx = w / 2;
                                const cy = h / 2;
                                const r = Math.min(w, h) / 2 - 1;

                                ctx.strokeStyle = strokeColor;
                                ctx.lineWidth = 2;
                                ctx.lineCap = "round";

                                // Outer circle
                                ctx.beginPath();
                                ctx.arc(cx, cy, r, 0, 2 * Math.PI);
                                ctx.stroke();

                                // Crosshair lines (with a gap in the middle)
                                const gap = r * 0.35;
                                ctx.beginPath();
                                ctx.moveTo(cx, 0);
                                ctx.lineTo(cx, cy - gap);
                                ctx.moveTo(cx, cy + gap);
                                ctx.lineTo(cx, h);
                                ctx.moveTo(0, cy);
                                ctx.lineTo(cx - gap, cy);
                                ctx.moveTo(cx + gap, cy);
                                ctx.lineTo(w, cy);
                                ctx.stroke();

                                // Center dot
                                ctx.fillStyle = strokeColor;
                                ctx.beginPath();
                                ctx.arc(cx, cy, 1.8, 0, 2 * Math.PI);
                                ctx.fill();
                            }
                        }

                        MouseArea {
                            id: recenterMouse
                            anchors.fill: parent
                            enabled: !recenterButton._inactive
                            onClicked: {
                                map._followPosition = true;
                                map.center = _position.coordinate;
                            }
                        }
                    }
                }

                Text {
                    objectName: "logger"

                    width: parent.width
                    visible: false

                    wrapMode: Text.WrapAnywhere
                }
            }
        }
    }
}
