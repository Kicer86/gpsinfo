
import QtQuick
import QtQuick.Controls
import QtPositioning

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

    property bool _gpsAvailable: positionSource.sourceError == PositionSource.NoError &&
                                 positionSource.valid;

    property alias _position: positionSource.position
    property bool _altitudeAvailable: _position.altitudeValid  && !isNaN(_position.altitudeValid)
    property bool _speedAvailable: _position.speedValid && !isNaN(_position.speed)

    Column {
        anchors.fill: parent

        spacing: 5

        Text {
            text: _gpsAvailable? qsTr("GPS position acquired"): qsTr("no GPS available")
            color: _gpsAvailable? "darkGreen": "red"
        }

        GroupBox {
            title: qsTr("Location") + ":"

            Grid {
                columns: 2
                spacing: 5

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
                    text: qsTr("altitude") + ":"
                }

                Text {
                    text: _altitudeAvailable?
                        _position.coordinate.altitude :
                        "--"
                }

                Text {
                    text: qsTr("speed") + ":"
                }

                Text {
                    text: _speedAvailable?
                        _position.speed.toFixed(1) + " m/s (" + (_position.speed * 3.6).toFixed(1) + " km/h)" :
                        "--"
                }
            }
        }

        GroupBox {
            title: qsTr("Satellites information") + ":"

            Grid {
                columns: 2
                spacing: 5

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
    }
}
