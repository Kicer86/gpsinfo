
#include <QGuiApplication>
#include <QQmlApplicationEngine>

#include "satellites_model.hpp"


int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    SatellitesModel satellitesModel;
    QQmlApplicationEngine engine(QUrl("qrc:///gpsinfo/main.qml"));

    return app.exec();
}
