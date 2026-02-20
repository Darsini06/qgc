# QGroundControl Airspace GeoJSON Integration

## 🎯 Overview

This integration provides professional-grade airspace restriction management for QGroundControl using a GeoJSON REST API backend.

## 🏗 Architecture

```
┌────────────────────┐
│   MongoDB (GeoJSON)│
└──────────┬─────────┘
           │
┌──────────▼─────────┐
│   Node.js REST API │
│   GET /api/facilities?bbox=...
└──────────┬─────────┘
           │
┌──────────▼─────────┐
│   QGC (Qt Client)  │
│  ┌──────────────┐  │
│  │ AirspaceManager │
│  │  - Fetch GeoJSON│
│  │  - Parse zones  │
│  │  - Cache (SQLite)│
│  └──────┬───────┘  │
│         │          │
│  ┌──────▼───────┐  │
│  │ Map Overlay  │  │
│  │  - Render    │  │
│  │  - Style     │  │
│  └──────────────┘  │
│         │          │
│  ┌──────▼───────┐  │
│  │ Validator    │  │
│  │  - Check WP  │  │
│  │  - Block/Warn│  │
│  └──────────────┘  │
└────────────────────┘
```

## 📁 Files Created

### C++ Backend
- `src/Airspace/AirspaceManager.h` - Main manager class
- `src/Airspace/AirspaceManager.cc` - Implementation
- `src/Airspace/AirspaceRestrictionValidator.h` - Mission validation
- `src/Airspace/AirspaceRestrictionValidator.cc` - Validation logic
- `src/Airspace/CMakeLists.txt` - Build configuration

### QML Frontend
- `src/FlightMap/MapItems/AirspaceMapOverlay.qml` - Map overlay
- `src/PlanView/AirspaceRestrictionDialog.qml` - Warning dialog

## 🔌 Integration Steps

### Step 1: Register with QGCToolbox

Edit `src/QGCToolbox.h`:

```cpp
#include "AirspaceManager.h"

class QGCToolbox {
    // ... existing code ...
    
    AirspaceManager* airspaceManager() { return _airspaceManager; }
    
private:
    AirspaceManager* _airspaceManager;
};
```

Edit `src/QGCToolbox.cc`:

```cpp
#include "AirspaceManager.h"

void QGCToolbox::_setToolbox(QGCToolbox* toolbox)
{
    // ... existing code ...
    
    _airspaceManager = new AirspaceManager(toolbox, toolbox);
    _airspaceManager->setToolbox(toolbox);
}
```

### Step 2: Add to CMake Build

Edit `src/CMakeLists.txt`:

```cmake
# Add Airspace subdirectory
add_subdirectory(Airspace)

# Link to main target
target_link_libraries(QGroundControl
    PRIVATE
        Airspace
        # ... other libraries ...
)
```

### Step 3: Integrate Map Overlay

Edit `src/FlightMap/FlightMap.qml`:

```qml
import QGroundControl.FlightMap

Map {
    id: flightMap
    
    // ... existing map configuration ...
    
    // Add airspace overlay
    AirspaceMapOverlay {
        id: airspaceOverlay
        map: flightMap
        airspaceManager: QGroundControl.airspaceManager
        showAirspace: true
        showLabels: true
        showIcons: true
    }
}
```

### Step 4: Integrate Mission Validation

Edit `src/PlanView/PlanView.qml`:

```qml
import QGroundControl

Item {
    property var _airspaceValidator: QGroundControl.airspaceManager ? 
        QGroundControl.airspaceManager.createValidator() : null
    
    // Mission upload button
    QGCButton {
        text: "Upload Mission"
        enabled: !_airspaceValidator || !_airspaceValidator.blockMissionUpload
        
        onClicked: {
            if (_airspaceValidator) {
                var allowed = _airspaceValidator.validateMission(_missionController)
                
                if (!allowed) {
                    // Show blocking dialog
                    _restrictionDialog.isBlocked = true
                    _restrictionDialog.message = _airspaceValidator.restrictionMessage
                    _restrictionDialog.open()
                    return
                } else if (_airspaceValidator.hasRestrictions) {
                    // Show warning dialog
                    _restrictionDialog.isBlocked = false
                    _restrictionDialog.message = _airspaceValidator.restrictionMessage
                    _restrictionDialog.onAccept = function() {
                        _uploadMission()
                    }
                    _restrictionDialog.open()
                    return
                }
            }
            
            _uploadMission()
        }
    }
    
    AirspaceRestrictionDialog {
        id: _restrictionDialog
        validator: _airspaceValidator
    }
}
```

## 🌐 Backend API Requirements

Your REST API must return GeoJSON FeatureCollection:

### Endpoint
```
GET /api/facilities?bbox=minLon,minLat,maxLon,maxLat
```

### Response Format
```json
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "properties": {
        "name": "Military Base Alpha",
        "zoneType": "military",
        "description": "Restricted military airspace",
        "minAltitude": 0,
        "maxAltitude": 5000,
        "active": true
      },
      "geometry": {
        "type": "Polygon",
        "coordinates": [
          [
            [77.5, 28.5],
            [77.6, 28.5],
            [77.6, 28.6],
            [77.5, 28.6],
            [77.5, 28.5]
          ]
        ]
      }
    }
  ]
}
```

