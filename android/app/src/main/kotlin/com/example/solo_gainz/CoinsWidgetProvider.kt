package com.example.solo_gainz

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class CoinsWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_coins).apply {
                val coins = widgetData.getInt("player_coins", 0)
                setTextViewText(R.id.player_coins, coins.toString())
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
