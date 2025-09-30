import 'package:flutter/material.dart';
import 'lat_lng.dart';

class Polyline {
  final String polylineId;
  final List<LatLng> points;
  final Color color;
  final double width;
  final String? lineType;
  final bool geodesic;
  final bool visible;
  final int zIndex;
  final VoidCallback? onTap;

  const Polyline({
    required this.polylineId,
    required this.points,
    this.color = Colors.blue,
    this.width = 5.0,
    this.lineType,
    this.geodesic = false,
    this.visible = true,
    this.zIndex = 0,
    this.onTap,
  });

  Map<String, dynamic> toJson() => {
        'polylineId': polylineId,
        'points': points.map((p) => p.toJson()).toList(),
        'color': '#${color.value.toRadixString(16).padLeft(8, '0')}',
        'width': width,
        'lineType': lineType,
        'geodesic': geodesic,
        'visible': visible,
        'zIndex': zIndex,
      };

  Polyline copyWith({
    String? polylineId,
    List<LatLng>? points,
    Color? color,
    double? width,
    String? lineType,
    bool? geodesic,
    bool? visible,
    int? zIndex,
    VoidCallback? onTap,
  }) =>
      Polyline(
        polylineId: polylineId ?? this.polylineId,
        points: points ?? this.points,
        color: color ?? this.color,
        width: width ?? this.width,
        lineType: lineType ?? this.lineType,
        geodesic: geodesic ?? this.geodesic,
        visible: visible ?? this.visible,
        zIndex: zIndex ?? this.zIndex,
        onTap: onTap ?? this.onTap,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Polyline &&
          runtimeType == other.runtimeType &&
          polylineId == other.polylineId;

  @override
  int get hashCode => polylineId.hashCode;

  @override
  String toString() => 'Polyline($polylineId with ${points.length} points)';
}