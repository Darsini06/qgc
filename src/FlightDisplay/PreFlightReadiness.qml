import QtQuick

import QGroundControl
import QGroundControl.Controls
import QGroundControl.Controllers
import QGroundControl.Vehicle

Item {
    id: root
    visible: false
    width: 0
    height: 0

    property var vehicle: QGroundControl.multiVehicleManager.activeVehicle
    property var appWindow: null
    property var _appSettings: QGroundControl.settingsManager.appSettings
    property int refreshTick: 0

    property string weatherState: qsTr("Waiting")
    property string weatherDetail: qsTr("Waiting for a valid vehicle position.")
    property real weatherWindSpeed: NaN
    property real weatherTemperature: NaN
    property int weatherCode: -1

    readonly property var healthReport: vehicle ? vehicle.healthAndArmingCheckReport : null
    readonly property var parameterManager: vehicle ? vehicle.parameterManager : null
    readonly property var battery: vehicle && vehicle.batteries && vehicle.batteries.count > 0 ? vehicle.batteries.get(0) : null
    readonly property real batteryPercent: battery && battery.percentRemaining && !isNaN(Number(battery.percentRemaining.rawValue))
                                                   ? Number(battery.percentRemaining.rawValue) : NaN
    readonly property int gpsFix: vehicle && vehicle.gps ? Number(vehicle.gps.lock.rawValue) : 0
    readonly property int satelliteCount: vehicle && vehicle.gps ? Number(vehicle.gps.count.rawValue) : 0
    readonly property bool gpsRequired: vehicle ? vehicle.requiresGpsFix : false
    readonly property bool compassPresent: vehicle ? !!(vehicle.sensorsPresentBits & Vehicle.SysStatusSensor3dMag) : false
    readonly property bool compassHealthy: vehicle ? !(vehicle.sensorsUnhealthyBits & Vehicle.SysStatusSensor3dMag) : false
    readonly property bool linkLost: vehicle ? vehicle.vehicleLinkManager.communicationLost : true
    readonly property bool parametersReady: parameterManager ? parameterManager.parametersReady : false
    readonly property int radioRssi: vehicle ? Math.max(Number(vehicle.telemetryLRSSI), Number(vehicle.telemetryRRSSI)) : 0
    readonly property bool radioAvailable: radioRssi !== 0
    readonly property bool firmwareKnown: vehicle ? vehicle.firmwareMajorVersion >= 0 : false
    readonly property bool inRestrictedZone: vehicle && vehicle.coordinate && vehicle.coordinate.isValid &&
                                             QGroundControl.airspaceManager
                                             ? QGroundControl.airspaceManager.isCoordinateInRedZone(vehicle.coordinate) : false
    readonly property bool geofenceConfigured: _geofenceConfigured()
    readonly property bool logisticsProfile: appWindow && appWindow.droneType === "Logistics"
    readonly property bool payloadOverweight: logisticsProfile && appWindow.logisticsPayloadWeight > appWindow.logisticsMaxPayloadWeight
    readonly property bool payloadReady: !logisticsProfile || (appWindow._logisticsPayloadChecklistReady &&
                                                               appWindow._logisticsPayloadChecklistReady())

    readonly property bool connectionCritical: !vehicle || !vehicle.initialConnectComplete || !parametersReady
    readonly property bool healthCritical: vehicle && healthReport && healthReport.supported
                                           ? !healthReport.canArm
                                           : (vehicle
                                              ? (vehicle.readyToFlyAvailable
                                                 ? !vehicle.readyToFly
                                                 : vehicle.prearmError.length > 0)
                                              : true)
    readonly property bool batteryCritical: !isNaN(batteryPercent) && batteryPercent < 20
    readonly property bool gpsCritical: gpsRequired && gpsFix < 3
    readonly property bool compassCritical: compassPresent && !compassHealthy
    readonly property bool linkCritical: linkLost
    readonly property bool airspaceCritical: inRestrictedZone
    readonly property bool payloadCritical: logisticsProfile && (payloadOverweight || !payloadReady)

    readonly property bool criticalReady: !!vehicle &&
                                          !connectionCritical &&
                                          !healthCritical &&
                                          !batteryCritical &&
                                          !gpsCritical &&
                                          !compassCritical &&
                                          !linkCritical &&
                                          !airspaceCritical &&
                                          !payloadCritical

    readonly property int criticalCount: (connectionCritical ? 1 : 0) +
                                         (healthCritical ? 1 : 0) +
                                         (batteryCritical ? 1 : 0) +
                                         (gpsCritical ? 1 : 0) +
                                         (compassCritical ? 1 : 0) +
                                         (linkCritical ? 1 : 0) +
                                         (airspaceCritical ? 1 : 0) +
                                         (payloadCritical ? 1 : 0)

    readonly property int warningCount: (batteryWarning ? 1 : 0) +
                                        (gpsWarning ? 1 : 0) +
                                        (compassWarning ? 1 : 0) +
                                        (linkWarning ? 1 : 0) +
                                        (firmwareWarning ? 1 : 0) +
                                        (storageWarning ? 1 : 0) +
                                        (geofenceWarning ? 1 : 0) +
                                        (weatherWarning ? 1 : 0)

    readonly property bool batteryWarning: !batteryCritical && (isNaN(batteryPercent) || batteryPercent < 40)
    readonly property bool gpsWarning: !gpsCritical && gpsRequired && satelliteCount < 8
    readonly property bool compassWarning: !compassPresent
    readonly property bool linkWarning: !linkCritical && (!radioAvailable || rssiPercent(radioRssi) < 35)
    readonly property bool firmwareWarning: !firmwareKnown
    readonly property bool storageWarning: !storageWritable || storagePercentUsed < 0 || storagePercentUsed >= 90
    readonly property bool geofenceWarning: !airspaceCritical && !geofenceConfigured
    readonly property bool weatherWarning: weatherState !== qsTr("OK")

    property bool storageWritable: false
    property real storageBytesAvailable: -1
    property real storageBytesTotal: -1
    readonly property int storagePercentUsed: storageBytesTotal > 0 && storageBytesAvailable >= 0
                                              ? Math.round((1 - storageBytesAvailable / storageBytesTotal) * 100) : -1

    readonly property string summary: !vehicle ? qsTr("Connect an aircraft to begin preflight checks.")
                                      : criticalReady
                                        ? (warningCount > 0
                                           ? qsTr("Ready to arm with %1 warning(s).").arg(warningCount)
                                           : qsTr("All critical checks passed."))
                                        : qsTr("%1 critical issue(s) must be resolved before arming.").arg(criticalCount)

    QGCFileDialogController {
        id: storageController
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root.refreshTick++
            root.refreshStorage()
        }
    }

    Timer {
        interval: 600000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refreshWeather()
    }

    onVehicleChanged: {
        refreshTick++
        refreshStorage()
        refreshWeather()
        updateChecklistState()
    }

    onCriticalReadyChanged: updateChecklistState()

    Component.onCompleted: updateChecklistState()

    function settingPath(setting) {
        if (!setting) return ""
        if (setting.rawValueString !== undefined) return setting.rawValueString
        if (setting.rawValue !== undefined) return String(setting.rawValue)
        return String(setting)
    }

    function updateChecklistState() {
        if (vehicle) {
            vehicle.checkListState = criticalReady ? Vehicle.CheckListPassed : Vehicle.CheckListFailed
        }
    }

    function refreshStorage() {
        var videoPath = settingPath(_appSettings.videoSavePath)
        var photoPath = settingPath(_appSettings.photoSavePath)
        if (!videoPath || !photoPath) {
            storageWritable = false
            storageBytesAvailable = -1
            storageBytesTotal = -1
            return
        }
        if (!storageController.storagePathWritable ||
                !storageController.storageBytesAvailable ||
                !storageController.storageBytesTotal) {
            storageWritable = true
            storageBytesAvailable = -1
            storageBytesTotal = -1
            return
        }

        storageWritable = storageController.storagePathWritable(videoPath) &&
                          storageController.storagePathWritable(photoPath)
        storageBytesAvailable = storageController.storageBytesAvailable(videoPath)
        storageBytesTotal = storageController.storageBytesTotal(videoPath)
    }

    function refreshWeather() {
        if (!vehicle || !vehicle.coordinate || !vehicle.coordinate.isValid) {
            weatherState = qsTr("Waiting")
            weatherDetail = qsTr("Weather needs a valid vehicle position.")
            return
        }

        weatherState = qsTr("Checking")
        weatherDetail = qsTr("Loading current weather.")
        var url = "https://api.open-meteo.com/v1/forecast?latitude=" + vehicle.coordinate.latitude +
                  "&longitude=" + vehicle.coordinate.longitude + "&current_weather=true"
        var xhr = new XMLHttpRequest()
        xhr.open("GET", url, true)
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return
            if (xhr.status !== 200) {
                weatherState = qsTr("Unavailable")
                weatherDetail = qsTr("Weather service could not be reached. This does not block arming.")
                return
            }
            try {
                var response = JSON.parse(xhr.responseText)
                var current = response.current_weather
                if (!current) throw new Error("missing current weather")
                weatherWindSpeed = Number(current.windspeed)
                weatherTemperature = Number(current.temperature)
                weatherCode = Number(current.weathercode)
                var severeCode = weatherCode >= 51 || weatherCode === 45 || weatherCode === 48
                var highWind = weatherWindSpeed >= 10
                weatherState = severeCode || highWind ? qsTr("Warning") : qsTr("OK")
                weatherDetail = qsTr("%1 C, wind %2 km/h.").arg(Math.round(weatherTemperature)).arg(Math.round(weatherWindSpeed))
            } catch (e) {
                weatherState = qsTr("Unavailable")
                weatherDetail = qsTr("Weather response could not be read. This does not block arming.")
            }
        }
        xhr.send()
    }

    function hasParameter(name) {
        return parameterManager && parameterManager.parameterExists(-1, name)
    }

    function parameterValue(name, fallback) {
        if (!hasParameter(name)) return fallback
        return Number(parameterManager.getParameter(-1, name).rawValue)
    }

    function _geofenceConfigured() {
        refreshTick
        if (!vehicle || !parameterManager || !parametersReady) return false
        if (hasParameter("FENCE_ENABLE")) return parameterValue("FENCE_ENABLE", 0) !== 0
        if (hasParameter("GF_ACTION")) return parameterValue("GF_ACTION", 0) !== 0
        return false
    }

    function rssiPercent(value) {
        if (!value) return 0
        if (value < 0) return Math.max(0, Math.min(100, Math.round((value + 120) * 100 / 80)))
        return Math.max(0, Math.min(100, Math.round(value * 100 / 255)))
    }

    function firmwareText() {
        if (!vehicle) return qsTr("No aircraft")
        if (!firmwareKnown) return vehicle.firmwareTypeString + qsTr(" version unavailable")
        return vehicle.firmwareTypeString + " " + vehicle.firmwareMajorVersion + "." +
               vehicle.firmwareMinorVersion + "." + vehicle.firmwarePatchVersion
    }

    function storageText() {
        if (!storageWritable) return qsTr("Photo or video folder is not writable.")
        if (storagePercentUsed < 0) return qsTr("Storage capacity is unavailable.")
        return qsTr("%1% used, %2 GB free.").arg(storagePercentUsed)
                .arg((storageBytesAvailable / (1024 * 1024 * 1024)).toFixed(1))
    }

    function batteryText() {
        if (isNaN(batteryPercent)) return qsTr("Battery percentage is unavailable.")
        if (batteryCritical) return qsTr("%1% remaining. Charge above 20% before arming.").arg(Math.round(batteryPercent))
        if (batteryWarning) return qsTr("%1% remaining. At least 40% is recommended.").arg(Math.round(batteryPercent))
        return qsTr("%1% remaining.").arg(Math.round(batteryPercent))
    }

    function gpsText() {
        if (!gpsRequired) return qsTr("This vehicle does not require a GPS fix to arm.")
        if (gpsCritical) return qsTr("Waiting for a 3D GPS fix. Current fix: %1, satellites: %2.").arg(gpsFix).arg(satelliteCount)
        if (gpsWarning) return qsTr("3D fix acquired with only %1 satellites.").arg(satelliteCount)
        return qsTr("3D fix acquired with %1 satellites.").arg(satelliteCount)
    }

    function compassText() {
        if (!compassPresent) return qsTr("No compass is reported by this vehicle.")
        return compassHealthy ? qsTr("Compass reports healthy.") : qsTr("Compass is unhealthy. Recalibrate or inspect the sensor.")
    }

    function linkText() {
        if (linkLost) return qsTr("Communication with the aircraft is lost.")
        if (!radioAvailable) return qsTr("Connected, but radio RSSI is unavailable.")
        return qsTr("Radio signal %1% (%2 dBm), MAVLink loss %3%.")
                .arg(rssiPercent(radioRssi)).arg(radioRssi).arg(Number(vehicle.mavlinkLossPercent).toFixed(1))
    }

    function healthText() {
        if (!vehicle) return qsTr("No aircraft connected.")
        if (!vehicle.initialConnectComplete || !parametersReady) return qsTr("Vehicle setup and parameters are still loading.")
        if (healthReport && healthReport.supported) {
            return healthReport.canArm ? qsTr("Autopilot permits arming.") : qsTr("Autopilot reports blocking health or arming checks.")
        }
        if (vehicle.readyToFlyAvailable && !vehicle.readyToFly) {
            return qsTr("Autopilot reports that the aircraft is not ready to fly.")
        }
        return vehicle.prearmError.length > 0 ? vehicle.prearmError : qsTr("No blocking pre-arm error reported.")
    }

    function geofenceText() {
        if (inRestrictedZone) return qsTr("Aircraft is inside a prohibited or restricted zone.")
        return geofenceConfigured ? qsTr("Aircraft geofence is enabled.") : qsTr("No enabled aircraft geofence was detected.")
    }

    function payloadText() {
        if (!logisticsProfile) return qsTr("No logistics payload checklist is required for this profile.")
        if (payloadOverweight) {
            return qsTr("%1 kg exceeds the %2 kg payload limit.")
                    .arg(appWindow.logisticsPayloadWeight.toFixed(1)).arg(appWindow.logisticsMaxPayloadWeight.toFixed(1))
        }
        return payloadReady ? qsTr("Package, weight, latch, release, and security checks passed.")
                            : (appWindow && appWindow._logisticsPayloadChecklistText
                               ? appWindow._logisticsPayloadChecklistText()
                               : qsTr("Payload checklist is incomplete."))
    }

    function firstCriticalReason() {
        if (connectionCritical) return healthText()
        if (healthCritical) return healthText()
        if (batteryCritical) return batteryText()
        if (gpsCritical) return gpsText()
        if (compassCritical) return compassText()
        if (linkCritical) return linkText()
        if (airspaceCritical) return geofenceText()
        if (payloadCritical) return payloadText()
        return ""
    }
}
