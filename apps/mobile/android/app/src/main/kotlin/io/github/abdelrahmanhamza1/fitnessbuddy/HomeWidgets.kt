package io.github.abdelrahmanhamza1.fitnessbuddy

import android.app.ActivityOptions
import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import android.view.View
import android.widget.RemoteViews
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.time.LocalDate
import java.time.ZoneId

/**
 * The home-screen widgets (A71, UX-082 to UX-085).
 *
 * The app writes a snapshot of formatted numbers through [HomeWidgetChannel] into the private
 * preferences file [PREFS] (excluded from backup: backup_rules and data_extraction_rules); the
 * widgets only render it and never open the database. A tap only opens the app (UX-083): an
 * explicit, immutable PendingIntent to [MainActivity] with one of the fixed [ACTIONS]; no intent
 * filter, no deep link. Nothing is logged.
 */
object HomeWidgets {
    /** The snapshot's preferences file. */
    const val PREFS = "fb_home_widget"

    /** The snapshot format this code reads (WidgetSnapshot.version in Dart). */
    private const val VERSION = 1

    /** The prefix of the tap actions; the suffix is one of [ACTIONS], upper case. */
    private const val ACTION_PREFIX = "io.github.abdelrahmanhamza1.fitnessbuddy.widget."

    /** The midnight redraw (an explicit broadcast to [TodayWidgetClock], not exported). */
    const val ACTION_MIDNIGHT = ACTION_PREFIX + "MIDNIGHT"

    /** The tap allow-list (HomeWidgetAction in Dart). */
    val ACTIONS = listOf("today", "ask", "speak", "weigh")

    private val MACROS = listOf("protein", "carbs", "fat", "fiber")

    private const val MAX_KEYS = 200
    private const val MAX_TEXT = 64

    private fun prefs(context: Context): SharedPreferences =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    /** Replaces the snapshot with [data]; only short strings, ints and bools are kept. */
    fun save(context: Context, data: Map<*, *>) {
        val edit = prefs(context).edit().clear()
        for ((key, value) in data.entries.take(MAX_KEYS)) {
            if (key !is String || key.length > MAX_TEXT) continue
            when (value) {
                is String -> edit.putString(key, value.take(MAX_TEXT))
                is Int -> edit.putInt(key, value)
                is Long -> edit.putInt(key, value.coerceIn(0L, Int.MAX_VALUE.toLong()).toInt())
                is Boolean -> edit.putBoolean(key, value)
            }
        }
        edit.apply()
        updateAll(context)
    }

    /** Removes the snapshot. */
    fun clear(context: Context) {
        prefs(context).edit().clear().apply()
        updateAll(context)
    }

    /**
     * Removes the snapshot and waits until the file is written (`commit`): the account
     * transitions call it before the profile changes, so a crash right after can't bring the old
     * numbers back. Whether it was written.
     */
    fun clearDurably(context: Context): Boolean {
        val committed = prefs(context).edit().clear().commit()
        updateAll(context)
        return committed
    }

    /** Removes the snapshot while it is [profileTag]'s. */
    fun clearFor(context: Context, profileTag: String) {
        if (prefs(context).getString("profile", null) == profileTag) clear(context)
    }

    /** The allow-listed action [intent] carries, or null. */
    fun actionOf(intent: Intent?): String? {
        val action = intent?.action ?: return null
        if (!action.startsWith(ACTION_PREFIX)) return null
        val name = action.removePrefix(ACTION_PREFIX).lowercase()
        return name.takeIf { it in ACTIONS }
    }

    /** Redraws every placed widget of the three kinds. */
    fun updateAll(context: Context) {
        val manager = AppWidgetManager.getInstance(context)
        for (kind in Kind.entries) {
            val ids = manager.getAppWidgetIds(ComponentName(context, kind.provider))
            if (ids.isNotEmpty()) update(context, manager, ids, kind)
        }
    }

    /** Draws [ids] of [kind] from the snapshot, then arms the midnight redraw. */
    fun update(context: Context, manager: AppWidgetManager, ids: IntArray, kind: Kind) {
        val views = render(context, kind, Snapshot.read(prefs(context)))
        manager.updateAppWidget(ids, views)
        armMidnight(context)
    }

