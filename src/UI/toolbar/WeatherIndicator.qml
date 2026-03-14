import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls
import QGroundControl.Palette

Item {
    id: _root
    width: childrenRect.width
    height: 40

    property var _activeVehicle: QGroundControl.multiVehicleManager.activeVehicle
    property real lat: _activeVehicle && _activeVehicle.coordinate && _activeVehicle.coordinate.isValid ? _activeVehicle.coordinate.latitude : 0
    property real lon: _activeVehicle && _activeVehicle.coordinate && _activeVehicle.coordinate.isValid ? _activeVehicle.coordinate.longitude : 0

    property string tempString: "-- °C"
    property string weatherIconText: "☁️" 

    QGCPalette { id: qgcPal; colorGroupEnabled: true }

    Timer {
        interval: 600000 // every 10 mins
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: fetchWeather()
    }

    onLatChanged: fetchWeather()
    onLonChanged: fetchWeather()

    function fetchWeather() {
        // If no coordinate is available yet, fall back to IP-based location
        if (Math.abs(lat) < 0.1 && Math.abs(lon) < 0.1) {
            var ipXhr = new XMLHttpRequest();
            ipXhr.open("GET", "http://ip-api.com/json/", true);
            ipXhr.onreadystatechange = function() {
                if (ipXhr.readyState == 4) {
                    if (ipXhr.status == 200) {
                        try {
                            var ipData = JSON.parse(ipXhr.responseText);
                            getWeatherFromMeteo(ipData.lat, ipData.lon);
                        } catch (e) {
                            console.log("Weather location fallback error");
                        }
                    }
                }
            }
            ipXhr.send();
        } else {
            getWeatherFromMeteo(lat, lon);
        }
    }

    function getWeatherFromMeteo(latitude, longitude) {
        var url = "https://api.open-meteo.com/v1/forecast?latitude=" + latitude + "&longitude=" + longitude + "&current_weather=true";
        var xhr = new XMLHttpRequest();
        xhr.open("GET", url, true);
        xhr.onreadystatechange = function() {
            if (xhr.readyState == 4 && xhr.status == 200) {
                try {
                    var response = JSON.parse(xhr.responseText);
                    if (response.current_weather) {
                        tempString = Math.round(response.current_weather.temperature) + " °C";
                        updateIcon(response.current_weather.weathercode);
                    }
                } catch (e) {
                    console.log("Weather sync failed.");
                }
            }
        }
        xhr.send();
    }

    function updateIcon(code) {
        if (code === 0) weatherIconText = "☀️"; // clear
        else if (code === 1 || code === 2) weatherIconText = "⛅"; // partly cloudy
        else if (code === 3) weatherIconText = "☁️"; // overcast
        else if (code === 45 || code === 48) weatherIconText = "🌫️"; // fog
        else if (code >= 51 && code <= 67) weatherIconText = "🌧️"; // rain
        else if (code >= 71 && code <= 86) weatherIconText = "❄️"; // snow
        else if (code >= 95) weatherIconText = "🌩️"; // thunderstorm
        else weatherIconText = "☁️";
    }

    Row {
        anchors.verticalCenter: parent.verticalCenter
        spacing: 5

        Text {
            text: weatherIconText
            font.pixelSize: 22
            color: "white"
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: tempString
            font.pixelSize: 15
            color: "white"
            font.bold: true
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
