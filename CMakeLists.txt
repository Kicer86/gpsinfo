
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

    # Prefer rsvg-convert for SVG rasterization: it renders SVGs directly via
    # librsvg/cairo and avoids ImageMagick's delegate chain, which on many
    # systems shells out to Inkscape and fails with D-Bus errors in headless
    # or sandboxed build environments. Fall back to `magick` if rsvg-convert
    # is not installed.
    find_program(RSVG_CONVERT rsvg-convert)
    if(NOT RSVG_CONVERT)
        find_program(MAGICK magick REQUIRED)
    endif()

    target_compile_definitions(gps-info
        PRIVATE
            _ANDROID
    )

    set_property(TARGET gps-info APPEND PROPERTY QT_ANDROID_PACKAGE_SOURCE_DIR ${CMAKE_CURRENT_BINARY_DIR}/android-input)
    set_property(TARGET gps-info APPEND PROPERTY QT_ANDROID_MIN_SDK_VERSION 28)
    set_property(TARGET gps-info APPEND PROPERTY QT_ANDROID_TARGET_SDK_VERSION 35)
    set_property(TARGET gps-info APPEND PROPERTY QT_ANDROID_COMPILE_SDK_VERSION 37)
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

        if(RSVG_CONVERT)
            set(_convert_cmd ${RSVG_CONVERT} -w ${res} -h ${res} -o ${CMAKE_CURRENT_BINARY_DIR}/android-input/res/drawable-${name}/icon.png ${CMAKE_CURRENT_SOURCE_DIR}/res/main_ico.svg)
        else()
            set(_convert_cmd ${MAGICK} ${CMAKE_CURRENT_SOURCE_DIR}/res/main_ico.svg -resize ${res}x${res} ${CMAKE_CURRENT_BINARY_DIR}/android-input/res/drawable-${name}/icon.png)
        endif()

        add_custom_command(
            OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/android-input/res/drawable-${name}/icon.png
            COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_CURRENT_BINARY_DIR}/android-input/res/drawable-${name}
            COMMAND ${_convert_cmd}
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
    # Signing is opt-in: set GPS_INFO_ANDROID_SIGN=ON (via -D on the cmake
    # command line or the release build script). The actual keystore path,
    # alias and passwords are read by androiddeployqt from environment
    # variables at build time:
    #   QT_ANDROID_KEYSTORE_PATH, QT_ANDROID_KEYSTORE_ALIAS,
    #   QT_ANDROID_KEYSTORE_STORE_PASS, QT_ANDROID_KEYSTORE_KEY_PASS
    # Never commit credentials; pass them via the environment only.
    option(GPS_INFO_ANDROID_SIGN "Sign the Android AAB/APK for release (keystore via env vars)." OFF)

    if(GPS_INFO_ANDROID_SIGN)
        set_property(TARGET gps-info PROPERTY QT_ANDROID_SIGN_AAB TRUE)
        set_property(TARGET gps-info PROPERTY QT_ANDROID_SIGN_APK TRUE)
        # Some Qt versions read the boolean from a cache variable rather than
        # the target property.
        set(QT_ANDROID_SIGN_AAB TRUE CACHE BOOL "" FORCE)
        set(QT_ANDROID_SIGN_APK TRUE CACHE BOOL "" FORCE)
        message(STATUS "Android release signing ENABLED (keystore will be read from QT_ANDROID_KEYSTORE_* env vars at build time).")
    else()
        message(STATUS "Android release signing DISABLED. AAB/APK will be signed with the debug key.")
    endif()
endif()
