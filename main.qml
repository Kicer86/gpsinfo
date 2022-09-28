
import QtQuick
import QtQuick.Controls
import QtPositioning

ApplicationWindow {
    visible: true

    PositionSource {
        id: positionSource

        active: true
        updateInterval: 3000
    }

    property bool _gpsAvailable: positionSource.sourceError == PositionSource.NoError &&
                                 positionSource.valid;

    property alias _position: positionSource.position

    Column {
        anchors.fill: parent

        spacing: 5

        Text {
            text: _gpsAvailable? qsTr("GPS position acquired"): qsTr("no GPS available")
            color: _gpsAvailable? "darkGreen": "red"
        }

        GroupBox {
            title: qsTr("Location:")

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
                    text: _position.coordinate.altitude
                }

                Text {
                    text: qsTr("speed") + ":"
                }

                Text {
                    text: _position.speed
                }
            }
        }
    }
}
