
import QtQuick 2.12
import QtQuick.Controls 2.12

ApplicationWindow {
    visible: true

    Text {
        id: rozhowor
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter

        text: "Rozhowor"
        font.pixelSize: 20
        color: "red"
    }

    SequentialAnimation {

        running: true
        loops:   Animation.Infinite

        NumberAnimation {
            target: rozhowor
            property: "font.pixelSize"
            from: 12
            to: 36
            duration: 500
            easing.type: Easing.InOutQuad
        }

        NumberAnimation {
            target: rozhowor
            property: "font.pixelSize"
            from: 36
            to: 12
            duration: 500
            easing.type: Easing.InOutQuad
        }
    }
}