### Zone Types
- `"red"` or `"prohibited"` - Flight blocked
- `"yellow"` or `"restricted"` - Warning only
- `"military"` - Military restricted (warning)
- `"airport"` - Airport area (warning)
- `"ctr"` - Control zone (warning)
- `"runway"` - Runway approach (warning)
- `"temporary"` or `"notam"` - Temporary restriction (warning)

## ⚙️ Configuration

### Server URL
Set in QGC settings or programmatically:

```cpp
QGroundControl.airspaceManager.serverUrl = "https://yourserver.com/api/facilities"
```

### Offline Mode
Enable offline mode to use cached data only:

```cpp
QGroundControl.airspaceManager.offlineModeEnabled = true
```

### Auto-Refresh
Data automatically refreshes every 5 minutes. Adjust in `AirspaceManager.h`:

```cpp
static constexpr int AUTO_REFRESH_INTERVAL_MS = 300000; // 5 minutes
```

## 💾 Offline Caching

Airspace data is automatically cached in SQLite:
- Location: `AppData/Local/QGroundControl/airspace_cache.db`
- Indexed by bounding box
- Fallback when network unavailable

### Clear Cache
```cpp
QGroundControl.airspaceManager.clearCache()
```

## 🎨 Styling

Zone colors are automatically applied based on type:

| Zone Type | Fill Color | Opacity | Border |
|-----------|------------|---------|--------|
| Red | #FF0000 | 0.4 | #8B0000 (3px) |
| Yellow | #FFFF00 | 0.3 | #FFA500 (2px) |
| Military | #8B0000 | 0.5 | #FF0000 (3px) |
| Airport | #4169E1 | 0.3 | #000080 (2px) |
| CTR | #9370DB | 0.25 | #4B0082 (2px) |
| Runway | #FF6347 | 0.35 | #DC143C (2px) |

## 🔍 Mission Validation Logic

```cpp
// For each waypoint in mission:
1. Check if waypoint inside any zone polygon
2. Check if waypoint altitude within zone altitude range
3. If in RED zone → BLOCK mission upload
4. If in YELLOW/MILITARY zone → WARN but allow
5. Show detailed dialog with zone information
```

## 🧪 Testing

### Test with Mock Data
```cpp
// In QGC console or test file
var testWaypoints = [
    {latitude: 28.55, longitude: 77.55, altitude: 100},
    {latitude: 28.56, longitude: 77.56, altitude: 150}
]

var errorMsg = ""
var allowed = QGroundControl.airspaceManager.checkMissionRestrictions(testWaypoints, errorMsg)
console.log("Allowed:", allowed, "Message:", errorMsg)
```

### Test Coordinate Check
```qml
var restrictions = QGroundControl.airspaceManager.getRestrictionsAtCoordinate(28.55, 77.55, 100)
console.log("Restrictions:", JSON.stringify(restrictions))
```

## 📊 Performance

- **Network**: Async requests, non-blocking UI
- **Parsing**: Efficient JSON parsing with Qt
- **Rendering**: QML hardware acceleration
- **Memory**: Zones loaded on-demand by bbox
- **Cache**: SQLite with indexes for fast lookup

## 🔒 Security

- HTTPS recommended for production
- API authentication can be added to `QNetworkRequest`
- Cached data encrypted if needed (extend SQLite setup)

## 🐛 Debugging

Enable debug output:

```cpp
// In main.cc or QGCApplication.cc
qSetMessagePattern("%{time yyyy-MM-dd hh:mm:ss} %{type} %{function} - %{message}");
```

Watch for:
- `AirspaceManager: Fetching from...`
- `AirspaceManager: Loaded X zones`
- `AirspaceManager: Mission blocked - ...`

## 📝 Example Backend (Node.js + MongoDB)

```javascript
app.get('/api/facilities', async (req, res) => {
  const { bbox } = req.query;
  const [minLon, minLat, maxLon, maxLat] = bbox.split(',').map(Number);

  const facilities = await db.collection('facilities').find({
    geometry: {
      $geoIntersects: {
        $geometry: {
          type: "Polygon",
          coordinates: [[
            [minLon, minLat],
            [maxLon, minLat],
            [maxLon, maxLat],
            [minLon, maxLat],
            [minLon, minLat]
          ]]
        }
      }
    }
  }).toArray();

  res.json({
    type: "FeatureCollection",
    features: facilities
  });
});
```

## 🚀 Next Steps

1. Build QGC with new Airspace module
2. Configure backend API URL
3. Test with sample GeoJSON data
4. Deploy to production
5. Monitor cache performance
6. Add custom zone types as needed

## 📞 Support

For issues or questions:
- Check QGC logs for `AirspaceManager` messages
- Verify API returns valid GeoJSON
- Test with offline mode to isolate network issues
- Check SQLite cache database for stored data