    private fun render(context: Context, kind: Kind, snapshot: Snapshot): RemoteViews {
        val views = RemoteViews(context.packageName, kind.layout)
        val today = open(context, "today")
        when (kind) {
            Kind.MEDIUM -> {
                views.setOnClickPendingIntent(R.id.widget_body, today)
                views.setOnClickPendingIntent(R.id.button_speak, open(context, "speak"))
                views.setOnClickPendingIntent(R.id.button_ask, open(context, "ask"))
                views.setOnClickPendingIntent(R.id.button_weigh, open(context, "weigh"))
                val day = snapshot.today
                if (day != null) {
                    showNumbers(views, day, MACROS)
                    views.setTextViewText(R.id.eaten_of, day.eatenOf)
                    views.setViewVisibility(R.id.eaten_of, visible(day.eatenOf.isNotEmpty()))
                } else {
                    // Hidden or a stale day: the prompt and the buttons; signed out: open the app.
                    showPlain(views, context.getString(
                        if (snapshot.signedOut) R.string.widget_open_app else R.string.widget_prompt,
                    ))
                }
                views.setViewVisibility(R.id.buttons, visible(!snapshot.signedOut))
            }
            Kind.NUMBERS -> {
                views.setOnClickPendingIntent(android.R.id.background, today)
                val day = snapshot.today
                if (day != null) {
                    showNumbers(views, day, listOf("protein"))
                } else {
                    showPlain(views, if (snapshot.signedOut) context.getString(R.string.widget_open_app) else null)
                }
            }
            Kind.BUTTONS -> {
                views.setOnClickPendingIntent(R.id.button_speak, open(context, "speak"))
                views.setOnClickPendingIntent(R.id.button_ask, open(context, "ask"))
            }
        }
        return views
    }

    private fun showNumbers(views: RemoteViews, day: Day, macros: List<String>) {
        views.setViewVisibility(R.id.numbers_block, View.VISIBLE)
        views.setViewVisibility(R.id.plain_block, View.GONE)
        views.setTextViewText(R.id.ring_value, day.kcal)
        views.setTextViewText(R.id.ring_caption, day.caption)
        views.setProgressBar(R.id.ring, 1000, day.ring, false)
        views.setViewVisibility(R.id.ring, visible(!day.over))
        views.setViewVisibility(R.id.ring_over, visible(day.over))
        for (name in macros) {
            val macro = day.macros.getValue(name)
            val ids = MacroIds.of(name)
            views.setTextViewText(ids.value, macro.text)
            views.setProgressBar(ids.bar, 1000, macro.bar, false)
            views.setViewVisibility(ids.bar, visible(!macro.over))
            views.setViewVisibility(ids.over, visible(macro.over))
        }
    }

    private fun showPlain(views: RemoteViews, text: String?) {
        views.setViewVisibility(R.id.numbers_block, View.GONE)
        views.setViewVisibility(R.id.plain_block, View.VISIBLE)
        views.setTextViewText(R.id.plain_text, text ?: "")
        views.setViewVisibility(R.id.plain_text, visible(text != null))
    }

    private fun visible(shown: Boolean) = if (shown) View.VISIBLE else View.GONE

    /** An explicit, immutable PendingIntent that opens the app with [name] (one per action). */
    private fun open(context: Context, name: String): PendingIntent {
        val intent = Intent(context, MainActivity::class.java)
            .setAction(ACTION_PREFIX + name.uppercase())
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        val code = ACTIONS.indexOf(name)
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            return PendingIntent.getActivity(context, code, intent, flags)
        }
        // Android 14+: the widget tap may bring the app to the front (the tap is the user's).
        val options = ActivityOptions.makeBasic()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.VANILLA_ICE_CREAM) {
            @Suppress("DEPRECATION")
            options.setPendingIntentCreatorBackgroundActivityStartMode(
                ActivityOptions.MODE_BACKGROUND_ACTIVITY_START_ALLOWED,
            )
        } else {
            @Suppress("DEPRECATION")
            options.pendingIntentBackgroundActivityStartMode =
                ActivityOptions.MODE_BACKGROUND_ACTIVITY_START_ALLOWED
        }
        return PendingIntent.getActivity(context, code, intent, flags, options.toBundle())
    }

    /**
     * One inexact, non-waking alarm a few seconds after the next local midnight (A71 D4): the
     * widgets then show the next day's block of the snapshot. Replaced on every redraw; no
     * exact-alarm permission (tools/scripts/apk_hardening_check.py).
     */
    private fun armMidnight(context: Context) {
        val alarms = context.getSystemService(AlarmManager::class.java) ?: return
        val zone = ZoneId.systemDefault()
        val at = LocalDate.now(zone).plusDays(1).atStartOfDay(zone).plusSeconds(5)
        val intent = Intent(context, TodayWidgetClock::class.java).setAction(ACTION_MIDNIGHT)
        val pending = PendingIntent.getBroadcast(
            context, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        alarms.set(AlarmManager.RTC, at.toInstant().toEpochMilli(), pending)
    }

    /** The three widgets. */
    enum class Kind(val layout: Int, val provider: Class<out AppWidgetProvider>) {
        MEDIUM(R.layout.widget_medium, TodayWidgetMedium::class.java),
        NUMBERS(R.layout.widget_numbers, TodayWidgetNumbers::class.java),
        BUTTONS(R.layout.widget_buttons, TodayWidgetButtons::class.java),
    }

    private data class MacroIds(val value: Int, val bar: Int, val over: Int) {
        companion object {
            fun of(name: String) = when (name) {
                "protein" -> MacroIds(R.id.protein_value, R.id.protein_bar, R.id.protein_over)
                "carbs" -> MacroIds(R.id.carbs_value, R.id.carbs_bar, R.id.carbs_over)
                "fat" -> MacroIds(R.id.fat_value, R.id.fat_bar, R.id.fat_over)
                else -> MacroIds(R.id.fiber_value, R.id.fiber_bar, R.id.fiber_over)
            }
        }
    }

    private data class Macro(val text: String, val bar: Int, val over: Boolean)

    private data class Day(
        val kcal: String,
        val caption: String,
        val ring: Int,
        val over: Boolean,
        val eatenOf: String,
        val macros: Map<String, Macro>,
    )

    /** What the snapshot says now: the phone's day's numbers, if shown and present. */
    private class Snapshot(val signedOut: Boolean, val today: Day?) {
        companion object {
            fun read(prefs: SharedPreferences): Snapshot {
                val shows = if (prefs.getInt("v", 0) == VERSION) prefs.getString("shows", null) else null
                // No snapshot (never written, cleared) reads as signed out: "Open Fitness Buddy".
                if (shows == null || shows == "signedOut") return Snapshot(true, null)
                if (shows != "numbers") return Snapshot(false, null)
                val date = LocalDate.now().toString()
                val days = prefs.getInt("days", 0).coerceIn(0, 2)
                val i = (0 until days).firstOrNull { prefs.getString("d$it.date", null) == date }
                    ?: return Snapshot(false, null)
                fun s(key: String) = prefs.getString("d$i.$key", "") ?: ""
                fun n(key: String) = prefs.getInt("d$i.$key", 0).coerceIn(0, 1000)
                fun b(key: String) = prefs.getBoolean("d$i.$key", false)
                return Snapshot(
                    false,
                    Day(
                        kcal = s("kcal"),
                        caption = s("caption"),
                        ring = n("ring"),
                        over = b("over"),
                        eatenOf = s("eatenOf"),
                        macros = MACROS.associateWith {
                            Macro(s("$it.text"), n("$it.bar"), b("$it.over"))
                        },
                    ),
                )
            }
        }
    }
}

