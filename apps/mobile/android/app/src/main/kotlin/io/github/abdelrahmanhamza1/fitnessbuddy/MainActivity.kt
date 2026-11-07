package io.github.abdelrahmanhamza1.fitnessbuddy

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var sessionStorageDurability: SessionStorageDurability? = null
    private var homeWidgets: HomeWidgetChannel? = null

    /** A71: the widget tap this activity was started with, if any (not on a restore). */
    private var launchAction: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        // Read before super, which configures the engine (and the channel) synchronously.
        // A restored activity or one reopened from Recents doesn't replay an old tap.
        val fromHistory =
            ((intent?.flags ?: 0) and Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY) != 0
        if (savedInstanceState == null && !fromHistory) {
            launchAction = HomeWidgets.actionOf(intent)
        }
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        sessionStorageDurability = SessionStorageDurability(
            applicationContext, flutterEngine.dartExecutor.binaryMessenger
        )
        homeWidgets = HomeWidgetChannel(
            applicationContext, flutterEngine.dartExecutor.binaryMessenger
        ).also { channel -> launchAction?.let { channel.opened(it, announce = false) } }
        launchAction = null
        SessionTestHooks.attach(this, flutterEngine)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // A71 D7: a widget tap while the app runs; any other intent is ignored here.
        HomeWidgets.actionOf(intent)?.let { homeWidgets?.opened(it, announce = true) }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        homeWidgets?.close()
        homeWidgets = null
        sessionStorageDurability?.close()
        sessionStorageDurability = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
