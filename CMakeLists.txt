
cmake_minimum_required(VERSION 3.24)
project(gps-info)

set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_STANDARD 20)

find_package(Qt6
    REQUIRED COMPONENTS
        Quick
        Positioning
        Location
)

find_package(QtClick QUIET)


if(QT_KNOWN_POLICY_QTP0002)
    qt_policy(SET QTP0002 NEW)
endif()

set(CMAKE_AUTOMOC ON)

qt_add_executable(gps-info
    main.cpp
)

qt_add_qml_module(gps-info
    URI gpsinfo
    VERSION 1.1.2
    RESOURCE_PREFIX /
    QML_FILES
        main.qml
    SOURCES
        satellites_model.cpp
        satellites_model.hpp
)


target_link_libraries(gps-info
    PRIVATE
        Qt::Quick
        Qt::Positioning
        Qt::Location
        $<$<TARGET_EXISTS:QtClick::QtClick>:QtClick::QtClick>
)

if(ANDROID)
    find_package(OpenSSL REQUIRED)
    find_program(MAGICK magick REQUIRED)

    target_compile_definitions(gps-info
        PRIVATE
            _ANDROID
    )

    set_property(TARGET gps-info APPEND PROPERTY QT_ANDROID_PACKAGE_SOURCE_DIR ${CMAKE_CURRENT_BINARY_DIR}/android-input)
    set_property(TARGET gps-info APPEND PROPERTY QT_ANDROID_MIN_SDK_VERSION 28)
    set_property(TARGET gps-info APPEND PROPERTY QT_ANDROID_TARGET_SDK_VERSION 35)
    set_property(TARGET gps-info APPEND PROPERTY QT_ANDROID_VERSION_CODE 9)
    set_property(TARGET gps-info APPEND PROPERTY QT_ANDROID_VERSION_NAME 1.1.2)

    set_property(TARGET gps-info PROPERTY QT_ANDROID_EXTRA_LIBS
        ${OPENSSL_CRYPTO_LIBRARY}
        ${OPENSSL_SSL_LIBRARY}
    )

    # generate bitmaps and android manifest file
    add_custom_command(
        OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/android-input/AndroidManifest.xml
        COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/AndroidManifest.xml ${CMAKE_CURRENT_BINARY_DIR}/android-input/AndroidManifest.xml
        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/AndroidManifest.xml
    )

    set(resolutions 32 48 72 96 144 192)
    set(resolution-names ldpi mdpi hdpi xhdpi xxhdpi xxxhdpi)
    list(LENGTH resolutions count)
    math(EXPR count "${count} - 1")
    set(bitmaps)

    foreach(i RANGE ${count})
        list(GET resolutions ${i} res)
        list(GET resolution-names ${i} name)

        add_custom_command(
            OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/android-input/res/drawable-${name}/icon.png
            COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_CURRENT_BINARY_DIR}/android-input/res/drawable-${name}
            COMMAND ${MAGICK} convert ${CMAKE_CURRENT_SOURCE_DIR}/res/main_ico.svg -resize ${res}x${res} ${CMAKE_CURRENT_BINARY_DIR}/android-input/res/drawable-${name}/icon.png
            DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/res/main_ico.svg
        )

        list(APPEND bitmaps ${CMAKE_CURRENT_BINARY_DIR}/android-input/res/drawable-${name}/icon.png)
    endforeach()

    add_custom_target(prepare_android_config
        DEPENDS
            ${CMAKE_CURRENT_BINARY_DIR}/android-input/AndroidManifest.xml
            ${bitmaps}
    )

    add_dependencies(gps-info prepare_android_config)

    # --- Release signing (AAB for Google Play) --------------------------------
    # Signing is opt-in: enabled when GPS_INFO_ANDROID_KEYSTORE_PATH is set
    # (via -D on the cmake command line or the release build script, which
    # in turn reads environment variables). Never commit credentials.
    set(GPS_INFO_ANDROID_KEYSTORE_PATH       "" CACHE FILEPATH "Path to the Android release keystore (.keystore/.jks).")
    set(GPS_INFO_ANDROID_KEYSTORE_ALIAS      "" CACHE STRING   "Key alias inside the keystore.")
    set(GPS_INFO_ANDROID_KEYSTORE_STORE_PASS "" CACHE STRING   "Keystore password.")
    set(GPS_INFO_ANDROID_KEYSTORE_KEY_PASS   "" CACHE STRING   "Key password (defaults to store password if empty).")

    if(GPS_INFO_ANDROID_KEYSTORE_PATH)
        if(NOT EXISTS "${GPS_INFO_ANDROID_KEYSTORE_PATH}")
            message(FATAL_ERROR "Keystore not found: ${GPS_INFO_ANDROID_KEYSTORE_PATH}")
        endif()
        if(NOT GPS_INFO_ANDROID_KEYSTORE_ALIAS)
            message(FATAL_ERROR "GPS_INFO_ANDROID_KEYSTORE_ALIAS must be set when keystore is provided.")
        endif()
        if(NOT GPS_INFO_ANDROID_KEYSTORE_STORE_PASS)
            message(FATAL_ERROR "GPS_INFO_ANDROID_KEYSTORE_STORE_PASS must be set when keystore is provided.")
        endif()
        if(NOT GPS_INFO_ANDROID_KEYSTORE_KEY_PASS)
            set(GPS_INFO_ANDROID_KEYSTORE_KEY_PASS "${GPS_INFO_ANDROID_KEYSTORE_STORE_PASS}")
        endif()

        set_property(TARGET gps-info PROPERTY QT_ANDROID_SIGN_AAB TRUE)
        set_property(TARGET gps-info PROPERTY QT_ANDROID_SIGN_APK TRUE)
        set_property(TARGET gps-info PROPERTY QT_ANDROID_KEYSTORE_PATH       "${GPS_INFO_ANDROID_KEYSTORE_PATH}")
        set_property(TARGET gps-info PROPERTY QT_ANDROID_KEYSTORE_ALIAS      "${GPS_INFO_ANDROID_KEYSTORE_ALIAS}")
        set_property(TARGET gps-info PROPERTY QT_ANDROID_KEYSTORE_STORE_PASS "${GPS_INFO_ANDROID_KEYSTORE_STORE_PASS}")
        set_property(TARGET gps-info PROPERTY QT_ANDROID_KEYSTORE_KEY_PASS   "${GPS_INFO_ANDROID_KEYSTORE_KEY_PASS}")

        # Also expose as cache variables — some Qt versions read those
        # rather than the target properties when invoking androiddeployqt.
        set(QT_ANDROID_SIGN_AAB TRUE CACHE BOOL "" FORCE)
        set(QT_ANDROID_SIGN_APK TRUE CACHE BOOL "" FORCE)
        set(QT_ANDROID_KEYSTORE_PATH       "${GPS_INFO_ANDROID_KEYSTORE_PATH}"       CACHE FILEPATH "" FORCE)
        set(QT_ANDROID_KEYSTORE_ALIAS      "${GPS_INFO_ANDROID_KEYSTORE_ALIAS}"      CACHE STRING   "" FORCE)
        set(QT_ANDROID_KEYSTORE_STORE_PASS "${GPS_INFO_ANDROID_KEYSTORE_STORE_PASS}" CACHE STRING   "" FORCE)
        set(QT_ANDROID_KEYSTORE_KEY_PASS   "${GPS_INFO_ANDROID_KEYSTORE_KEY_PASS}"   CACHE STRING   "" FORCE)

        message(STATUS "Android release signing ENABLED (keystore: ${GPS_INFO_ANDROID_KEYSTORE_PATH}, alias: ${GPS_INFO_ANDROID_KEYSTORE_ALIAS})")
    else()
        message(STATUS "Android release signing DISABLED (no keystore provided). AAB/APK will be unsigned or signed with the debug key.")
    endif()
endif()
