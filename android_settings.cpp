
#include "android_settings.hpp"

#ifdef _ANDROID
#include <QCoreApplication>
#include <QJniObject>
#include <QUrl>
#endif


AndroidSettings::AndroidSettings(QObject* parent):
    QObject(parent)
{
}


void AndroidSettings::openAppDetailsSettings()
{
#ifdef _ANDROID
    // Build: Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
    //               Uri.parse("package:<packageName>"))
    //        .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
    // and start it from the current Activity.
    const QJniObject activity = QNativeInterface::QAndroidApplication::context();
    if (activity.isValid() == false)
        return;

    const QJniObject packageName = activity.callObjectMethod("getPackageName", "()Ljava/lang/String;");
    const QJniObject uriString = QJniObject::fromString(QStringLiteral("package:") + packageName.toString());
    const QJniObject uri = QJniObject::callStaticObjectMethod(
        "android/net/Uri", "parse",
        "(Ljava/lang/String;)Landroid/net/Uri;",
        uriString.object<jstring>());

    const QJniObject action = QJniObject::getStaticObjectField(
        "android/provider/Settings", "ACTION_APPLICATION_DETAILS_SETTINGS",
        "Ljava/lang/String;");

    QJniObject intent("android/content/Intent",
                      "(Ljava/lang/String;Landroid/net/Uri;)V",
                      action.object<jstring>(), uri.object());

    // Required because we start the intent outside of an Activity context
    // path that preserves the task stack.
    constexpr jint FLAG_ACTIVITY_NEW_TASK = 0x10000000;
    intent.callObjectMethod("addFlags", "(I)Landroid/content/Intent;", FLAG_ACTIVITY_NEW_TASK);

    activity.callMethod<void>("startActivity",
                              "(Landroid/content/Intent;)V",
                              intent.object());
#endif
}
