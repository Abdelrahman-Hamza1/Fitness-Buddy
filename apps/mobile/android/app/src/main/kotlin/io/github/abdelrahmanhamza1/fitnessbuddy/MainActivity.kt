package io.github.abdelrahmanhamza1.fitnessbuddy

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var sessionStorageDurability: SessionStorageDurability? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        sessionStorageDurability = SessionStorageDurability(
            applicationContext, flutterEngine.dartExecutor.binaryMessenger
        )
        SessionTestHooks.attach(this, flutterEngine)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        sessionStorageDurability?.close()
        sessionStorageDurability = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
