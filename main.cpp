
#include <QFont>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>

#include "satellites_model.hpp"

namespace
{
    QObject* logger;
    QString accumulator;

    void qmlOutput(QtMsgType, const QMessageLogContext &, const QString &msg)
    {
        if (logger)
        {
            const auto text = logger->property("text");
            auto textStr = text.toString();

            if (accumulator.isEmpty() == false)
            {
                textStr += accumulator;
                accumulator.clear();
            }

            textStr += msg + '\n';
            logger->setProperty("text", textStr);
        }
        else
            accumulator += msg + '\n';

    }

    QObject* findQmlObject(QQmlApplicationEngine& engine, const QString& objectName)
    {
        QObject* child = nullptr;

        for(auto rootObject: engine.rootObjects())
        {
            child = (rootObject->objectName() == objectName)?
                rootObject :
                rootObject->findChild<QObject*>(objectName);

            if (child != nullptr)
                break;
        }

        return child;
    }
}


int main(int argc, char *argv[])
{
#ifdef _ANDROID
    qInstallMessageHandler(qmlOutput);
#endif

    QGuiApplication app(argc, argv);
    SatellitesModel satellitesModel;

    QFont font = app.font();
    font.setPixelSize(20);
    app.setFont(font);

    QQmlApplicationEngine engine(QUrl("qrc:///gpsinfo/main.qml"));

    logger = findQmlObject(engine, "logger");

#ifndef _ANDROID
    logger->setProperty("visible", false);
#endif

    return app.exec();
}
