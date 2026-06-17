find_package(Qt6 REQUIRED COMPONENTS Core Multimedia Qml)
find_package(OpenCV QUIET COMPONENTS core dnn imgproc imgcodecs)

qt_add_library(FlightDisplay STATIC)

target_sources(FlightDisplay
    PRIVATE
        YoloDetectionController.cc
        YoloDetectionController.h
)

target_compile_definitions(FlightDisplay PRIVATE QGC_AI_MODEL_DIR="${CMAKE_SOURCE_DIR}/models")

if(OpenCV_FOUND)
    target_compile_definitions(FlightDisplay PRIVATE QGC_ENABLE_OPENCV_DNN)
    target_link_libraries(FlightDisplay PRIVATE ${OpenCV_LIBS})
endif()

file(GLOB QML_SOURCES RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} ${CMAKE_CURRENT_SOURCE_DIR}/*.qml)
qt_add_qml_module(FlightDisplay
    URI QGroundControl.FlightDisplay
    VERSION 1.0
    QML_FILES ${QML_SOURCES}
    OUTPUT_TARGETS FlightDisplay_targets
    IMPORT_PATH ${QT_QML_OUTPUT_DIRECTORY}
    IMPORTS
        QtQuick
        QtQuick.Controls
        QtQuick.Dialogs
        QtQuick.Layouts
        QtMultimedia

        QtLocation
        QtPositioning
        QtQuick.Window
        QtQml.Models

        QGroundControl
        QGroundControl.Controllers
        QGroundControl.Controls
        QGroundControl.FactSystem
        QGroundControl.FlightDisplay
        QGroundControl.FlightMap
        QGroundControl.Palette
        QGroundControl.ScreenTools
        QGroundControl.Vehicle
)
