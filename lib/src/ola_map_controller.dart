import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models/camera_position.dart';
import 'models/lat_lng.dart';
import 'models/marker.dart';
import 'models/polyline.dart';
import 'models/polygon.dart';

class OlaMapController {
  final MethodChannel _channel;
  final int mapId;
  
  final _onMapClickController = StreamController<LatLng>.broadcast();
  final _onMapLongClickController = StreamController<LatLng>.broadcast();
  final _onCameraMoveController = StreamController<CameraPosition>.broadcast();
  final _onCameraIdleController = StreamController<void>.broadcast();
  final _onMarkerTapController = StreamController<String>.broadcast();
  
  Stream<LatLng> get onMapClick => _onMapClickController.stream;
  Stream<LatLng> get onMapLongClick => _onMapLongClickController.stream;
  Stream<CameraPosition> get onCameraMove => _onCameraMoveController.stream;
  Stream<void> get onCameraIdle => _onCameraIdleController.stream;
  Stream<String> get onMarkerTap => _onMarkerTapController.stream;

  OlaMapController._(this.mapId, this._channel) {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  static Future<OlaMapController> init(int id, MethodChannel channel) async {
    final controller = OlaMapController._(id, channel);
    return controller;
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onMapClick':
        final args = call.arguments as Map<String, dynamic>;
        _onMapClickController.add(LatLng.fromJson(args));
        break;
      case 'onMapLongClick':
        final args = call.arguments as Map<String, dynamic>;
        _onMapLongClickController.add(LatLng.fromJson(args));
        break;
      case 'onCameraMove':
        final args = call.arguments as Map<String, dynamic>;
        _onCameraMoveController.add(CameraPosition.fromJson(args));
        break;
      case 'onCameraIdle':
        _onCameraIdleController.add(null);
        break;
      case 'onMarkerTap':
        final markerId = call.arguments as String;
        _onMarkerTapController.add(markerId);
        break;
    }
  }

  // Marker methods
  Future<String> addMarker(Marker marker) async {
    final result = await _channel.invokeMethod<String>('addMarker', marker.toJson());
    return result ?? marker.markerId;
  }

  Future<void> removeMarker(String markerId) async {
    await _channel.invokeMethod('removeMarker', {'markerId': markerId});
  }

  Future<void> updateMarker(Marker marker) async {
    await _channel.invokeMethod('updateMarker', marker.toJson());
  }

  Future<void> clearMarkers() async {
    await _channel.invokeMethod('clearMarkers');
  }

  // Add markers at specific predefined locations
  // Future<List<String>> addMarkersAtLocations(List<Marker> locations) async {
  //   final List<String> markerIds = [];
  //   for (final location in locations) {
  //     final markerId = await addMarker(
  //       Marker(
  //         markerId: location['id'] ?? 'marker_${DateTime.now().millisecondsSinceEpoch}',
  //         position: location['position'],
  //         snippet: location['snippet'] ?? '',
  //         title: location['title'],
  //         isIconClickable: true,
  //         isAnimationEnable: true,
  //         isInfoWindowDismissOnClick: true,
  //       ),
  //     );
  //     markerIds.add(markerId);
  //   }
  //   return markerIds;
  // }
  
  // Add a single marker at a specific location
  Future<String> addMarkerAtLocation({
    required double latitude,
    required double longitude,
    String? markerId,
    String? snippet,
    String? title,
  }) async {
    return await addMarker(
      Marker(
        markerId: markerId ?? 'marker_${DateTime.now().millisecondsSinceEpoch}',
        position: LatLng(latitude, longitude),
        snippet: snippet ?? 'Location: $latitude, $longitude',
        title: title,
        isIconClickable: true,
        isAnimationEnable: true,
        isInfoWindowDismissOnClick: true,
      ),
    );
  }
  
  // Info window methods
  Future<void> showInfoWindow(String markerId) async {
    await _channel.invokeMethod('showInfoWindow', {'markerId': markerId});
  }
  
