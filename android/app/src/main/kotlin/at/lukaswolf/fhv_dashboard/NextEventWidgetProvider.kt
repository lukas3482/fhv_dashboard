package at.lukaswolf.fhv_dashboard

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.view.View
import android.widget.RemoteViews
import androidx.core.content.ContextCompat
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class NextEventWidgetProvider : HomeWidgetProvider() {

  override fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences,
  ) {
    appWidgetIds.forEach { widgetId ->
      val views =
          RemoteViews(context.packageName, R.layout.next_event_widget).apply {
            val pendingIntent =
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
            setOnClickPendingIntent(R.id.widget_root, pendingIntent)

            val hasEvent = widgetData.getBoolean("next_event_has_event", false)
            if (hasEvent) {
              setTextViewText(
                  R.id.widget_header,
                  widgetData.getString("next_event_header", null)
                      ?: context.getString(R.string.next_event_widget_default_header),
              )
              setTextViewText(
                  R.id.widget_title,
                  widgetData.getString("next_event_title", null) ?: "",
              )
              val time = widgetData.getString("next_event_time", null) ?: ""
              val room = widgetData.getString("next_event_room", null) ?: ""
              setTextViewText(
                  R.id.widget_meta,
                  if (room.isEmpty()) time else "$time · $room",
              )

              setInt(
                  R.id.widget_accent_bar,
                  "setBackgroundColor",
                  readColor(context, widgetData),
              )

              setViewVisibility(R.id.widget_title, View.VISIBLE)
              setViewVisibility(R.id.widget_meta, View.VISIBLE)
              setViewVisibility(R.id.widget_empty, View.GONE)
            } else {
              setTextViewText(
                  R.id.widget_header,
                  context.getString(R.string.next_event_widget_default_header),
              )
              setTextViewText(
                  R.id.widget_empty,
                  context.getString(R.string.next_event_widget_empty),
              )
              setInt(
                  R.id.widget_accent_bar,
                  "setBackgroundColor",
                  ContextCompat.getColor(context, R.color.widget_accent),
              )
              setViewVisibility(R.id.widget_title, View.GONE)
              setViewVisibility(R.id.widget_meta, View.GONE)
              setViewVisibility(R.id.widget_empty, View.VISIBLE)
            }
          }

      appWidgetManager.updateAppWidget(widgetId, views)
    }
  }

  private fun readColor(context: Context, widgetData: SharedPreferences): Int {
    val fallback = ContextCompat.getColor(context, R.color.widget_accent)
    return when (val raw = widgetData.all["next_event_color"]) {
      is Int -> raw
      is Long -> raw.toInt()
      else -> fallback
    }
  }
}
