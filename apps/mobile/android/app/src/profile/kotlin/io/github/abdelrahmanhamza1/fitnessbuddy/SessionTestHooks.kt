package io.github.abdelrahmanhamza1.fitnessbuddy

import android.app.Activity
import io.flutter.embedding.engine.FlutterEngine

/** No test channel, fault injector or probe in this build type. */
object SessionTestHooks {
    fun attach(@Suppress("UNUSED_PARAMETER") activity: Activity,
               @Suppress("UNUSED_PARAMETER") engine: FlutterEngine) = Unit
}
