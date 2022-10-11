
project(gps-info)
cmake_minimum_required(VERSION 3.24)

find_package(Qt6 REQUIRED COMPONENTS Quick Positioning)

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
)

set_property(TARGET gps-info APPEND PROPERTY QT_ANDROID_PACKAGE_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/android)
set_property(TARGET gps-info APPEND PROPERTY QT_ANDROID_MIN_SDK_VERSION 28)
set_property(TARGET gps-info APPEND PROPERTY QT_ANDROID_TARGET_SDK_VERSION 31)
