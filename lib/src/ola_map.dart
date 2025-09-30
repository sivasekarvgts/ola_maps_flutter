import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'ola_map_controller.dart';
import 'models/camera_position.dart';
import 'models/lat_lng.dart';

typedef OnMapCreated = void Function(OlaMapController controller);

class OlaMap extends StatefulWidget {
  final String apiKey;
  final String? clientId;
  final String? clientSecret;
  final CameraPosition initialCameraPosition;
  final OnMapCreated? onMapCreated;
  final bool myLocationEnabled;
  final bool zoomControlsEnabled;
  final bool compassEnabled;
  final bool trafficEnabled;
  final String? mapStyle;
  final Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers;

  const OlaMap({
    Key? key,
    required this.apiKey,
    this.clientId,
    this.clientSecret,
    required this.initialCameraPosition,
    this.onMapCreated,
    this.myLocationEnabled = false,
    this.zoomControlsEnabled = true,
    this.compassEnabled = true,
    this.trafficEnabled = false,
    this.mapStyle,
    this.gestureRecognizers,
  }) : super(key: key);

  @override
  State<OlaMap> createState() => _OlaMapState();
}

class _OlaMapState extends State<OlaMap> {
  final Completer<OlaMapController> _controller = Completer<OlaMapController>();

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidView(
        viewType: 'ola_maps_flutter/map_view',
        creationParams: {
          'apiKey': widget.apiKey,
          'clientId': widget.clientId,
          'clientSecret': widget.clientSecret,
          'initialCameraPosition': widget.initialCameraPosition.toJson(),
          'myLocationEnabled': widget.myLocationEnabled,
          'zoomControlsEnabled': widget.zoomControlsEnabled,
          'compassEnabled': widget.compassEnabled,
          'trafficEnabled': widget.trafficEnabled,
          'mapStyle': widget.mapStyle,
        },
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: _onPlatformViewCreated,
        gestureRecognizers: widget.gestureRecognizers,
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return UiKitView(
        viewType: 'ola_maps_flutter/map_view',
        creationParams: {
          'apiKey': widget.apiKey,
          'clientId': widget.clientId,
          'clientSecret': widget.clientSecret,
          'initialCameraPosition': widget.initialCameraPosition.toJson(),
          'myLocationEnabled': widget.myLocationEnabled,
          'zoomControlsEnabled': widget.zoomControlsEnabled,
          'compassEnabled': widget.compassEnabled,
          'trafficEnabled': widget.trafficEnabled,
          'mapStyle': widget.mapStyle,
        },
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: _onPlatformViewCreated,
        gestureRecognizers: widget.gestureRecognizers,
      );
    }
    return const Center(
      child: Text('OlaMaps is not supported on this platform'),
    );
  }

  void _onPlatformViewCreated(int id) async {
    final channel = MethodChannel('ola_maps_flutter_$id');
    final controller = await OlaMapController.init(id, channel);
    _controller.complete(controller);
    
    if (widget.onMapCreated != null) {
      widget.onMapCreated!(controller);
    }
  }
}