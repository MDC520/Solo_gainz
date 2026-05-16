package com.example.solo_gainz

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Defend app data: Blocks external apps from taking screenshots, recording screen,
        // or capturing RAM surfaces in the recent apps menu.
        // FLAG_SECURE is disabled in debug/emulator environments to prevent black screen issues
        // window.setFlags(
        //     WindowManager.LayoutParams.FLAG_SECURE,
        //     WindowManager.LayoutParams.FLAG_SECURE
        // )
    }
}
