
#ifndef ANDROID_SETTINGS_HPP_INCLUDED
#define ANDROID_SETTINGS_HPP_INCLUDED

#include <QObject>
#include <QtQmlIntegration>


// Small QML-accessible helper for Android-specific system interactions.
// Currently only used to open the app's details settings page so the
// user can re-grant a permission that was previously denied (once the
// user has tapped "Don't ask again", LocationPermission.request() is a
// no-op and the only remaining path is the system settings UI).
// On non-Android platforms the methods are safe no-ops.
class AndroidSettings: public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    explicit AndroidSettings(QObject* parent = nullptr);

    Q_INVOKABLE void openAppDetailsSettings();
};

#endif
