package io.github.abdelrahmanhamza1.fitnessbuddy

import android.app.Activity
import android.content.Context
import android.os.Build
import com.it_nomads.fluttersecurestorage.FlutterSecureStoragePlugin
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.security.KeyStore
import org.json.JSONObject

/** Destructive synthetic-fixture hooks: debug source set AND dev package only. */
object SessionTestHooks {
    private const val NAMESPACE = "fb.session.secure.v1"
    private const val PREFIX = "VGhpcyBpcyB0aGUgcHJlZml4IGZvciBhIHNlY3VyZSBzdG9yYWdlCg_"

    fun attach(activity: Activity, engine: FlutterEngine) {
        if (activity.packageName != "io.github.abdelrahmanhamza1.fitnessbuddy.dev") return
        val emulator = Build.HARDWARE in setOf("goldfish", "ranchu") ||
            Build.FINGERPRINT.startsWith("generic/") ||
            Build.FINGERPRINT.startsWith("generic_x86/") ||
            Build.FINGERPRINT.contains("/emulator/")
        val context = activity.applicationContext
        val prefs = context.getSharedPreferences(NAMESPACE, Context.MODE_PRIVATE)
        val snapshot = File(context.filesDir, "a20-raw-snapshot")
        // Compare entries independently across all three durability stores. JSON
        // preserves multiline ciphertext without exposing keys or values to Dart.
        val stores = listOf(NAMESPACE, "FlutterSecureKeyStorage:$NAMESPACE",
            "FlutterSecureStorageConfiguration:$NAMESPACE")
        fun raw(): JSONObject = JSONObject().apply {
            stores.forEach { name ->
                put(name, JSONObject(context.getSharedPreferences(name, Context.MODE_PRIVATE).all))
            }
        }
        // The plugin stores Base64.DEFAULT text (line-wrapped). The prefs XML
        // round trip may change only that wrapping, so ciphertext is compared
        // by stored Base64 content identity, line breaks ignored. Anything else
        // (another IV, another wrap, any non-Base64 value) is still a change.
        val base64 = Regex("[A-Za-z0-9+/=\\s]+")
        fun sameValue(a: Any?, b: Any?): Boolean {
            if (a == b) return true
            if (a !is String || b !is String) return false
            if (!base64.matches(a) || !base64.matches(b)) return false
            return a.filterNot { it.isWhitespace() } == b.filterNot { it.isWhitespace() }
        }
        fun changes(): List<String> {
            check(snapshot.exists())
            val before = JSONObject(snapshot.readText())
            val after = raw()
            val changes = linkedSetOf<String>()
            stores.forEachIndexed { index, name ->
                val old = before.getJSONObject(name)
                val current = after.getJSONObject(name)
                val keys = (old.keys().asSequence().toSet() + current.keys().asSequence().toSet()).sorted()
                keys.forEach { key ->
                    if (old.opt(key) != current.opt(key) && sameValue(old.opt(key), current.opt(key))) {
                        changes.add("base64_wrapping_only")
                    }
                    if (old.has(key) != current.has(key) || !sameValue(old.opt(key), current.opt(key))) {
                        changes.add(when {
                            key == SessionStorageCommitter.BARRIER_KEY -> "barrier_counter"
                            index == 0 && key.startsWith(PREFIX + "fb.session.v1.") ->
                                if (current.has(key)) "envelope_value" else "envelope_removed"
                            index == 0 && key.startsWith(PREFIX + "fb.session.active.v1.") ->
                                if (current.has(key)) "pointer_value" else "pointer_removed"
                            // Recovery intent carries account kind; active pointer also contains kind.
                            index == 0 && key.startsWith(PREFIX + "fb.session.intent.v1.") -> "kind_marker"
                            index == 1 -> "plugin_internal_1"
                            !old.has(key) -> "extra_key_added"
                            else -> "plugin_internal_$index"
                        })
                    }
                }
            }
            return changes.toList()
        }
        MethodChannel(engine.dartExecutor.binaryMessenger, "fitness_buddy/session_test")
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "arguments" -> result.success(mapOf(
                            "phase" to activity.intent.getStringExtra("phase"),
                            "iteration" to activity.intent.getStringExtra("iteration")
                        ))
                        "claimWritePhase" -> {
                            val phase = requireNotNull(call.argument<String>("phase"))
                            val iteration = requireNotNull(call.argument<String>("iteration"))
                            check(phase in listOf("pending", "pair", "ciphertext", "key"))
                            check(Regex("[0-9]+").matches(iteration))
                            // SIGKILL can recreate the Activity with its old intent before
                            // adb gets to force-stop. Never replay a fixture's secure writes.
                            val claim = File(context.filesDir, "a20-write-$phase-$iteration")
                            val progress = File(context.filesDir, "a20-progress")
                            if (claim.exists()) {
                                progress.writeText("$phase-$iteration:CLAIM_SKIPPED")
                                result.success(false)
                            } else {
                                FileOutputStream(claim).use {
                                    it.write(1)
                                    it.fd.sync()
                                }
                                progress.writeText("$phase-$iteration:CLAIMED")
                                result.success(true)
                            }
                        }
                        "fault" -> {
                            check(emulator)
                            when (call.argument<String>("mode")) {
                                "ciphertext" -> {
                                    val key = PREFIX + requireNotNull(call.argument<String>("key"))
                                    check(key.startsWith(PREFIX + "fb.session.v1."))
                                    check(prefs.contains(key))
                                    check(prefs.edit().putString(key, "invalid-ciphertext").commit())
                                }
                                "key" -> {
                                    val ks = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
                                    val alias = context.packageName +
                                        ".FlutterSecureStoragePluginKeyOAEP." + NAMESPACE
                                    check(ks.containsAlias(alias))
                                    ks.deleteEntry(alias)
                                    // AndroidKeyStore deletion is a synchronous service operation,
                                    // not a SharedPreferences/in-process cache mutation. Reopen
                                    // the provider to verify completion before acknowledging.
                                    val reopened = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
                                    check(!reopened.containsAlias(alias))
                                }
                                else -> error("unknown_fault")
                            }
                            // Simulate a fresh native plugin too: the old instance caches the AES key.
                            engine.plugins.remove(FlutterSecureStoragePlugin::class.java)
                            engine.plugins.add(FlutterSecureStoragePlugin())
                            // The restart assertion also depends on this file surviving SIGKILL.
                            val baseline = raw()
                            val data = baseline.getJSONObject(NAMESPACE)
                            check(data.keys().asSequence().any { it.startsWith(PREFIX + "fb.session.v1.") })
                            check(data.keys().asSequence().any { it.startsWith(PREFIX + "fb.session.active.v1.") })
                            FileOutputStream(snapshot).use {
                                it.write(baseline.toString().toByteArray())
                                it.fd.sync()
                            }
                            result.success(true)
                        }
                        "retentionChanges" -> result.success(changes())
                        "retained" -> result.success(changes().all { it == "barrier_counter" || it == "base64_wrapping_only" })
                        "barrier" -> {
                            check(emulator)
                            val mode = call.arguments as String
                            check(mode == "false" || mode == "lost")
                            MethodChannel(engine.dartExecutor.binaryMessenger, "fitness_buddy/session_storage")
                                .setMethodCallHandler { _, reply ->
                                    if (mode == "false") reply.success(false)
                                    // lost deliberately withholds acknowledgement until Dart times out.
                                }
                            result.success(true)
                        }
                        "signal" -> {
                            val signal = call.arguments as String
                            check(Regex("[a-z0-9-]+:(ACKED|PASS|FAIL:[a-zA-Z0-9_]+)(:NOTICE:base64_wrapping_only)*").matches(signal))
                            val notices = signal.split(":NOTICE:").drop(1)
                            check(notices.size == notices.toSet().size)
                            val temporary = File(context.filesDir, "a20-status-tmp")
                            FileOutputStream(temporary).use {
                                it.write(signal.toByteArray())
                                it.fd.sync()
                            }
                            check(temporary.renameTo(File(context.filesDir, "a20-status")))
                            result.success(true)
                        }
                        else -> result.notImplemented()
                    }
                } catch (_: Exception) {
                    result.error("probe_failed", null, null)
                }
            }
    }
}
