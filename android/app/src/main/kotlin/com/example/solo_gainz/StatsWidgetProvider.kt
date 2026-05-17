package com.example.solo_gainz

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class StatsWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_stats).apply {
                val rank = widgetData.getString("player_rank", "E") ?: "E"
                val level = widgetData.getInt("player_level", 1)
                val xp = widgetData.getInt("player_xp", 0)
                val xpNeeded = widgetData.getInt("player_xp_needed", 100)
                val xpPercent = widgetData.getInt("player_xp_percent", 0)

                setTextViewText(R.id.player_rank, "RANK: $rank")
                setTextViewText(R.id.player_level, "LVL $level")
                setTextViewText(R.id.player_xp_text, "$xp / $xpNeeded XP")
                setProgressBar(R.id.player_xp_bar, 100, xpPercent, false)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
