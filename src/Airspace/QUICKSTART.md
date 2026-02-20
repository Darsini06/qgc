# QGroundControl Airspace Integration - Quick Start Guide

## ✅ Integration Checklist

### 1. Build System Integration

- [ ] Add Airspace module to main CMakeLists.txt
  ```cmake
  # In src/CMakeLists.txt
  add_subdirectory(Airspace)
  target_link_libraries(QGroundControl PRIVATE Airspace)
  ```

- [ ] Verify Qt dependencies are available:
  - Qt6::Network
  - Qt6::Positioning
  - Qt6::Sql

### 2. QGCToolbox Registration

- [ ] Add AirspaceManager to QGCToolbox.h:
  ```cpp
  #include "AirspaceManager.h"
  
  class QGCToolbox {
  public:
      AirspaceManager* airspaceManager() { return _airspaceManager; }
  private:
      AirspaceManager* _airspaceManager = nullptr;
  };
  ```

- [ ] Initialize in QGCToolbox.cc:
  ```cpp
  void QGCToolbox::_setToolbox(QGCToolbox* toolbox) {
      _airspaceManager = new AirspaceManager(toolbox, toolbox);
  }
  ```

- [ ] Add to QGCApplication for QML access:
  ```cpp
  // In QGCApplication.cc
  qmlRegisterSingletonInstance("QGroundControl", 1, 0, "QGroundControl", this);
  ```

### 3. Map Integration

- [ ] Add overlay to FlightMap.qml:
  ```qml
  import QGroundControl.FlightMap
  
  Map {
      AirspaceMapOverlay {
          map: parent
          airspaceManager: QGroundControl.airspaceManager
          showAirspace: true
      }
  }
  ```

- [ ] Add to FlyViewMap.qml (flight display)
- [ ] Add to PlanView map (mission planning)

### 4. Mission Validation Integration

- [ ] Create validator in PlanView.qml:
  ```qml
  property var _airspaceValidator: {
      if (QGroundControl.airspaceManager) {
          return new AirspaceRestrictionValidator(
              QGroundControl.airspaceManager
          )
      }
      return null
  }
  ```

- [ ] Hook into mission upload button:
  ```qml
  QGCButton {
      text: "Upload"
      onClicked: {
          if (_airspaceValidator) {
              var allowed = _airspaceValidator.validateMission(_missionController)
              if (!allowed) {
                  _restrictionDialog.open()
                  return
              }
          }
          _uploadMission()
      }
  }
  ```

- [ ] Add AirspaceRestrictionDialog to PlanView

### 5. Settings Integration

- [ ] Add AirspaceSettings.qml to Settings menu
- [ ] Register in SettingsManager or AppSettings
- [ ] Add menu item in main settings view

### 6. Backend API Setup

- [ ] Deploy GeoJSON REST API
- [ ] Verify endpoint format: `GET /api/facilities?bbox=minLon,minLat,maxLon,maxLat`
- [ ] Test response format (FeatureCollection)
- [ ] Configure CORS if needed
- [ ] Add authentication if required

### 7. Configuration

- [ ] Set server URL in settings or code:
  ```cpp
  QGroundControl.airspaceManager.serverUrl = "https://your-api.com/api/facilities"
  ```

- [ ] Test with sample data (sample_data_delhi.json)
- [ ] Configure auto-refresh interval if needed

### 8. Testing

- [ ] Test map overlay rendering
- [ ] Test zone styling (red, yellow, military, etc.)
- [ ] Test mission validation with test waypoints
- [ ] Test offline mode with cached data
- [ ] Test cache clear functionality
- [ ] Test error handling (network errors, invalid JSON)

### 9. Build & Deploy

- [ ] Clean build QGC
- [ ] Verify no compilation errors
- [ ] Test on target platform (Desktop/Android/iOS)
- [ ] Check SQLite cache creation
- [ ] Monitor debug logs for airspace messages

## 🚀 Quick Test

### Test with Local Mock Server

1. **Create simple Node.js mock server:**

```javascript
// mock-server.js
const express = require('express');
const fs = require('fs');
const app = express();

app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  next();
});

app.get('/api/facilities', (req, res) => {
  const data = JSON.parse(fs.readFileSync('sample_data_delhi.json'));
  res.json(data);
});

app.listen(3000, () => {
  console.log('Mock airspace server running on http://localhost:3000');
});
```

