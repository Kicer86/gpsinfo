
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
                    width: parent.width
                    height: 300
                    plugin: mapPlugin
                    center: _position.coordinate
                    zoomLevel: 14
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
