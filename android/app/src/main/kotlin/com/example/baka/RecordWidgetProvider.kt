package com.example.baka

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.SizeF
import android.widget.RemoteViews

/**
 * Home-screen widget: a single "Record thought" button. Tapping it launches
 * the invisible [RecordLauncherActivity], which starts/stops recording without
 * opening the full Flutter app.
 *
 * Provides two responsive layouts (API 31+): a square layout for 2x2+ and a
 * compact horizontal layout for short sizes (2x1, 4x1). Older versions get the
 * square layout at any size.
 */
class RecordWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        for (id in appWidgetIds) {
            appWidgetManager.updateAppWidget(id, buildViews(context))
        }
    }

    private fun launchIntent(context: Context): PendingIntent {
        val intent = Intent(context, RecordLauncherActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        return PendingIntent.getActivity(
            context, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun views(context: Context, layout: Int): RemoteViews =
        RemoteViews(context.packageName, layout).apply {
            setOnClickPendingIntent(R.id.widget_root, launchIntent(context))
        }

    private fun buildViews(context: Context): RemoteViews {
        val square = views(context, R.layout.widget_record)
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return square

        val compact = views(context, R.layout.widget_record_compact)
        val mapping = mapOf(
            SizeF(110f, 40f) to compact,
            SizeF(120f, 100f) to square,
        )
        return RemoteViews(mapping)
    }
}
