package com.olakrutrim.ola_maps_flutter

import android.content.Context
import android.view.View
import android.widget.FrameLayout
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.platform.PlatformView

class OlaMapView(
    private val context: Context,
    private val id: Int,
    private val creationParams: Map<String, Any?>?,
    private val binaryMessenger: BinaryMessenger
) : PlatformView, MethodCallHandler {

    private val container: FrameLayout = FrameLayout(context)
    private var mapView: Any? = null  // Will be OlaMapView instance
    private var olaMap: Any? = null   // Will be OlaMap instance
    private val methodChannel: MethodChannel
    
    // Store references to map elements for management
    private val markers = mutableMapOf<String, Any>()
    private val polylines = mutableMapOf<String, Any>()
    private val polygons = mutableMapOf<String, Any>()
    private val circles = mutableMapOf<String, Any>()

    init {
        methodChannel = MethodChannel(binaryMessenger, "ola_maps_flutter_$id")
        methodChannel.setMethodCallHandler(this)
        initializeMap()
    }
    
    // Helper method to create OlaLatLng with SDK 1.8.4
    private fun createOlaLatLng(lat: Double, lng: Double): Any {
        val latLngClass = Class.forName("com.ola.mapsdk.model.OlaLatLng")
        return try {
            // Try constructor with two doubles
            val constructor = latLngClass.getConstructor(
                Double::class.java,
                Double::class.java
            )
            constructor.newInstance(lat, lng)
        } catch (e: NoSuchMethodException) {
            // Try to use a factory method or different approach
            try {
                // Check if there's a static method to create
                val createMethod = latLngClass.getMethod(
                    "create",
                    Double::class.java,
                    Double::class.java
                )
                createMethod.invoke(null, lat, lng)
            } catch (e2: Exception) {
                // Try using default constructor and setting fields
                val instance = latLngClass.getDeclaredConstructor().newInstance()
                val latField = latLngClass.getDeclaredField("latitude")
                val lngField = latLngClass.getDeclaredField("longitude")
                latField.isAccessible = true
                lngField.isAccessible = true
                latField.set(instance, lat)
                lngField.set(instance, lng)
                instance
            }
        }
    }

    private fun initializeMap() {
        try {
            val apiKey = creationParams?.get("apiKey") as? String ?: ""
            
            // Use reflection to create OlaMapView since we don't know exact constructor
            val mapViewClass = Class.forName("com.ola.mapsdk.view.OlaMapView")
            val constructor = mapViewClass.getConstructor(Context::class.java)
            mapView = constructor.newInstance(context)
            
            if (mapView is View) {
                container.addView(mapView as View)
            }
            
            // Try to call getMap method with proper callback
            try {
                // Create MapControlSettings using reflection since constructor is private
                val settingsClass = Class.forName("com.ola.mapsdk.camera.MapControlSettings")
                val settingsConstructor = settingsClass.getDeclaredConstructor(
                    Boolean::class.java, Boolean::class.java, Boolean::class.java,
                    Boolean::class.java, Boolean::class.java, Boolean::class.java
                )
                settingsConstructor.isAccessible = true
                val mapSettings = settingsConstructor.newInstance(
                    true, true, true, true, true, true
                )
                
                val getMapMethod = mapViewClass.getMethod("getMap", 
                    String::class.java,  // API key
                    Class.forName("com.ola.mapsdk.interfaces.OlaMapCallback"),
                    settingsClass
                )
                
                // Create callback using reflection
                val callbackInterface = Class.forName("com.ola.mapsdk.interfaces.OlaMapCallback")
                val callback = java.lang.reflect.Proxy.newProxyInstance(
                    callbackInterface.classLoader,
                    arrayOf(callbackInterface)
                ) { _, method, args ->
                    when (method.name) {
                        "onMapReady" -> {
                            olaMap = args?.get(0)
                            setupMap()
                            methodChannel.invokeMethod("onMapReady", null)
                        }
                        "onMapError" -> {
                            val error = args?.get(0) as? String ?: "Unknown error"
                            android.util.Log.e("OlaMapView", "Map error: $error")
                            methodChannel.invokeMethod("onMapError", mapOf("error" to error))
                        }
                    }
                    null
                }
                
                getMapMethod.invoke(mapView, apiKey, callback, mapSettings)
                
            } catch (e: Exception) {
                android.util.Log.e("OlaMapView", "Error calling getMap", e)
                methodChannel.invokeMethod("onMapError", mapOf("error" to e.message))
            }
            
        } catch (e: Exception) {
            android.util.Log.e("OlaMapView", "Error initializing map", e)
            methodChannel.invokeMethod("onMapError", mapOf("error" to e.message))
        }
    }

    private fun setupMap() {
        olaMap?.let { map ->
            try {
                // Try to use setMarkerListener with MarkerEventListener (as seen in map methods)
                try {
                    val setMarkerListenerMethod = map.javaClass.getMethod("setMarkerListener",
                        Class.forName("com.ola.mapsdk.interfaces.MarkerEventListener"))
                    
                    val listenerInterface = Class.forName("com.ola.mapsdk.interfaces.MarkerEventListener")
                    
                    // Log available methods on MarkerEventListener interface
                    android.util.Log.d("OlaMapView", "MarkerEventListener methods:")
                    listenerInterface.methods.forEach { method ->
                        android.util.Log.d("OlaMapView", "  - ${method.name}(${method.parameterTypes.joinToString { it.simpleName }})")
                    }
                    
                    val listener = java.lang.reflect.Proxy.newProxyInstance(
                        listenerInterface.classLoader,
                        arrayOf(listenerInterface)
                    ) { _, method, args ->
                        android.util.Log.d("OlaMapView", "MarkerEventListener method called: ${method.name}")
                        
                        when (method.name) {
                            "onMarkerClicked" -> {
                                // The method signature is onMarkerClicked(String) - it passes the marker ID directly
                                val markerId = args?.get(0) as? String
                                if (markerId != null) {
                                    android.util.Log.d("OlaMapView", "Marker clicked with ID: $markerId")
                                    methodChannel.invokeMethod("onMarkerTap", markerId)
                                } else {
                                    android.util.Log.w("OlaMapView", "Marker clicked but ID is null")
                                }
                                null // Return value for void method
                            }
                            "onMarkerClick", "onMarkerTapped", "onClick" -> {
                                // Fallback for other possible method names
                                val marker = args?.get(0)
                                if (marker != null) {
                                    android.util.Log.d("OlaMapView", "Marker clicked via MarkerEventListener (fallback)")
                                    if (marker is String) {
                                        // Direct marker ID
                                        methodChannel.invokeMethod("onMarkerTap", marker)
                                    } else {
                                        // Marker object - find ID
                                        val markerId = markers.entries.find { it.value == marker }?.key
                                        if (markerId != null) {
                                            methodChannel.invokeMethod("onMarkerTap", markerId)
                                        }
                                    }
                                }
                                true
                            }
                            "onMarkerDragStart", "onMarkerDrag", "onMarkerDragEnd" -> {
                                // Handle drag events if needed
                                android.util.Log.d("OlaMapView", "Marker drag event: ${method.name}")
                                null
                            }
                            else -> {
                                android.util.Log.d("OlaMapView", "Unknown MarkerEventListener method: ${method.name}")
                                null
                            }
                        }
                    }
                    
                    setMarkerListenerMethod.invoke(map, listener)
                    android.util.Log.d("OlaMapView", "MarkerEventListener set successfully")
                } catch (e: Exception) {
                    android.util.Log.e("OlaMapView", "Could not set MarkerEventListener: ${e.message}", e)
                }
                
                // Also try to set up info window click listener as fallback
                try {
                    val setOnInfoWindowClickListenerMethod = map.javaClass.getMethod("setOnInfoWindowClickListener",
                        Class.forName("com.ola.mapsdk.interfaces.OnInfoWindowClickListener"))
                    
                    val listenerInterface = Class.forName("com.ola.mapsdk.interfaces.OnInfoWindowClickListener")
                    val listener = java.lang.reflect.Proxy.newProxyInstance(
                        listenerInterface.classLoader,
                        arrayOf(listenerInterface)
                    ) { _, method, args ->
                        android.util.Log.d("OlaMapView", "Info window method called: ${method.name}")
                        if (method.name == "onInfoWindowClick" || method.name == "onClick") {
                            val marker = args?.get(0)
                            if (marker != null) {
                                val markerId = markers.entries.find { it.value == marker }?.key
                                if (markerId != null) {
                                    android.util.Log.d("OlaMapView", "Info window clicked for marker: $markerId")
                                    methodChannel.invokeMethod("onMarkerTap", markerId)
                                }
                            }
                        }
                        null
                    }
                    
                    setOnInfoWindowClickListenerMethod.invoke(map, listener)
                    android.util.Log.d("OlaMapView", "Info window click listener set as fallback")
                } catch (e: Exception) {
                    android.util.Log.w("OlaMapView", "Could not set info window click listener: ${e.message}")
                }
                
                
                // Set initial camera position if provided
                creationParams?.get("initialCameraPosition")?.let { position ->
                    val cameraMap = position as Map<String, Any>
                    val target = cameraMap["target"] as Map<String, Any>
                    val lat = target["latitude"] as Double
                    val lng = target["longitude"] as Double
                    val zoom = (cameraMap["zoom"] as? Double) ?: 12.0
                    
                    // Try to zoom to location using reflection
                    try {
                        // Create OlaLatLng using helper method
                        val latLng = createOlaLatLng(lat, lng)
                        val latLngClass = Class.forName("com.ola.mapsdk.model.OlaLatLng")
                        
                        // Try zoomToLocation method
                        val zoomMethod = map.javaClass.getMethod(
                            "zoomToLocation",
                            latLngClass,
                            Double::class.java
                        )
                        zoomMethod.invoke(map, latLng, zoom)
                    } catch (e: Exception) {
                        android.util.Log.e("OlaMapView", "Could not set initial position", e)
                    }
                }
            } catch (e: Exception) {
                android.util.Log.e("OlaMapView", "Error in setupMap", e)
            }
        }
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "addMarker" -> {
                try {
                    val position = call.argument<Map<String, Double>>("position")
                    if (position != null) {
                        val lat = position["latitude"] ?: 0.0
                        val lng = position["longitude"] ?: 0.0
                        val markerId = call.argument<String>("markerId") ?: "marker_${System.currentTimeMillis()}"
                        val title = call.argument<String>("title")
                        val snippet = call.argument<String>("snippet") ?: ""
                        val subSnippet = call.argument<String>("subSnippet")
                        val rotation = call.argument<Double>("rotation")?.toFloat() ?: 0f
                        val isIconClickable = call.argument<Boolean>("isIconClickable") ?: true
                        val isAnimationEnable = call.argument<Boolean>("isAnimationEnable") ?: true
                        val isInfoWindowDismissOnClick = call.argument<Boolean>("isInfoWindowDismissOnClick") ?: true
                        
                        olaMap?.let { map ->
                            try {
                                android.util.Log.d("OlaMapView", "Adding marker at: $lat, $lng with snippet: $snippet")
                                
                                // Create OlaLatLng for the marker position
                                val latLngClass = Class.forName("com.ola.mapsdk.model.OlaLatLng")
                                val latLng = createOlaLatLng(lat, lng)
                                
                                // Use OlaMarkerOptions.Builder pattern
                                val markerOptionsClass = Class.forName("com.ola.mapsdk.model.OlaMarkerOptions")
                                val builderClass = Class.forName("com.ola.mapsdk.model.OlaMarkerOptions\$Builder")
                                
                                // Create Builder instance
                                val builderConstructor = builderClass.getDeclaredConstructor()
                                val builder = builderConstructor.newInstance()
                                
                                // Set marker ID - REQUIRED
                                val setMarkerIdMethod = builderClass.getMethod("setMarkerId", String::class.java)
                                setMarkerIdMethod.invoke(builder, markerId)
                                android.util.Log.d("OlaMapView", "Set marker ID: $markerId")
                                
                                // Set position - REQUIRED
                                val setPositionMethod = builderClass.getMethod("setPosition", latLngClass)
                                setPositionMethod.invoke(builder, latLng)
                                android.util.Log.d("OlaMapView", "Set position")
                                
                                // Set snippet for info window - This is important for showing info window
                                if (snippet.isNotEmpty() || title != null) {
                                    val infoText = snippet.ifEmpty { title ?: "Marker" }
                                    val setSnippetMethod = builderClass.getMethod("setSnippet", String::class.java)
                                    setSnippetMethod.invoke(builder, infoText)
                                    android.util.Log.d("OlaMapView", "Set snippet: $infoText")
                                }
                                
                                // Set icon clickable
                                val setIsIconClickableMethod = builderClass.getMethod("setIsIconClickable", Boolean::class.java)
                                setIsIconClickableMethod.invoke(builder, isIconClickable)
                                
                                // Set icon rotation
                                val setIconRotationMethod = builderClass.getMethod("setIconRotation", Float::class.java)
                                setIconRotationMethod.invoke(builder, rotation)
                                
                                // Set animation enable
                                val setIsAnimationEnableMethod = builderClass.getMethod("setIsAnimationEnable", Boolean::class.java)
                                setIsAnimationEnableMethod.invoke(builder, isAnimationEnable)
                                
                                // Set info window dismiss on click
                                val setIsInfoWindowDismissOnClickMethod = builderClass.getMethod("setIsInfoWindowDismissOnClick", Boolean::class.java)
                                setIsInfoWindowDismissOnClickMethod.invoke(builder, isInfoWindowDismissOnClick)
                                
                                // Build the marker options
                                val buildMethod = builderClass.getMethod("build")
                                val markerOptions = buildMethod.invoke(builder)
                                android.util.Log.d("OlaMapView", "Built marker options")
                                
                                // Add marker to map
                                val addMarkerMethod = map.javaClass.getMethod("addMarker", markerOptionsClass)
                                val marker = addMarkerMethod.invoke(map, markerOptions)
                                
                                if (marker != null) {
                                    markers[markerId] = marker
                                    
                                    // Log all available methods on the marker object for debugging
                                    android.util.Log.d("OlaMapView", "Available methods on marker object:")
                                    marker.javaClass.methods.forEach { method ->
                                        android.util.Log.d("OlaMapView", "  - ${method.name}(${method.parameterTypes.joinToString { it.simpleName }})")
                                    }
                                    
                                    // Try to set up info window click listener as an alternative
                                    try {
                                        // Check if marker has setInfoWindowClickable method
                                        val setInfoWindowClickableMethod = marker.javaClass.getMethod("setInfoWindowClickable", Boolean::class.java)
                                        setInfoWindowClickableMethod.invoke(marker, true)
                                        android.util.Log.d("OlaMapView", "Info window made clickable for marker: $markerId")
                                    } catch (e: Exception) {
                                        android.util.Log.w("OlaMapView", "Could not set info window clickable: ${e.message}")
                                    }
                                    
                                    // Try to check if marker is clickable
                                    try {
                                        val isClickableMethod = marker.javaClass.getMethod("isClickable")
                                        val isClickable = isClickableMethod.invoke(marker) as? Boolean
                                        android.util.Log.d("OlaMapView", "Marker $markerId isClickable: $isClickable")
                                    } catch (e: Exception) {
                                        android.util.Log.w("OlaMapView", "Could not check if marker is clickable: ${e.message}")
                                    }
                                    
                                    android.util.Log.d("OlaMapView", "Marker added successfully: $markerId")
                                    result.success(markerId)
                                } else {
                                    android.util.Log.e("OlaMapView", "Marker returned null")
                                    result.error("ERROR", "Failed to add marker - returned null", null)
                                }
                            } catch (e: Exception) {
                                android.util.Log.e("OlaMapView", "Failed to add marker: ${e.message}", e)
                                e.printStackTrace()
                                result.error("ERROR", "Failed to add marker: ${e.message}", null)
                            }
                        } ?: result.error("MAP_NOT_READY", "Map is not ready", null)
                    } else {
                        result.error("INVALID_ARGUMENT", "Position is required", null)
                    }
                } catch (e: Exception) {
                    android.util.Log.e("OlaMapView", "Error in addMarker: ${e.message}", e)
                    result.error("ERROR", e.message, null)
                }
            }
            "removeMarker" -> {
                try {
                    val markerId = call.argument<String>("markerId")
                    if (markerId != null) {
                        markers[markerId]?.let { marker ->
                            val removeMethod = marker.javaClass.getMethod("removeMarker")
                            removeMethod.invoke(marker)
                            markers.remove(markerId)
                            result.success(true)
                        } ?: result.error("NOT_FOUND", "Marker not found", null)
                    } else {
                        result.error("INVALID_ARGUMENT", "Marker ID is required", null)
                    }
                } catch (e: Exception) {
                    result.error("ERROR", e.message, null)
                }
            }
            "updateMarker" -> {
                try {
                    val markerId = call.argument<String>("markerId")
                    val position = call.argument<Map<String, Double>>("position")
                    val snippet = call.argument<String>("snippet")
                    val rotation = call.argument<Double>("rotation")?.toFloat()
                    
                    if (markerId != null) {
                        markers[markerId]?.let { marker ->
                            // Update marker properties using updateMarker method
                            try {
                                val updateMethod = marker.javaClass.getMethod(
                                    "updateMarker",
                                    Class.forName("com.ola.mapsdk.model.OlaLatLng"),
                                    String::class.java, // iconAnchor
                                    android.graphics.Bitmap::class.java, // iconBitmap
                                    Int::class.java, // iconIntRes
                                    FloatArray::class.java, // iconOffset
                                    Float::class.java, // iconRotation
                                    Float::class.java, // iconSize
                                    String::class.java, // snippet
                                    String::class.java // subSnippet
                                )
                                
                                // Create new position if provided
                                val newPosition = if (position != null) {
                                    createOlaLatLng(position["latitude"] ?: 0.0, position["longitude"] ?: 0.0)
                                } else null
                                
                                // Call update with available parameters
                                updateMethod.invoke(
                                    marker,
                                    newPosition,
                                    null, // iconAnchor
                                    null, // iconBitmap
                                    null, // iconIntRes
                                    null, // iconOffset
                                    rotation,
                                    null, // iconSize
                                    snippet,
                                    null // subSnippet
                                )
                                result.success(true)
                            } catch (e: Exception) {
                                // If specific update method doesn't exist, try simpler approach
                                if (position != null) {
                                    try {
                                        val setPositionMethod = marker.javaClass.getMethod(
                                            "setPosition",
                                            Class.forName("com.ola.mapsdk.model.OlaLatLng")
                                        )
                                        val newPosition = createOlaLatLng(
                                            position["latitude"] ?: 0.0,
                                            position["longitude"] ?: 0.0
                                        )
                                        setPositionMethod.invoke(marker, newPosition)
                                    } catch (e2: Exception) {
                                        // Position update not supported
                                    }
                                }
                                result.success(true)
                            }
                        } ?: result.error("NOT_FOUND", "Marker not found", null)
                    } else {
                        result.error("INVALID_ARGUMENT", "Marker ID is required", null)
                    }
                } catch (e: Exception) {
                    result.error("ERROR", e.message, null)
                }
            }
            "showInfoWindow" -> {
                try {
                    val markerId = call.argument<String>("markerId")
                    if (markerId != null) {
                        markers[markerId]?.let { marker ->
                            val showInfoWindowMethod = marker.javaClass.getMethod("showInfoWindow")
                            showInfoWindowMethod.invoke(marker)
                            result.success(true)
                        } ?: result.error("NOT_FOUND", "Marker not found", null)
                    } else {
                        result.error("INVALID_ARGUMENT", "Marker ID is required", null)
                    }
                } catch (e: Exception) {
                    result.error("ERROR", e.message, null)
                }
            }
            "hideInfoWindow" -> {
                try {
                    val markerId = call.argument<String>("markerId")
                    if (markerId != null) {
                        markers[markerId]?.let { marker ->
                            val hideInfoWindowMethod = marker.javaClass.getMethod("hideInfoWindow")
                            hideInfoWindowMethod.invoke(marker)
                            result.success(true)
                        } ?: result.error("NOT_FOUND", "Marker not found", null)
                    } else {
                        result.error("INVALID_ARGUMENT", "Marker ID is required", null)
                    }
                } catch (e: Exception) {
                    result.error("ERROR", e.message, null)
                }
            }
            "updateInfoWindow" -> {
                try {
                    val markerId = call.argument<String>("markerId")
                    val infoText = call.argument<String>("infoText")
                    if (markerId != null && infoText != null) {
                        markers[markerId]?.let { marker ->
                            val updateInfoWindowMethod = marker.javaClass.getMethod(
                                "updateInfoWindow",
                                String::class.java
                            )
                            updateInfoWindowMethod.invoke(marker, infoText)
                            result.success(true)
                        } ?: result.error("NOT_FOUND", "Marker not found", null)
                    } else {
                        result.error("INVALID_ARGUMENT", "Marker ID and info text are required", null)
                    }
                } catch (e: Exception) {
                    result.error("ERROR", e.message, null)
                }
            }
            "clearMarkers" -> {
                try {
                    // First try to remove each marker individually
                    markers.forEach { (_, marker) ->
                        try {
                            val removeMethod = marker.javaClass.getMethod("removeMarker")
                            removeMethod.invoke(marker)
                        } catch (e: Exception) {
                            android.util.Log.e("OlaMapView", "Error removing marker: ${e.message}")
                        }
                    }
                    markers.clear()
                    
                    // Also try to call removeAllMarkers if available
                    olaMap?.let { map ->
                        try {
                            val method = map.javaClass.getMethod("removeAllMarkers")
                            method.invoke(map)
                        } catch (e: Exception) {
                            // Method might not exist, that's ok
                        }
                    }
                    
                    result.success(true)
                } catch (e: Exception) {
                    android.util.Log.e("OlaMapView", "Error clearing markers: ${e.message}")
                    result.success(true) // Don't fail the operation
                }
            }
            "animateCamera" -> {
                try {
                    val target = call.argument<Map<String, Double>>("target")
                    val zoom = call.argument<Double>("zoom") ?: 12.0
                    
                    if (target != null) {
                        val lat = target["latitude"] ?: 0.0
                        val lng = target["longitude"] ?: 0.0
                        
                        olaMap?.let { map ->
                            // Create OlaLatLng using helper method
                            val latLng = createOlaLatLng(lat, lng)
                            val latLngClass = Class.forName("com.ola.mapsdk.model.OlaLatLng")
                            
                            // Call zoomToLocation
                            val zoomMethod = map.javaClass.getMethod(
                                "zoomToLocation",
                                latLngClass,
                                Double::class.java
                            )
                            zoomMethod.invoke(map, latLng, zoom)
                            result.success(true)
                        } ?: result.error("MAP_NOT_READY", "Map is not ready", null)
                    } else {
                        result.error("INVALID_ARGUMENT", "Target is required", null)
                    }
                } catch (e: Exception) {
                    result.error("ERROR", e.message, null)
                }
            }
            "moveCamera" -> {
                // Same as animateCamera for now
                onMethodCall(call.apply { "animateCamera" }, result)
            }
            "setMyLocationEnabled" -> {
                try {
                    val enabled = call.argument<Boolean>("enabled") ?: false
                    olaMap?.let { map ->
                        if (enabled) {
                            val method = map.javaClass.getMethod("showCurrentLocation")
                            method.invoke(map)
                        }
                        result.success(true)
                    } ?: result.error("MAP_NOT_READY", "Map is not ready", null)
                } catch (e: Exception) {
                    result.success(true) // Fail silently
                }
            }
            "getCameraPosition" -> {
                val position = mapOf(
                    "target" to mapOf("latitude" to 12.9716, "longitude" to 77.5946),
                    "zoom" to 12.0,
                    "tilt" to 0.0,
                    "bearing" to 0.0
                )
                result.success(position)
            }
            
            "addPolyline" -> {
                try {
                    val points = call.argument<List<Map<String, Double>>>("points")
                    val colorValue = call.argument<Any>("color")
                    val color = when (colorValue) {
                        is String -> colorValue
                        is Long -> String.format("#%08X", colorValue)
                        is Int -> String.format("#%08X", colorValue.toLong())
                        else -> "#0000FF"
                    }
                    val width = call.argument<Double>("width")?.toFloat() ?: 5.0f
                    val lineType = call.argument<String>("lineType")
                    val polylineId = call.argument<String>("polylineId") ?: "polyline_${System.currentTimeMillis()}"
                    
                    if (points != null && points.isNotEmpty()) {
                        olaMap?.let { map ->
                            // Convert points to OlaLatLng list
                            val olaPoints = ArrayList<Any>()
                            for (point in points) {
                                val lat = point["latitude"] ?: 0.0
                                val lng = point["longitude"] ?: 0.0
                                olaPoints.add(createOlaLatLng(lat, lng))
                            }
                            
                            // Create OlaPolylineOptions using Builder
                            val polylineOptionsClass = Class.forName("com.ola.mapsdk.model.OlaPolylineOptions")
                            val builderClass = Class.forName("com.ola.mapsdk.model.OlaPolylineOptions\$Builder")
                            
                            val builderConstructor = builderClass.getDeclaredConstructor()
                            val builder = builderConstructor.newInstance()
                            
                            // Set polyline ID
                            val setPolylineIdMethod = builderClass.getMethod("setPolylineId", String::class.java)
                            setPolylineIdMethod.invoke(builder, polylineId)
                            
                            // Set points
                            val setPointsMethod = builderClass.getMethod("setPoints", ArrayList::class.java)
                            setPointsMethod.invoke(builder, olaPoints)
                            
                            // Set color
                            val setColorMethod = builderClass.getMethod("setColor", String::class.java)
                            setColorMethod.invoke(builder, color)
                            
                            // Set width
                            val setWidthMethod = builderClass.getMethod("setWidth", Float::class.java)
                            setWidthMethod.invoke(builder, width)
                            
                            // Set line type if provided
                            if (lineType != null) {
                                val setLineTypeMethod = builderClass.getMethod("setLineType", String::class.java)
                                setLineTypeMethod.invoke(builder, lineType)
                            }
                            
                            // Build
                            val buildMethod = builderClass.getMethod("build")
                            val polylineOptions = buildMethod.invoke(builder)
                            
                            // Add polyline to map
                            val addPolylineMethod = map.javaClass.getMethod("addPolyline", polylineOptionsClass)
                            val polyline = addPolylineMethod.invoke(map, polylineOptions)
                            
                            polylines[polylineId] = polyline!!
                            result.success(polylineId)
                        } ?: result.error("MAP_NOT_READY", "Map is not ready", null)
                    } else {
                        result.error("INVALID_ARGUMENT", "Points are required", null)
                    }
                } catch (e: Exception) {
                    android.util.Log.e("OlaMapView", "Error adding polyline", e)
                    result.error("ERROR", e.message, null)
                }
            }
            "removePolyline" -> {
                try {
                    val polylineId = call.argument<String>("polylineId")
                    if (polylineId != null) {
                        polylines[polylineId]?.let { polyline ->
                            val removeMethod = polyline.javaClass.getMethod("removePolyline")
                            removeMethod.invoke(polyline)
                            polylines.remove(polylineId)
                            result.success(true)
                        } ?: result.error("NOT_FOUND", "Polyline not found", null)
                    } else {
                        result.error("INVALID_ARGUMENT", "Polyline ID is required", null)
                    }
                } catch (e: Exception) {
                    result.error("ERROR", e.message, null)
                }
            }
            "updatePolyline" -> {
                try {
                    val polylineId = call.argument<String>("polylineId")
                    val points = call.argument<List<Map<String, Double>>>("points")
                    
                    if (polylineId != null) {
                        polylines[polylineId]?.let { polyline ->
                            if (points != null && points.isNotEmpty()) {
                                // Convert points to OlaLatLng list
                                val olaPoints = ArrayList<Any>()
                                for (point in points) {
                                    val lat = point["latitude"] ?: 0.0
                                    val lng = point["longitude"] ?: 0.0
                                    olaPoints.add(createOlaLatLng(lat, lng))
                                }
                                
                                // Update points
                                val setPointsMethod = polyline.javaClass.getMethod("setPoints", ArrayList::class.java)
                                setPointsMethod.invoke(polyline, olaPoints)
                                result.success(true)
                            } else {
                                result.error("INVALID_ARGUMENT", "Points are required", null)
                            }
                        } ?: result.error("NOT_FOUND", "Polyline not found", null)
                    } else {
                        result.error("INVALID_ARGUMENT", "Polyline ID is required", null)
                    }
                } catch (e: Exception) {
                    result.error("ERROR", e.message, null)
                }
            }
            "clearPolylines" -> {
                try {
                    polylines.forEach { (_, polyline) ->
                        val removeMethod = polyline.javaClass.getMethod("removePolyline")
                        removeMethod.invoke(polyline)
                    }
                    polylines.clear()
                    result.success(true)
                } catch (e: Exception) {
                    result.error("ERROR", e.message, null)
                }
            }
            "addPolygon" -> {
                try {
                    val points = call.argument<List<Map<String, Double>>>("points")
                    val fillColorValue = call.argument<Any>("fillColor")
                    val fillColor = when (fillColorValue) {
                        is String -> fillColorValue
                        is Long -> String.format("#%08X", fillColorValue)
                        is Int -> String.format("#%08X", fillColorValue.toLong())
                        else -> "#FF0000"
                    }
                    val strokeColorValue = call.argument<Any>("strokeColor")
                    val strokeColor = when (strokeColorValue) {
                        is String -> strokeColorValue
                        is Long -> String.format("#%08X", strokeColorValue)
                        is Int -> String.format("#%08X", strokeColorValue.toLong())
                        else -> "#000000"
                    }
                    val strokeWidth = call.argument<Double>("strokeWidth")?.toFloat() ?: 2.0f
                    val polygonId = call.argument<String>("polygonId") ?: "polygon_${System.currentTimeMillis()}"
                    
                    if (points != null && points.isNotEmpty()) {
                        olaMap?.let { map ->
                            // Convert points to OlaLatLng list
                            val olaPoints = ArrayList<Any>()
                            for (point in points) {
                                val lat = point["latitude"] ?: 0.0
                                val lng = point["longitude"] ?: 0.0
                                olaPoints.add(createOlaLatLng(lat, lng))
                            }
                            
                            // Create OlaPolygonOptions using Builder
                            val polygonOptionsClass = Class.forName("com.ola.mapsdk.model.OlaPolygonOptions")
                            val builderClass = Class.forName("com.ola.mapsdk.model.OlaPolygonOptions\$Builder")
                            
                            val builderConstructor = builderClass.getDeclaredConstructor()
                            val builder = builderConstructor.newInstance()
                            
                            // Set polygon ID
                            val setPolygonIdMethod = builderClass.getMethod("setPolygonId", String::class.java)
                            setPolygonIdMethod.invoke(builder, polygonId)
                            
                            // Set points
                            val setPointsMethod = builderClass.getMethod("setPoints", ArrayList::class.java)
                            setPointsMethod.invoke(builder, olaPoints)
                            
                            // Set color
                            val setColorMethod = builderClass.getMethod("setColor", String::class.java)
                            setColorMethod.invoke(builder, fillColor)
                            
                            // Build
                            val buildMethod = builderClass.getMethod("build")
                            val polygonOptions = buildMethod.invoke(builder)
                            
                            // Add polygon to map
                            val addPolygonMethod = map.javaClass.getMethod("addPolygon", polygonOptionsClass)
                            val polygon = addPolygonMethod.invoke(map, polygonOptions)
                            
                            polygons[polygonId] = polygon!!
                            result.success(polygonId)
                        } ?: result.error("MAP_NOT_READY", "Map is not ready", null)
                    } else {
                        result.error("INVALID_ARGUMENT", "Points are required", null)
                    }
                } catch (e: Exception) {
                    android.util.Log.e("OlaMapView", "Error adding polygon", e)
                    result.error("ERROR", e.message, null)
                }
            }
            "removePolygon" -> {
                try {
                    val polygonId = call.argument<String>("polygonId")
                    if (polygonId != null) {
                        polygons[polygonId]?.let { polygon ->
                            val removeMethod = polygon.javaClass.getMethod("removePolygon")
                            removeMethod.invoke(polygon)
                            polygons.remove(polygonId)
                            result.success(true)
                        } ?: result.error("NOT_FOUND", "Polygon not found", null)
                    } else {
                        result.error("INVALID_ARGUMENT", "Polygon ID is required", null)
                    }
                } catch (e: Exception) {
                    result.error("ERROR", e.message, null)
                }
            }
            "clearPolygons" -> {
                try {
                    polygons.forEach { (_, polygon) ->
                        val removeMethod = polygon.javaClass.getMethod("removePolygon")
                        removeMethod.invoke(polygon)
                    }
                    polygons.clear()
                    result.success(true)
                } catch (e: Exception) {
                    result.error("ERROR", e.message, null)
                }
            }
            "addCircle" -> {
                try {
                    val center = call.argument<Map<String, Double>>("center")
                    val radius = call.argument<Double>("radius")?.toFloat() ?: 100.0f
                    val fillColor = call.argument<String>("fillColor") ?: "#FF0000"
                    val strokeColor = call.argument<String>("strokeColor") ?: "#000000"
                    val strokeWidth = call.argument<Double>("strokeWidth")?.toFloat() ?: 2.0f
                    val circleId = call.argument<String>("circleId") ?: "circle_${System.currentTimeMillis()}"
                    
                    if (center != null) {
                        val lat = center["latitude"] ?: 0.0
                        val lng = center["longitude"] ?: 0.0
                        
                        olaMap?.let { map ->
                            val centerLatLng = createOlaLatLng(lat, lng)
                            
                            // Create OlaCircleOptions using Builder
                            val circleOptionsClass = Class.forName("com.ola.mapsdk.model.OlaCircleOptions")
                            val builderClass = Class.forName("com.ola.mapsdk.model.OlaCircleOptions\$Builder")
                            
                            val builderConstructor = builderClass.getDeclaredConstructor()
                            val builder = builderConstructor.newInstance()
                            
                            // Set center
                            val latLngClass = Class.forName("com.ola.mapsdk.model.OlaLatLng")
                            val setCenterMethod = builderClass.getMethod("setOlaLatLng", latLngClass)
                            setCenterMethod.invoke(builder, centerLatLng)
                            
                            // Set radius
                            val setRadiusMethod = builderClass.getMethod("setRadius", Float::class.java)
                            setRadiusMethod.invoke(builder, radius)
                            
                            // Set color
                            val setColorMethod = builderClass.getMethod("setColor", String::class.java)
                            setColorMethod.invoke(builder, fillColor)
                            
                            // Build
                            val buildMethod = builderClass.getMethod("build")
                            val circleOptions = buildMethod.invoke(builder)
                            
                            // Add circle to map
                            val addCircleMethod = map.javaClass.getMethod("addCircle", circleOptionsClass)
                            val circle = addCircleMethod.invoke(map, circleOptions)
                            
                            circles[circleId] = circle!!
                            result.success(circleId)
                        } ?: result.error("MAP_NOT_READY", "Map is not ready", null)
                    } else {
                        result.error("INVALID_ARGUMENT", "Center is required", null)
                    }
                } catch (e: Exception) {
                    android.util.Log.e("OlaMapView", "Error adding circle", e)
                    result.error("ERROR", e.message, null)
                }
            }
            "removeCircle" -> {
                try {
                    val circleId = call.argument<String>("circleId")
                    if (circleId != null) {
                        circles[circleId]?.let { circle ->
                            val removeMethod = circle.javaClass.getMethod("removeCircle")
                            removeMethod.invoke(circle)
                            circles.remove(circleId)
                            result.success(true)
                        } ?: result.error("NOT_FOUND", "Circle not found", null)
                    } else {
                        result.error("INVALID_ARGUMENT", "Circle ID is required", null)
                    }
                } catch (e: Exception) {
                    result.error("ERROR", e.message, null)
                }
            }
            "clearCircles" -> {
                try {
                    circles.forEach { (_, circle) ->
                        val removeMethod = circle.javaClass.getMethod("removeCircle")
                        removeMethod.invoke(circle)
                    }
                    circles.clear()
                    result.success(true)
                } catch (e: Exception) {
                    result.error("ERROR", e.message, null)
                }
            }
            else -> result.notImplemented()
        }
    }

    override fun getView(): View = container

    override fun dispose() {
        try {
            // Try to call onDestroy if available
            mapView?.let {
                val onDestroyMethod = it.javaClass.getMethod("onDestroy")
                onDestroyMethod.invoke(it)
            }
        } catch (e: Exception) {
            // Ignore
        }
        methodChannel.setMethodCallHandler(null)
    }
}