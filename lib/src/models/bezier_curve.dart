import 'package:flutter/material.dart';
import 'lat_lng.dart';

enum BezierLineType { solid, dotted, dashed }

String _lineTypeToString(BezierLineType type) {
  switch (type) {
    case BezierLineType.solid:
      return 'LINE_SOLID';
    case BezierLineType.dotted:
      return 'LINE_DOTTED';
    case BezierLineType.dashed:
      return 'LINE_DASHED';
  }
}

class BezierCurve {
  final String curveId;
  final LatLng startPoint;
  final LatLng endPoint;
  final BezierLineType lineType;
  final Color color;

  const BezierCurve({
    required this.curveId,
    required this.startPoint,
    required this.endPoint,
    this.lineType = BezierLineType.solid,
    this.color = const Color(0xFF000000),
  });

  Map<String, dynamic> toJson() => {
    'curveId': curveId,
    'startPoint': startPoint.toJson(),
    'endPoint': endPoint.toJson(),
    'lineType': _lineTypeToString(lineType),
    'color': '#${color.value.toRadixString(16).padLeft(8, '0').toUpperCase()}',
  };
}
