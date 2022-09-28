
project(gps-info)
cmake_minimum_required(VERSION 3.24)

find_package(Qt6 REQUIRED COMPONENTS Quick Positioning)

set(CMAKE_AUTOMOC ON)

qt_add_executable(gps-info
    main.cpp
    satellites_model.cpp
    satellites_model.hpp
)

qt_add_qml_module(gps-info
    URI gpsinfo
    VERSION 1.0
    RESOURCE_PREFIX /
    QML_FILES
        main.qml
)


target_link_libraries(gps-info
    PRIVATE
        Qt::Quick
        Qt::Positioning
)

