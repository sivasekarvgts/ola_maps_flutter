import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ola_maps_flutter/ola_maps_flutter.dart';
import 'dart:ui' as ui;
import 'package:ola_maps_flutter/src/models/bezier_curve.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OlaMaps Flutter Demo',
      theme: ThemeData(primarySwatch: Colors.green, useMaterial3: true),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OlaMaps Flutter Examples'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Basic Map'),
            subtitle: const Text('Display a simple interactive map'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BasicMapExample()),
                ),
          ),
          ListTile(
            title: const Text('Predefined Markers'),
            subtitle: const Text('Show markers at specific locations'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PredefinedMarkersExample(),
                  ),
                ),
          ),
          ListTile(
            title: const Text('Markers Demo'),
            subtitle: const Text('Add, remove, and update markers'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MarkersExample()),
                ),
          ),
          ListTile(
            title: const Text('Polylines Demo'),
            subtitle: const Text('Draw routes and paths on the map'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PolylinesExample()),
                ),
          ),
          ListTile(
            title: const Text('Camera Controls'),
            subtitle: const Text('Animate and move camera'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CameraExample()),
                ),
          ),
          ListTile(
            title: const Text('Map Events'),
            subtitle: const Text('Handle map click and camera events'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EventsExample()),
                ),
          ),
          ListTile(
            title: const Text('Location Tracking'),
            subtitle: const Text('Show current location on map'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LocationExample()),
                ),
          ),
        ],
      ),
    );
  }
}

// Basic Map Example
class BasicMapExample extends StatefulWidget {
  const BasicMapExample({Key? key}) : super(key: key);

  @override
  State<BasicMapExample> createState() => _BasicMapExampleState();
}

class _BasicMapExampleState extends State<BasicMapExample> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Basic Map')),
      body: OlaMap(
        // TODO: Replace with your actual credentials
        apiKey: 'API-KEY',
        tileURL:
            'https://api.olamaps.io/tiles/vector/v1/styles/default-light-standard/style.json',
        projectId: '04f0ab5b-6bbf-40fa-adda-9ef3eecd17ae',
        initialCameraPosition: const CameraPosition(
          target: LatLng(12.9716, 77.5946), // Bangalore coordinates
          zoom: 12,
        ),
        onMapCreated: (controller) {
          // Map created successfully
        },
      ),
    );
  }
}

// Predefined Markers Example
class PredefinedMarkersExample extends StatefulWidget {
  const PredefinedMarkersExample({Key? key}) : super(key: key);

  @override
  State<PredefinedMarkersExample> createState() =>
      _PredefinedMarkersExampleState();
}

class _PredefinedMarkersExampleState extends State<PredefinedMarkersExample> {
  OlaMapController? _controller;
  List<String> _markerIds = [];
  Map<String, Map<String, dynamic>> _markerData = {};
  final List<String> _curveIds = [];

  // Hardcoded locations with specific lat-long
  final List<Map<String, dynamic>> predefinedLocations = [
    {
      'id': 'location_1',
      'position': const LatLng(12.9314, 77.6164),
      'snippet': 'MG Road Metro Station',
      'title': 'Location 1',
      'description': 'Popular metro station in the heart of Bangalore',
      'type': 'Transit',
      'rating': 4.5,
    },
    {
      'id': 'location_2',
      'position': const LatLng(12.9318, 77.6144),
      'snippet': 'Brigade Road',
      'title': 'Location 2',
      'description': 'Famous shopping and dining street',
      'type': 'Shopping',
      'rating': 4.3,
    },
    {
      'id': 'location_3',
      'position': const LatLng(12.9343, 77.6148),
      'snippet': 'Church Street',
      'title': 'Location 3',
      'description': 'Historic street with colonial architecture',
      'type': 'Heritage',
      'rating': 4.2,
    },
    {
      'id': 'location_4',
      'position': const LatLng(12.9352, 77.6136),
      'snippet': 'Commercial Street',
      'title': 'Location 4',
      'description': 'Bustling market area for textiles and jewelry',
      'type': 'Shopping',
      'rating': 4.4,
    },
    {
      'id': 'location_5',
      'position': const LatLng(12.9376, 77.6143),
      'snippet': 'Shivaji Nagar',
      'title': 'Location 5',
      'description': 'Major commercial and residential area',
      'type': 'Commercial',
      'rating': 4.1,
    },
  ];

