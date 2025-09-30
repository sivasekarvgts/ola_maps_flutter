import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'lat_lng.dart';

enum MarkerIconType {
  asset,
  bytes,
  defaultIcon,
}

class MarkerIcon {
  final MarkerIconType type;
  final String? assetName;
  final Uint8List? bytes;
  final double? width;
  final double? height;
  final String anchor; // 'center', 'top-left', 'top-right', 'bottom-left', 'bottom-right'
  final List<double>? offset; // [x, y] offset
  final double scale;

  const MarkerIcon({
    required this.type,
    this.assetName,
    this.bytes,
    this.width,
    this.height,
    this.anchor = 'center',
    this.offset,
    this.scale = 1.0,
  });

  factory MarkerIcon.fromAsset(
    String assetName, {
    double? width,
    double? height,
    String anchor = 'center',
    List<double>? offset,
    double scale = 1.0,
  }) {
    return MarkerIcon(
      type: MarkerIconType.asset,
      assetName: assetName,
      width: width,
      height: height,
      anchor: anchor,
      offset: offset,
      scale: scale,
    );
  }

  factory MarkerIcon.fromBytes(
    Uint8List bytes, {
    double? width,
    double? height,
    String anchor = 'center',
    List<double>? offset,
    double scale = 1.0,
  }) {
    return MarkerIcon(
      type: MarkerIconType.bytes,
      bytes: bytes,
      width: width,
      height: height,
      anchor: anchor,
      offset: offset,
      scale: scale,
    );
  }

  factory MarkerIcon.defaultIcon() {
    return const MarkerIcon(type: MarkerIconType.defaultIcon);
  }

  Map<String, dynamic> toJson() => {
        'type': type.toString().split('.').last,
        'assetName': assetName,
        'bytes': bytes,
        'width': width,
        'height': height,
        'anchor': anchor,
        'offset': offset,
        'scale': scale,
      };
}

class Marker {
  final String markerId;
  final LatLng position;
  final String? title;
  final String? snippet;
  final String? subSnippet;
  final bool draggable;
  final double rotation;
  final double alpha;
  final bool isIconClickable;
  final bool isAnimationEnable;
  final bool isInfoWindowDismissOnClick;
  final MarkerIcon? icon;
  final VoidCallback? onTap;
  final VoidCallback? onDragEnd;
  final VoidCallback? onInfoWindowTap;

  const Marker({
    required this.markerId,
    required this.position,
    this.title,
    this.snippet,
    this.subSnippet,
    this.draggable = false,
    this.rotation = 0.0,
    this.alpha = 1.0,
    this.isIconClickable = true,
    this.isAnimationEnable = true,
    this.isInfoWindowDismissOnClick = true,
    this.icon,
    this.onTap,
    this.onDragEnd,
    this.onInfoWindowTap,
  });

  Map<String, dynamic> toJson() => {
        'markerId': markerId,
        'position': position.toJson(),
        'title': title,
        'snippet': snippet,
        'subSnippet': subSnippet,
        'draggable': draggable,
        'rotation': rotation,
        'alpha': alpha,
        'isIconClickable': isIconClickable,
        'isAnimationEnable': isAnimationEnable,
        'isInfoWindowDismissOnClick': isInfoWindowDismissOnClick,
        'icon': icon?.toJson(),
      };

  Marker copyWith({
    String? markerId,
    LatLng? position,
    String? title,
    String? snippet,
    String? subSnippet,
    bool? draggable,
    double? rotation,
    double? alpha,
    bool? isIconClickable,
    bool? isAnimationEnable,
    bool? isInfoWindowDismissOnClick,
    MarkerIcon? icon,
    VoidCallback? onTap,
    VoidCallback? onDragEnd,
    VoidCallback? onInfoWindowTap,
  }) =>
      Marker(
        markerId: markerId ?? this.markerId,
        position: position ?? this.position,
        title: title ?? this.title,
        snippet: snippet ?? this.snippet,
        subSnippet: subSnippet ?? this.subSnippet,
        draggable: draggable ?? this.draggable,
        rotation: rotation ?? this.rotation,
        alpha: alpha ?? this.alpha,
        isIconClickable: isIconClickable ?? this.isIconClickable,
        isAnimationEnable: isAnimationEnable ?? this.isAnimationEnable,
        isInfoWindowDismissOnClick: isInfoWindowDismissOnClick ?? this.isInfoWindowDismissOnClick,
        icon: icon ?? this.icon,
        onTap: onTap ?? this.onTap,
        onDragEnd: onDragEnd ?? this.onDragEnd,
        onInfoWindowTap: onInfoWindowTap ?? this.onInfoWindowTap,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Marker &&
          runtimeType == other.runtimeType &&
          markerId == other.markerId;

  @override
  int get hashCode => markerId.hashCode;

  @override
  String toString() => 'Marker($markerId at $position)';
}