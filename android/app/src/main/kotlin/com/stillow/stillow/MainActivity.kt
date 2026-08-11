package com.stillow.stillow

import android.content.Intent
import com.ryanheise.audioservice.AudioServiceFragmentActivity

class MainActivity : AudioServiceFragmentActivity() {
    override fun getInitialRoute(): String? =
        if (isPrivacyIntent(intent)) "/privacy" else super.getInitialRoute()

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        if (isPrivacyIntent(intent)) {
            flutterEngine?.navigationChannel?.pushRoute("/privacy")
        }
    }

    private fun isPrivacyIntent(intent: Intent?): Boolean =
        intent?.action == "androidx.health.ACTION_SHOW_PERMISSIONS_RATIONALE" ||
            intent?.action == "android.intent.action.VIEW_PERMISSION_USAGE"
}