  void _addPredefinedMarkers() async {
    // Clear existing markers
    await _controller?.clearMarkers();
    _markerData.clear();
    _markerIds.clear();

    // Add markers and store their data
    for (final location in predefinedLocations) {
      print('Adding marker with custom icon: ${location['id']}');
      final markerId = await _controller?.addMarker(
        Marker(
          markerId: location['id'],
          position: location['position'],
          snippet: location['snippet'],
          title: location['title'],
          icon: MarkerIcon.fromAsset("assets/pin.png"),
          isIconClickable: true,
          isAnimationEnable: true,
          isInfoWindowDismissOnClick: true,
        ),
      );

      if (markerId != null) {
        _markerIds.add(markerId);
        _markerData[markerId] = location;
        print('Successfully added marker: $markerId');
      } else {
        print('Failed to add marker: ${location['id']}');
      }
    }

    setState(() {});
    print('Added ${_markerIds.length} predefined markers');
  }

  Future<Uint8List> createGreenFlagMarker() async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);

    const double width = 100;
    const double height = 100;

    // Draw flag pole
    final Paint polePaint = Paint()..color = Colors.black;
    canvas.drawRect(Rect.fromLTWH(10, 10, 6, 60), polePaint);

    // Draw flag (green rectangle)
    final Paint flagPaint = Paint()..color = Colors.green;
    final Path flagPath = Path();
    flagPath.moveTo(16, 10);
    flagPath.lineTo(70, 30);
    flagPath.lineTo(16, 50);
    flagPath.close();
    canvas.drawPath(flagPath, flagPaint);

    final ui.Image img = await recorder.endRecording().toImage(
      width.toInt(),
      height.toInt(),
    );
    final ByteData? byteData = await img.toByteData(
      format: ui.ImageByteFormat.png,
    );

    return byteData!.buffer.asUint8List();
  }

  void _addTestMarkerWithBytesIcon() async {
    // Create a custom marker with bytes-based icon
    print('Creating custom bytes icon...');
    final customIcon = await createGreenFlagMarker();
    print('Custom icon created with ${customIcon.length} bytes');

    final id = await _controller?.addMarker(
      Marker(
        markerId: 'test_marker_${DateTime.now().millisecondsSinceEpoch}',
        position: const LatLng(12.9350, 77.6100),
        snippet: 'Test Marker with Custom Icon',
        title: 'Custom Bytes Icon',
        icon: MarkerIcon.fromBytes(customIcon),
        isIconClickable: true,
        isAnimationEnable: true,
        isInfoWindowDismissOnClick: true,
      ),
    );

    if (id != null) {
      setState(() {
        _markerIds.add(id);
        _markerData[id] = {
          'position': const LatLng(12.9350, 77.6100),
          'snippet': 'Test Marker with Custom Icon',
          'title': 'Custom Bytes Icon',
          'description': 'This marker uses a custom icon created from bytes',
          'type': 'Test',
        };
      });
      print('Added test marker with bytes icon: $id');
    } else {
      print('Failed to add test marker with bytes icon');
    }
  }

  void _testAssetLoading() async {
    // Test if we can load the asset
    try {
      print('Testing asset loading...');
      final ByteData data = await rootBundle.load('assets/pin.png');
      print('Asset loaded successfully: ${data.lengthInBytes} bytes');

      // Create a marker with the loaded asset
      final id = await _controller?.addMarker(
        Marker(
          markerId: 'asset_test_${DateTime.now().millisecondsSinceEpoch}',
          position: const LatLng(12.9300, 77.6000),
          snippet: 'Asset Test Marker',
          title: 'Asset Test',
          icon: MarkerIcon.fromAsset("assets/pin.png"),
          isIconClickable: true,
          isAnimationEnable: true,
          isInfoWindowDismissOnClick: true,
        ),
      );

      if (id != null) {
        setState(() {
          _markerIds.add(id);
          _markerData[id] = {
            'position': const LatLng(12.9300, 77.6000),
            'snippet': 'Asset Test Marker',
            'title': 'Asset Test',
            'description': 'This marker tests asset loading',
            'type': 'Test',
          };
        });
        print('Added asset test marker: $id');
      }
    } catch (e) {
      print('Error loading asset: $e');
    }
  }

  void _showMarkerBottomSheet(String markerId) {
    print('TAPPED  JHD');
    final data = _markerData[markerId];
    if (data == null) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    data['snippet'] ?? 'Location',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (data['type'] != null)
                Chip(
                  label: Text(data['type']),
                  backgroundColor: Colors.blue.shade100,
                ),
              const SizedBox(height: 10),
              Text(
                data['description'] ?? 'No description available',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 15),
              if (data['rating'] != null)
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 20),
                    const SizedBox(width: 5),
                    Text(
                      '${data['rating']} / 5.0',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              const SizedBox(height: 15),
              Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.grey, size: 20),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      'Lat: ${(data['position'] as LatLng).latitude.toStringAsFixed(4)}, '
                      'Lng: ${(data['position'] as LatLng).longitude.toStringAsFixed(4)}',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _controller?.animateCamera(
                          target: data['position'],
                          zoom: 18,
                        );
                      },
                      icon: const Icon(Icons.zoom_in),
                      label: const Text('Zoom In'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _controller?.showInfoWindow(markerId);
                      },
                      icon: const Icon(Icons.info),
                      label: const Text('Show Info'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _addSingleMarker() async {
    // Add a single marker at a specific hardcoded location with custom icon
    final markerId = 'single_marker_${DateTime.now().millisecondsSinceEpoch}';
    final id = await _controller?.addMarker(
      Marker(
        markerId: markerId,
        position: const LatLng(12.9400, 77.6200),
        snippet: 'Single Marker Location',
        title: 'Custom Point',
        icon: MarkerIcon.fromAsset("assets/pin.png"),
        isIconClickable: true,
        isAnimationEnable: true,
        isInfoWindowDismissOnClick: true,
      ),
    );

    if (id != null) {
      setState(() {
        _markerIds.add(id);
        _markerData[id] = {
          'position': const LatLng(12.9400, 77.6200),
          'snippet': 'Single Marker Location',
          'title': 'Custom Point',
          'description':
              'This is a manually added single marker with custom icon',
          'type': 'Custom',
        };
      });
      print('Added single marker with custom icon: $id');
    }
  }

  void _showMarkerAtSpecificLocation(
    double lat,
    double lng,
    String name,
    String description,
    String type,
  ) async {
    final markerId = 'specific_${DateTime.now().millisecondsSinceEpoch}';
    final id = await _controller?.addMarkerAtLocation(
      latitude: lat,
      longitude: lng,
      snippet: name,
      markerId: markerId,
    );

    if (id != null) {
      setState(() {
        _markerIds.add(id);
        _markerData[id] = {
          'position': LatLng(lat, lng),
          'snippet': name,
          'description': description,
          'type': type,
        };
      });

      // Zoom to the new marker
      _controller?.animateCamera(target: LatLng(lat, lng), zoom: 16);

      // Show info window
      _controller?.showInfoWindow(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Predefined Markers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () async {
              await _controller?.clearMarkers();
              setState(() {
                _markerIds.clear();
              });
            },
            tooltip: 'Clear all markers',
          ),
        ],
      ),
      body: Stack(
        children: [
          OlaMap(
            // TODO: Replace with your actual credentials
            apiKey: 'API-KEY',
            tileURL:
                'https://api.olamaps.io/tiles/vector/v1/styles/default-light-standard/style.json',
            projectId: '04f0ab5b-6bbf-40fa-adda-9ef3eecd17ae',
            initialCameraPosition: const CameraPosition(
              target: LatLng(
                12.9345,
                77.6150,
              ), // Center of predefined locations
              zoom: 15,
            ),
            onMapCreated: (controller) {
              setState(() {
                _controller = controller;
              });
              print("MAP READY");
              // Listen for marker tap events
              controller.onMarkerTap.listen((markerId) {
                print("MAP READY1212");
                _showMarkerBottomSheet(markerId);
              });

              // Automatically add predefined markers when map is ready
              Future.delayed(const Duration(milliseconds: 2000), () {
                _addPredefinedMarkers();
              });
            },
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Total Markers: ${_markerIds.length}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _addPredefinedMarkers,
                            icon: const Icon(Icons.location_on),
                            label: const Text('Load 5 Markers'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _addSingleMarker,
                            icon: const Icon(Icons.add_location),
                            label: const Text('Add Single'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Quick Add Markers:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ActionChip(
                          label: const Text('Cubbon Park'),
                          onPressed:
                              () => _showMarkerAtSpecificLocation(
                                12.9763,
                                77.5929,
                                'Cubbon Park',
                                'A large public park with lush greenery in the heart of the city',
                                'Park',
                              ),
                        ),
                        ActionChip(
                          label: const Text('Lalbagh'),
                          onPressed:
                              () => _showMarkerAtSpecificLocation(
                                12.9507,
                                77.5848,
                                'Lalbagh Botanical Garden',
                                'Historic botanical garden with rare plant species and glasshouse',
                                'Garden',
                              ),
                        ),
                        ActionChip(
                          label: const Text('Vidhana Soudha'),
                          onPressed:
                              () => _showMarkerAtSpecificLocation(
                                12.9794,
                                77.5907,
                                'Vidhana Soudha',
                                'Iconic legislative building and seat of Karnataka government',
                                'Government',
                              ),
                        ),
                        ActionChip(
                          label: const Text('ISKCON Temple'),
                          onPressed:
                              () => _showMarkerAtSpecificLocation(
                                12.9716,
                                77.6411,
                                'ISKCON Temple',
                                'Famous Krishna temple with beautiful architecture',
                                'Temple',
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              if (_controller == null) return;
                              final id = await _controller!.addBezierCurve(
                                BezierCurve(
                                  curveId:
                                      'bcurve_${DateTime.now().millisecondsSinceEpoch}',
                                  startPoint: const LatLng(
                                    23.036885,
                                    72.561059,
                                  ),
                                  endPoint: const LatLng(23.037355, 72.567242),
                                  lineType: BezierLineType.dotted,
                                  color: const Color(0xFF000000),
                                ),
                              );
                              setState(() {
                                _curveIds.add(id);
                              });
                            },
                            icon: const Icon(Icons.timeline),
                            label: const Text('Add Bezier Curve'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              await _controller?.clearBezierCurves();
                              setState(() {
                                _curveIds.clear();
                              });
                            },
                            icon: const Icon(Icons.clear),
                            label: const Text('Clear Curves'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _addTestMarkerWithBytesIcon,
                            icon: const Icon(Icons.flag),
                            label: const Text('Test Bytes Icon'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _testAssetLoading,
                            icon: const Icon(Icons.image),
                            label: const Text('Test Asset'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed:
                          () => _controller?.animateCamera(
                            target: const LatLng(12.9345, 77.6150),
                            zoom: 15,
                          ),
                      icon: const Icon(Icons.zoom_out_map),
                      label: const Text('Show All Markers'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Markers Example
class MarkersExample extends StatefulWidget {
  const MarkersExample({Key? key}) : super(key: key);

  @override
  State<MarkersExample> createState() => _MarkersExampleState();
}

class _MarkersExampleState extends State<MarkersExample> {
  OlaMapController? _controller;
  int _markerIdCounter = 0;

  void _addMarker(LatLng position) async {
    await _controller?.addMarkerAtLocation(
      latitude: 12.9314,
      longitude: 77.6164,
      snippet: 'MG Road',
      markerId: 'mg_road',
    );

    final markerId = 'marker_$_markerIdCounter';
    _markerIdCounter++;

    //
    // await _controller?.addMarker(
    //   Marker(
    //     markerId: markerId,
    //     position: position,
    //     title: 'Marker $markerId',
    //     snippet: 'Tap to see more',
    //     draggable: true,
    //   ),
    // );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Markers Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () => _controller?.clearMarkers(),
            tooltip: 'Clear all markers',
          ),
        ],
      ),
      body: Stack(
        children: [
          OlaMap(
            // TODO: Replace with your actual credentials
            apiKey: 'API-KEY',
            tileURL:
                'https://api.olamaps.io/tiles/vector/v1/styles/default-light-standard/style.json',
            projectId: '04f0ab5b-6bbf-40fa-adda-9ef3eecd17ae',
            initialCameraPosition: const CameraPosition(
              target: LatLng(12.9716, 77.5946),
              zoom: 12,
            ),
            onMapCreated: (controller) {
              setState(() {
                _controller = controller;
              });

              // Listen to map clicks to add markers
              controller.onMapClick.listen((position) {
                _addMarker(position);
              });
            },
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Tap on the map to add markers',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Polylines Example
class PolylinesExample extends StatefulWidget {
  const PolylinesExample({Key? key}) : super(key: key);

  @override
  State<PolylinesExample> createState() => _PolylinesExampleState();
}

class _PolylinesExampleState extends State<PolylinesExample> {
  OlaMapController? _controller;
  final List<String> _polylineIds = [];
  int _polylineCounter = 0;

  void _addRoutePolyline() {
    final polylineId = 'route_$_polylineCounter';
    _polylineCounter++;

    // Create a route from Bangalore city center to Airport
    final routePoints = [
      const LatLng(12.9716, 77.5946), // MG Road
      const LatLng(12.9719, 77.6412), // Indiranagar
      const LatLng(12.9941, 77.6599), // KR Puram
      const LatLng(13.0358, 77.6970), // Hebbal
      const LatLng(13.1986, 77.7066), // Kempegowda Airport
    ];

    _controller?.addPolyline(
      Polyline(
        polylineId: polylineId,
        points: routePoints,
        color: Colors.blue,
        width: 5.0,
      ),
    );

    setState(() {
      _polylineIds.add(polylineId);
    });

    // Zoom to show the entire route
    _controller?.animateCamera(
      target: const LatLng(13.0851, 77.6500),
      zoom: 10.5,
    );
  }

  void _addNavigationPolyline() {
    final polylineId = 'navigation_$_polylineCounter';
    _polylineCounter++;

    // Create a navigation path with turns
    final navigationPoints = [
      const LatLng(12.9314, 77.6164), // Start
      const LatLng(12.9318, 77.6144), // Turn 1
      const LatLng(12.9343, 77.6148), // Turn 2
      const LatLng(12.9352, 77.6136), // Turn 3
      const LatLng(12.9376, 77.6143), // End
    ];

    _controller?.addPolyline(
      Polyline(
        polylineId: polylineId,
        points: navigationPoints,
        color: Colors.green,
        width: 8.0,
      ),
    );

    setState(() {
      _polylineIds.add(polylineId);
    });

    // Zoom to navigation area
    _controller?.animateCamera(
      target: const LatLng(12.9345, 77.6150),
      zoom: 16,
    );
  }

  void _addCustomPolyline() {
    final polylineId = 'custom_$_polylineCounter';
    _polylineCounter++;

    // Create a decorative polyline pattern
    final customPoints = <LatLng>[];
    for (int i = 0; i <= 10; i++) {
      customPoints.add(
        LatLng(
          12.9716 + (i * 0.003),
          77.5946 + (i * 0.002) + (i.isEven ? 0.002 : -0.002),
        ),
      );
    }

    _controller?.addPolyline(
      Polyline(
        polylineId: polylineId,
        points: customPoints,
        color: Colors.purple,
        width: 3.0,
      ),
    );

    setState(() {
      _polylineIds.add(polylineId);
    });

    // Zoom to custom area
    _controller?.animateCamera(
      target: const LatLng(12.9850, 77.6050),
      zoom: 13,
    );
  }

  void _updateLastPolyline() {
    if (_polylineIds.isNotEmpty) {
      // Generate new random points for the last polyline
      final newPoints = <LatLng>[];
      for (int i = 0; i <= 5; i++) {
        newPoints.add(LatLng(12.9716 + (i * 0.005), 77.5946 + (i * 0.003)));
      }

      _controller?.updatePolyline(_polylineIds.last, newPoints);

      // Show a snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Updated polyline: ${_polylineIds.last}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _removeLastPolyline() {
    if (_polylineIds.isNotEmpty) {
      final polylineId = _polylineIds.removeLast();
      _controller?.removePolyline(polylineId);
      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Removed polyline: $polylineId'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _clearAllPolylines() {
    _controller?.clearPolylines();
    setState(() {
      _polylineIds.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cleared all polylines'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Polylines Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: _clearAllPolylines,
            tooltip: 'Clear all polylines',
          ),
        ],
      ),
      body: Stack(
        children: [
          OlaMap(
            // TODO: Replace with your actual credentials
            apiKey: 'API-KEY',
            tileURL:
                'https://api.olamaps.io/tiles/vector/v1/styles/default-light-standard/style.json',
            projectId: '04f0ab5b-6bbf-40fa-adda-9ef3eecd17ae',
            initialCameraPosition: const CameraPosition(
              target: LatLng(12.9716, 77.5946),
              zoom: 11,
            ),
            onMapCreated: (controller) {
              setState(() {
                _controller = controller;
              });

              // Add initial polyline
              _addRoutePolyline();
            },
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Polylines: ${_polylineIds.length}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _addRoutePolyline,
                          icon: const Icon(Icons.route, size: 18),
                          label: const Text('Add Route'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _addNavigationPolyline,
                          icon: const Icon(Icons.navigation, size: 18),
                          label: const Text('Add Navigation'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _addCustomPolyline,
                          icon: const Icon(Icons.gesture, size: 18),
                          label: const Text('Add Custom'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed:
                              _polylineIds.isEmpty ? null : _updateLastPolyline,
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text('Update Last'),
                        ),
                        OutlinedButton.icon(
                          onPressed:
                              _polylineIds.isEmpty ? null : _removeLastPolyline,
                          icon: const Icon(Icons.remove_circle, size: 18),
                          label: const Text('Remove Last'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Camera Example
class CameraExample extends StatefulWidget {
  const CameraExample({Key? key}) : super(key: key);

  @override
  State<CameraExample> createState() => _CameraExampleState();
}

class _CameraExampleState extends State<CameraExample> {
  OlaMapController? _controller;
  double _currentZoom = 12;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Camera Controls')),
      body: Stack(
        children: [
          OlaMap(
            // TODO: Replace with your actual credentials
            apiKey: 'API-KEY',
            tileURL:
                'https://api.olamaps.io/tiles/vector/v1/styles/default-light-standard/style.json',
            projectId: '04f0ab5b-6bbf-40fa-adda-9ef3eecd17ae',
            initialCameraPosition: const CameraPosition(
              target: LatLng(12.9716, 77.5946),
              zoom: 12,
            ),
            onMapCreated: (controller) {
              setState(() {
                _controller = controller;
              });

              controller.onCameraMove.listen((position) {
                setState(() {
                  _currentZoom = position.zoom;
                });
              });
            },
          ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Current Zoom: ${_currentZoom.toStringAsFixed(2)}'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        ElevatedButton(
                          onPressed:
                              () => _controller?.animateCamera(
                                target: const LatLng(
                                  13.0827,
                                  80.2707,
                                ), // Chennai
                                zoom: 12,
                              ),
                          child: const Text('Go to Chennai'),
                        ),
                        ElevatedButton(
                          onPressed:
                              () => _controller?.animateCamera(
                                target: const LatLng(
                                  19.0760,
                                  72.8777,
                                ), // Mumbai
                                zoom: 12,
                              ),
                          child: const Text('Go to Mumbai'),
                        ),
                        ElevatedButton(
                          onPressed:
                              () => _controller?.animateCamera(
                                zoom: _currentZoom + 1,
                              ),
                          child: const Text('Zoom In'),
                        ),
                        ElevatedButton(
                          onPressed:
                              () => _controller?.animateCamera(
                                zoom: _currentZoom - 1,
                              ),
                          child: const Text('Zoom Out'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Events Example
class EventsExample extends StatefulWidget {
  const EventsExample({Key? key}) : super(key: key);

  @override
  State<EventsExample> createState() => _EventsExampleState();
}

class _EventsExampleState extends State<EventsExample> {
  OlaMapController? _controller;
  String _lastEvent = 'No events yet';
  LatLng? _lastClickedPosition;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Map Events')),
      body: Stack(
        children: [
          OlaMap(
            // TODO: Replace with your actual credentials
            apiKey: 'API-KEY',
            tileURL:
                'https://api.olamaps.io/tiles/vector/v1/styles/default-light-standard/style.json',
            projectId: '04f0ab5b-6bbf-40fa-adda-9ef3eecd17ae',
            initialCameraPosition: const CameraPosition(
              target: LatLng(12.9716, 77.5946),
              zoom: 12,
            ),
            onMapCreated: (controller) {
              setState(() {
                _controller = controller;
              });

              // Listen to map events
              controller.onMapClick.listen((position) {
                setState(() {
                  _lastEvent =
                      'Map clicked at: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
                  _lastClickedPosition = position;
                });

                // Add marker at clicked position
                controller.addMarker(
                  Marker(
                    markerId: 'clicked_position',
                    position: position,
                    title: 'Clicked Position',
                  ),
                );
              });

              controller.onMapLongClick.listen((position) {
                setState(() {
                  _lastEvent =
                      'Map long-clicked at: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
                });
              });

              controller.onCameraIdle.listen((_) {
                setState(() {
                  _lastEvent = 'Camera idle';
                });
              });
            },
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Last Event:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(_lastEvent),
                    if (_lastClickedPosition != null) ...[
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed:
                            () => _controller?.animateCamera(
                              target: _lastClickedPosition!,
                              zoom: 15,
                            ),
                        child: const Text('Zoom to Last Click'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Location Example
class LocationExample extends StatefulWidget {
  const LocationExample({Key? key}) : super(key: key);

  @override
  State<LocationExample> createState() => _LocationExampleState();
}

class _LocationExampleState extends State<LocationExample> {
  OlaMapController? _controller;
  bool _myLocationEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Tracking'),
        actions: [
          Switch(
            value: _myLocationEnabled,
            onChanged: (value) {
              setState(() {
                _myLocationEnabled = value;
              });
              _controller?.setMyLocationEnabled(value);
            },
          ),
        ],
      ),
      body: OlaMap(
        // TODO: Replace with your actual credentials
        apiKey: 'API-KEY',
        tileURL:
            'https://api.olamaps.io/tiles/vector/v1/styles/default-light-standard/style.json',
        projectId: '04f0ab5b-6bbf-40fa-adda-9ef3eecd17ae',
        initialCameraPosition: const CameraPosition(
          target: LatLng(12.9716, 77.5946),
          zoom: 12,
        ),
        myLocationEnabled: _myLocationEnabled,
        onMapCreated: (controller) {
          setState(() {
            _controller = controller;
          });
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // In a real app, you would get the current location and animate to it
          _controller?.animateCamera(
            target: const LatLng(12.9716, 77.5946),
            zoom: 15,
          );
        },
        child: const Icon(Icons.my_location),
      ),
    );
  }
}
