cmake_minimum_required(VERSION 3.16)

find_package(Qt6 REQUIRED COMPONENTS Core Network Positioning Sql Concurrent)

set(AIRSPACE_SOURCES
    AirspaceManager.cc
    AirspaceRestrictionValidator.cc
)

set(AIRSPACE_HEADERS
    AirspaceManager.h
    AirspaceRestrictionValidator.h
)

add_library(Airspace STATIC
    ${AIRSPACE_SOURCES}
    ${AIRSPACE_HEADERS}
)

target_link_libraries(Airspace
    PUBLIC
        Qt6::Core
        Qt6::Network
        Qt6::Positioning
        Qt6::Sql
        Qt6::Concurrent
    PRIVATE
        Qt6::CorePrivate
        MAVLink
        FactSystem
        Comms
        Utilities
)

# We still need these include paths because QGC headers often use relative includes 
# or assume they are in the include path without proper target usage in some places.
target_include_directories(Airspace PUBLIC 
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}/..
    ${CMAKE_CURRENT_SOURCE_DIR}/../API
    ${CMAKE_CURRENT_SOURCE_DIR}/../Comms
    ${CMAKE_CURRENT_SOURCE_DIR}/../FactSystem
    ${CMAKE_CURRENT_SOURCE_DIR}/../FirmwarePlugin
    ${CMAKE_CURRENT_SOURCE_DIR}/../Geo
    ${CMAKE_CURRENT_SOURCE_DIR}/../MAVLink
    ${CMAKE_CURRENT_SOURCE_DIR}/../MissionManager
    ${CMAKE_CURRENT_SOURCE_DIR}/../QmlControls
    ${CMAKE_CURRENT_SOURCE_DIR}/../Settings
    ${CMAKE_CURRENT_SOURCE_DIR}/../Utilities
    ${CMAKE_CURRENT_SOURCE_DIR}/../Vehicle
)
