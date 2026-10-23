package io.github.abdelrahmanhamza1.fitnessbuddy

import android.content.Context
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

/** PA2: no caller-controlled store/key paths and no credential channel arguments. */
class SessionStorageDurability(context: Context, messenger: BinaryMessenger) {
    private val appContext = context.applicationContext
    private val worker = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())
    private val channel = MethodChannel(messenger, "fitness_buddy/session_storage")

    init {
        channel.setMethodCallHandler { call, result ->
            if (call.method != "commit") {
                result.notImplemented()
            } else if (call.arguments != null) {
                result.error("invalid_arguments", null, null)
            } else {
                worker.execute {
                    val committed = try {
                        SessionStorageCommitter.commit { name ->
                            val prefs = appContext.getSharedPreferences(name, Context.MODE_PRIVATE)
                            val key = SessionStorageCommitter.BARRIER_KEY
                            // A changed nonsecret value forces a disk commit. Outside plugin prefix.
                            val next = prefs.getLong(key, 0L) + 1L
                            prefs.edit().putLong(key, next).commit()
                        }
                    } catch (_: Exception) {
                        false
                    }
                    main.post { result.success(committed) }
                }
            }
        }
    }

    fun close() {
        channel.setMethodCallHandler(null)
        // Finish queued commits; a detached/lost acknowledgement remains unavailable in Dart.
        worker.shutdown()
    }
}
