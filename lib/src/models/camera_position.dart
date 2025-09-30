import 'lat_lng.dart';

class CameraPosition {
  final LatLng target;
  final double zoom;
  final double tilt;
  final double bearing;

  const CameraPosition({
    required this.target,
    this.zoom = 10.0,
    this.tilt = 0.0,
    this.bearing = 0.0,
  });

  Map<String, dynamic> toJson() => {
        'target': target.toJson(),
        'zoom': zoom,
        'tilt': tilt,
        'bearing': bearing,
      };

  factory CameraPosition.fromJson(Map<String, dynamic> json) => CameraPosition(
        target: LatLng.fromJson(json['target'] as Map<String, dynamic>),
        zoom: (json['zoom'] as num?)?.toDouble() ?? 10.0,
        tilt: (json['tilt'] as num?)?.toDouble() ?? 0.0,
        bearing: (json['bearing'] as num?)?.toDouble() ?? 0.0,
      );

  CameraPosition copyWith({
    LatLng? target,
    double? zoom,
    double? tilt,
    double? bearing,
  }) =>
      CameraPosition(
        target: target ?? this.target,
        zoom: zoom ?? this.zoom,
        tilt: tilt ?? this.tilt,
        bearing: bearing ?? this.bearing,
      );

  @override
  String toString() =>
      'CameraPosition(target: $target, zoom: $zoom, tilt: $tilt, bearing: $bearing)';
}