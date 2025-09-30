package com.olakrutrim.ola_maps_flutter_example

import android.app.Application
import android.util.Log

class MainApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        
        // Initialize MapLibre using reflection
        Log.d("MainApplication", "Initializing MapLibre...")
        try {
            val mapLibreClass = Class.forName("org.maplibre.android.MapLibre")
            val getInstanceMethod = mapLibreClass.getMethod("getInstance", android.content.Context::class.java)
            getInstanceMethod.invoke(null, this)
            Log.d("MainApplication", "MapLibre initialized successfully")
        } catch (e: Exception) {
            Log.e("MainApplication", "Failed to initialize MapLibre", e)
        }
    }
}