/**
 * The base of the three widget receivers: draws from the snapshot. Exported because the launcher
 * sends APPWIDGET_UPDATE; AppWidgetProvider ignores every other action, so an outside app can at
 * most cause a redraw.
 */
abstract class TodayWidget(private val kind: HomeWidgets.Kind) : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        HomeWidgets.update(context, manager, ids, kind)
    }
}

/**
 * Not exported (A71 review): the midnight alarm (explicit, ours) and the system's time and time-zone
 * changes (implicit-broadcast exceptions, delivered by the system) redraw every widget for the
 * phone's day and re-arm the alarm. Nothing else is accepted.
 */
class TodayWidgetClock : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            HomeWidgets.ACTION_MIDNIGHT,
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_TIMEZONE_CHANGED -> HomeWidgets.updateAll(context)
        }
    }
}

/** The medium 4 x 2 widget. */
class TodayWidgetMedium : TodayWidget(HomeWidgets.Kind.MEDIUM)

/** The small 2 x 2 numbers widget. */
class TodayWidgetNumbers : TodayWidget(HomeWidgets.Kind.NUMBERS)

/** The small 2 x 1 buttons widget. */
class TodayWidgetButtons : TodayWidget(HomeWidgets.Kind.BUTTONS)

/**
 * The app side of the widgets: `fitness_buddy/home_widget` (home_widget_store.dart). The launch
 * action is taken once; a tap while the app runs is announced with `tapped`.
 */
class HomeWidgetChannel(private val context: Context, messenger: BinaryMessenger) :
    MethodChannel.MethodCallHandler {
    private val channel = MethodChannel(messenger, "fitness_buddy/home_widget")
    private var pending: String? = null

    init {
        channel.setMethodCallHandler(this)
    }

    /** The app was opened or brought back by a widget tap with the allow-listed [action]. */
    fun opened(action: String, announce: Boolean) {
        pending = action
        if (announce) channel.invokeMethod("tapped", null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "save" -> {
                val data = call.arguments as? Map<*, *>
                if (data == null) {
                    result.error("bad_arguments", null, null)
                    return
                }
                HomeWidgets.save(context, data)
                result.success(null)
            }
            "clear" -> {
                HomeWidgets.clear(context)
                result.success(null)
            }
            "clearDurably" -> result.success(HomeWidgets.clearDurably(context))
            "clearFor" -> {
                (call.arguments as? String)?.let { HomeWidgets.clearFor(context, it) }
                result.success(null)
            }
            "takeLaunchAction" -> {
                result.success(pending)
                pending = null
            }
            else -> result.notImplemented()
        }
    }

    fun close() {
        channel.setMethodCallHandler(null)
    }
}
