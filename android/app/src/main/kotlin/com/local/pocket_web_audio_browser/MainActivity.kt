package com.local.pocket_web_audio_browser

import android.Manifest
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), NOTIFICATION_REQUEST_CODE)
        }

        PlaybackKeeperService.start(this)
    }

    override fun onDestroy() {
        if (isFinishing) {
            PlaybackKeeperService.stop(this)
        }
        super.onDestroy()
    }

    private companion object {
        const val NOTIFICATION_REQUEST_CODE = 1001
    }
}
