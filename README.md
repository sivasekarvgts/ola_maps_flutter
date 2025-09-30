# OlaMaps Flutter Plugin

A Flutter plugin for integrating OlaMaps SDK in Flutter applications. This plugin provides a comprehensive wrapper around the OlaMaps Android SDK, enabling developers to add interactive maps with markers, polygons, and more to their Flutter apps.

## Features

- 🗺️ **Interactive Maps**: Display OlaMaps with full gesture support
- 📍 **Markers**: Add, remove, and update custom markers

- 🔷 **Polygons**: Create filled areas with customizable styles
- 📸 **Camera Controls**: Animate and move camera to specific positions
- 🎯 **Event Handling**: Respond to map clicks, long presses, and camera movements
- 📍 **Location Tracking**: Show user's current location on the map
- 🎨 **Custom Styling**: Apply custom map styles
- 🔄 **Real-time Updates**: Dynamic marker and shape management

## Prerequisites

Before using this plugin, you need:

1. **OlaMaps API Key**: Register at [OlaMaps Platform](https://maps.olakrutrim.com) to get your API credentials
2. **OlaMaps SDK AAR**: Download the OlaMapSDK.aar file (v1.0.68 or newer)
3. **Android SDK**: Minimum API level 21 (Android 5.0)

## Installation

### Step 1: Add the plugin dependency

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  ola_maps_flutter:
    path: ../ola_maps_flutter  # Or use git/pub.dev when published
```

### Step 2: Configure Android

1. **Add the OlaMaps SDK AAR file**:
   - Download `OlaMapSDK.aar` from the OlaMaps developer portal
   - Place it in `android/libs/` directory of the plugin

2. **Update Android Manifest**:

Add required permissions in `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

## Quick Start

### Basic Map Implementation

```dart
import 'package:flutter/material.dart';
import 'package:ola_maps_flutter/ola_maps_flutter.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  OlaMapController? _controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('OlaMaps Demo'),
      ),
      body: OlaMap(
        apiKey: 'YOUR_API_KEY_HERE',
        initialCameraPosition: CameraPosition(
          target: LatLng(12.9716, 77.5946), // Bangalore
          zoom: 12,
        ),
        onMapCreated: (OlaMapController controller) {
          _controller = controller;
        },
      ),
    );
  }
}
```

## Usage Examples

### Adding Markers

```dart
_controller?.addMarker(
  Marker(
    markerId: 'marker_1',
    position: LatLng(12.9716, 77.5946),
    title: 'Bangalore',
    snippet: 'Silicon Valley of India',
  ),
);
```



### Camera Animation

```dart
_controller?.animateCamera(
  target: LatLng(13.0827, 80.2707),
  zoom: 14,
);
```

## Example App

Run the example app to see all features in action:

```bash
cd example
flutter run
```

## Platform Support

| Platform | Status |
|----------|--------|
| Android | ✅ Supported |
| iOS | 🚧 Planned |

## License

MIT License - see LICENSE file for details

