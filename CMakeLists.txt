
project(gps-info)
cmake_minimum_required(VERSION 3.24)

find_package(Qt6 REQUIRED COMPONENTS Quick Positioning Location)

set(CMAKE_AUTOMOC ON)
set(QT_ANDROID_SIGN_AAB TRUE)

qt_add_executable(gps-info
    main.cpp
)

qt_add_qml_module(gps-info
    URI gpsinfo
    VERSION 1.0
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
)

if(ANDROID)
    find_package(OpenSSL REQUIRED)
    find_program(MAGICK magick REQUIRED)

    set_property(TARGET gps-info APPEND PROPERTY QT_ANDROID_PACKAGE_SOURCE_DIR ${CMAKE_CURRENT_BINARY_DIR}/android-input)
    set_property(TARGET gps-info APPEND PROPERTY QT_ANDROID_MIN_SDK_VERSION 28)
    set_property(TARGET gps-info APPEND PROPERTY QT_ANDROID_TARGET_SDK_VERSION 31)

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
endif()
