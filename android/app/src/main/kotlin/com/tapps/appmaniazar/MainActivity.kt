package com.tapps.appmaniazar

import io.flutter.embedding.android.FlutterActivity
import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.view.View
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat

class MainActivity: FlutterActivity() {
    private val locationPermissionCode = 1001
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Enable edge-to-edge display for all API levels
        WindowCompat.setDecorFitsSystemWindows(window, false)
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            // For Android 11 (API 30) and above, use WindowInsetsController
            val windowInsetsController = WindowCompat.getInsetsController(window, window.decorView)
            windowInsetsController.systemBarsBehavior =
                WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
            
            // Set light status bar icons
            windowInsetsController.isAppearanceLightStatusBars = true
            windowInsetsController.isAppearanceLightNavigationBars = true
            
            // Set transparent system bars
            window.statusBarColor = android.graphics.Color.TRANSPARENT
            window.navigationBarColor = android.graphics.Color.TRANSPARENT
            
            // For Android 12L and above, set the navigation bar divider color
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                window.navigationBarDividerColor = android.graphics.Color.TRANSPARENT
            }
        } else {
            // For older versions, use the older approach with appropriate flags
            @Suppress("DEPRECATION")
            window.decorView.systemUiVisibility = (
                View.SYSTEM_UI_FLAG_LAYOUT_STABLE or
                View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION or
                View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN or
                View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR
            )
            
            @Suppress("DEPRECATION")
            window.statusBarColor = android.graphics.Color.TRANSPARENT
            
            @Suppress("DEPRECATION")
            window.navigationBarColor = android.graphics.Color.TRANSPARENT
        }
        
        requestLocationPermission()
    }
    
    private fun requestLocationPermission() {
        if (ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.ACCESS_FINE_LOCATION
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            ActivityCompat.requestPermissions(
                this,
                arrayOf(Manifest.permission.ACCESS_FINE_LOCATION),
                locationPermissionCode
            )
        }
    }
}

