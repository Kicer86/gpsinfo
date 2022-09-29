
#include <QFont>
#include <QGuiApplication>
#include <QQmlApplicationEngine>

#include "satellites_model.hpp"


int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    SatellitesModel satellitesModel;

    QFont font = app.font();
    font.setPixelSize(20);
    app.setFont(font);

    QQmlApplicationEngine engine(QUrl("qrc:///gpsinfo/main.qml"));

    return app.exec();
}
