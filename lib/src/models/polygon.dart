import 'package:flutter/material.dart';
import 'lat_lng.dart';

class Polygon {
  final String polygonId;
  final List<LatLng> points;
  final List<List<LatLng>>? holes;
  final Color strokeColor;
  final Color fillColor;
  final double strokeWidth;
  final bool geodesic;
  final VoidCallback? onTap;

  const Polygon({
    required this.polygonId,
    required this.points,
    this.holes,
    this.strokeColor = Colors.black,
    this.fillColor = const Color(0x7F0000FF),
    this.strokeWidth = 2.0,
    this.geodesic = false,
    this.onTap,
  });

  Map<String, dynamic> toJson() => {
        'polygonId': polygonId,
        'points': points.map((p) => p.toJson()).toList(),
        'holes': holes?.map((h) => h.map((p) => p.toJson()).toList()).toList(),
        'strokeColor': strokeColor.value,
        'fillColor': fillColor.value,
        'strokeWidth': strokeWidth,
        'geodesic': geodesic,
      };

  Polygon copyWith({
    String? polygonId,
    List<LatLng>? points,
    List<List<LatLng>>? holes,
    Color? strokeColor,
    Color? fillColor,
    double? strokeWidth,
    bool? geodesic,
    VoidCallback? onTap,
  }) =>
      Polygon(
        polygonId: polygonId ?? this.polygonId,
        points: points ?? this.points,
        holes: holes ?? this.holes,
        strokeColor: strokeColor ?? this.strokeColor,
        fillColor: fillColor ?? this.fillColor,
        strokeWidth: strokeWidth ?? this.strokeWidth,
        geodesic: geodesic ?? this.geodesic,
        onTap: onTap ?? this.onTap,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Polygon &&
          runtimeType == other.runtimeType &&
          polygonId == other.polygonId;

  @override
  int get hashCode => polygonId.hashCode;

  @override
  String toString() => 'Polygon($polygonId with ${points.length} points)';
}