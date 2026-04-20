
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

                    width: parent.width
                    height: 300

                    plugin: mapPlugin
                    zoomLevel: 14

                    // When true, the map view auto-centers on every new GPS fix.
                    // Any user interaction (pan/zoom) turns this off; the
                    // re-center button turns it back on.
                    property bool followPosition: true

                    Component.onCompleted: {
                        if (_gpsAvailable)
                            center = _position.coordinate;
                    }

                    Connections {
                        target: positionSource
                        function onPositionChanged() {
                            if (map.followPosition && _gpsAvailable)
                                map.center = _position.coordinate;
                        }
                    }

                    PinchHandler {
                        target: null
                        onActiveChanged: if (active) map.followPosition = false
                        onScaleChanged: (delta) => {
                            map.zoomLevel += Math.log2(delta)
                        }
                        grabPermissions: PointerHandler.TakeOverForbidden
                    }

                    WheelHandler {
                        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                        rotationScale: 1/120
                        property: "zoomLevel"
                        onWheel: map.followPosition = false
                    }

                    DragHandler {
                        target: null
                        onActiveChanged: if (active) map.followPosition = false
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
                            color: "#2d7ef7"
                            border.color: "white"
                            border.width: 3
                            antialiasing: true
                        }
                    }

                    // Re-center button (only visible when following is off).
                    Button {
                        visible: !map.followPosition && _gpsAvailable
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.margins: 8
                        text: qsTr("Re-center")
                        onClicked: {
                            map.followPosition = true;
                            map.center = _position.coordinate;
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