  Future<void> hideInfoWindow(String markerId) async {
    await _channel.invokeMethod('hideInfoWindow', {'markerId': markerId});
  }
  
  Future<void> updateInfoWindow(String markerId, String infoText) async {
    await _channel.invokeMethod('updateInfoWindow', {
      'markerId': markerId,
      'infoText': infoText,
    });
  }

  // Polyline methods
  Future<void> addPolyline(Polyline polyline) async {
    await _channel.invokeMethod('addPolyline', polyline.toJson());
  }

  Future<void> removePolyline(String polylineId) async {
    await _channel.invokeMethod('removePolyline', {'polylineId': polylineId});
  }

  Future<void> updatePolyline(String polylineId, List<LatLng> points) async {
    await _channel.invokeMethod('updatePolyline', {
      'polylineId': polylineId,
      'points': points.map((p) => p.toJson()).toList(),
    });
  }

  Future<void> clearPolylines() async {
    await _channel.invokeMethod('clearPolylines');
  }

  // Polygon methods
  Future<void> addPolygon(Polygon polygon) async {
    await _channel.invokeMethod('addPolygon', polygon.toJson());
  }

  Future<void> removePolygon(String polygonId) async {
    await _channel.invokeMethod('removePolygon', {'polygonId': polygonId});
  }

  Future<void> clearPolygons() async {
    await _channel.invokeMethod('clearPolygons');
  }

  // Camera methods
  Future<void> animateCamera({
    LatLng? target,
    double? zoom,
    double? bearing,
    double? tilt,
    Duration duration = const Duration(milliseconds: 300),
  }) async {
    await _channel.invokeMethod('animateCamera', {
      if (target != null) 'target': target.toJson(),
      if (zoom != null) 'zoom': zoom,
      if (bearing != null) 'bearing': bearing,
      if (tilt != null) 'tilt': tilt,
      'duration': duration.inMilliseconds,
    });
  }

  Future<void> moveCamera({
    LatLng? target,
    double? zoom,
    double? bearing,
    double? tilt,
  }) async {
    await _channel.invokeMethod('moveCamera', {
      if (target != null) 'target': target.toJson(),
      if (zoom != null) 'zoom': zoom,
      if (bearing != null) 'bearing': bearing,
      if (tilt != null) 'tilt': tilt,
    });
  }

  Future<void> animateCameraToPosition(CameraPosition position, {Duration duration = const Duration(milliseconds: 300)}) async {
    await _channel.invokeMethod('animateCamera', {
      'target': position.target.toJson(),
      'zoom': position.zoom,
      'bearing': position.bearing,
      'tilt': position.tilt,
      'duration': duration.inMilliseconds,
    });
  }

  Future<void> moveCameraToPosition(CameraPosition position) async {
    await _channel.invokeMethod('moveCamera', {
      'target': position.target.toJson(),
      'zoom': position.zoom,
      'bearing': position.bearing,
      'tilt': position.tilt,
    });
  }

  Future<CameraPosition> getCameraPosition() async {
    final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('getCameraPosition');
    return CameraPosition.fromJson(Map<String, dynamic>.from(result!));
  }

  // Map settings
  Future<void> setMapStyle(String style) async {
    await _channel.invokeMethod('setMapStyle', {'style': style});
  }

  Future<void> setMyLocationEnabled(bool enabled) async {
    await _channel.invokeMethod('setMyLocationEnabled', {'enabled': enabled});
  }

  // Utility methods
  Future<Uint8List?> takeSnapshot() async {
    final result = await _channel.invokeMethod<Uint8List>('takeSnapshot');
    return result;
  }

  void dispose() {
    _onMapClickController.close();
    _onMapLongClickController.close();
    _onCameraMoveController.close();
    _onCameraIdleController.close();
    _onMarkerTapController.close();
  }
}