2. **Run mock server:**
```bash
node mock-server.js
```

3. **Configure QGC:**
```cpp
QGroundControl.airspaceManager.serverUrl = "http://localhost:3000/api/facilities"
```

4. **Test in QGC:**
- Open map view
- Pan to Delhi (28.6°N, 77.2°E)
- Verify zones appear
- Create mission through restricted zones
- Verify validation warnings/blocks

## 📋 Verification Steps

### Visual Verification
- [ ] Red zones appear with red fill
- [ ] Yellow zones appear with yellow fill
- [ ] Military zones appear with dark red fill
- [ ] Airport zones show airplane icons
- [ ] Zone labels display correctly
- [ ] Hover tooltips work
- [ ] Loading indicator appears during fetch

### Functional Verification
- [ ] Zones load when map moves
- [ ] Zones update when zooming
- [ ] Mission validation blocks red zones
- [ ] Mission validation warns for yellow zones
- [ ] Offline mode uses cached data
- [ ] Cache persists across app restarts
- [ ] Settings panel updates work

### Performance Verification
- [ ] Map rendering is smooth
- [ ] No lag when panning/zooming
- [ ] Network requests are debounced
- [ ] Memory usage is reasonable
- [ ] SQLite queries are fast

## 🐛 Troubleshooting

### Zones not appearing
1. Check network request in logs: `AirspaceManager: Fetching from...`
2. Verify API returns valid GeoJSON
3. Check CORS headers if cross-origin
4. Enable offline mode and check cache

### Mission validation not working
1. Verify validator is created in PlanView
2. Check mission controller is valid
3. Verify waypoints have coordinates
4. Check zone polygon contains waypoints

### Build errors
1. Verify Qt6 modules are installed
2. Check CMakeLists.txt includes Airspace
3. Verify all headers are included
4. Clean build directory and rebuild

### Cache issues
1. Check SQLite database location
2. Verify write permissions
3. Clear cache and re-fetch
4. Check database schema creation

## 📊 Expected Log Output

```
AirspaceManager: Cache database initialized at C:/Users/.../airspace_cache.db
AirspaceManager: Fetching from http://localhost:3000/api/facilities?bbox=77.0,28.4,77.3,28.7
AirspaceManager: Loaded 10 zones
AirspaceManager: Saved 10 zones to cache
AirspaceRestrictionValidator: Mission warning - Path intersects restricted zone 'Delhi CTR'
```

## 🎯 Success Criteria

✅ **Integration Complete When:**
1. Map displays airspace zones with correct styling
2. Zones load automatically when map moves
3. Mission upload is blocked for red zones
4. Warnings appear for yellow/military zones
5. Offline mode works with cached data
6. Settings panel controls all options
7. No crashes or memory leaks
8. Performance is acceptable

## 📞 Next Steps After Integration

1. **Production Deployment:**
   - Deploy backend API to production server
   - Configure production URL in QGC
   - Enable HTTPS
   - Add authentication if needed

2. **Data Management:**
   - Populate database with real airspace data
   - Set up data update pipeline
   - Configure NOTAM integration for temporary restrictions
   - Add data validation

3. **User Training:**
   - Document airspace features for users
   - Create tutorial videos
   - Add in-app help text
   - Provide zone type explanations

4. **Monitoring:**
   - Monitor API usage and performance
   - Track cache hit rates
   - Log validation events
   - Collect user feedback

## 🔗 Related Files

- **C++ Backend:** `src/Airspace/AirspaceManager.{h,cc}`
- **Validation:** `src/Airspace/AirspaceRestrictionValidator.{h,cc}`
- **QML Overlay:** `src/FlightMap/MapItems/AirspaceMapOverlay.qml`
- **Settings:** `src/Settings/AirspaceSettings.qml`
- **Dialog:** `src/PlanView/AirspaceRestrictionDialog.qml`
- **Documentation:** `src/Airspace/README.md`
- **Sample Data:** `src/Airspace/sample_data_delhi.json`

## 💡 Tips

- Start with offline mode and sample data for initial testing
- Use debug builds to see detailed logs
- Test with simple missions before complex ones
- Verify API responses with curl/Postman first
- Monitor network traffic with browser dev tools
- Check SQLite database with DB Browser for SQLite

---

**Ready to integrate? Start with Step 1 of the checklist above!**
