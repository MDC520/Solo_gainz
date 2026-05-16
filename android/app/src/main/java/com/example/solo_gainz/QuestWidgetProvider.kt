package com.example.solo_gainz

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class QuestWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {
                val completed = widgetData.getBoolean("all_completed", false)
                
                if (completed) {
                    val targetMs = widgetData.getLong("refresh_time_ms", System.currentTimeMillis())
                    
                    setViewVisibility(R.id.widget_progress_bar, android.view.View.GONE)
                    setViewVisibility(R.id.widget_progress_text, android.view.View.GONE)
                    setViewVisibility(R.id.quests_container, android.view.View.GONE)
                    setViewVisibility(R.id.widget_chronometer, android.view.View.VISIBLE)
                    
                    setTextViewText(R.id.widget_title, "DAILY QUESTS COMPLETED!")
                    setChronometer(R.id.widget_chronometer, android.os.SystemClock.elapsedRealtime() + (targetMs - System.currentTimeMillis()), null, true)
                } else {
                    val progressStr = widgetData.getString("quest_progress", "0 / 0") ?: "0 / 0"
                    val progressPct = widgetData.getInt("quest_percent", 0)
                    
                    setViewVisibility(R.id.widget_progress_bar, android.view.View.VISIBLE)
                    setViewVisibility(R.id.widget_progress_text, android.view.View.VISIBLE)
                    setViewVisibility(R.id.quests_container, android.view.View.VISIBLE)
                    setViewVisibility(R.id.widget_chronometer, android.view.View.GONE)
                    
                    setTextViewText(R.id.widget_title, "DAILY QUESTS")
                    setTextViewText(R.id.widget_progress_text, progressStr)
                    setProgressBar(R.id.widget_progress_bar, 100, progressPct, false)

                    // Update the 4 quests
                    val questIds = arrayOf(R.id.quest_0, R.id.quest_1, R.id.quest_2, R.id.quest_3)
                    val nameIds = arrayOf(R.id.quest_0_name, R.id.quest_1_name, R.id.quest_2_name, R.id.quest_3_name)
                    val progIds = arrayOf(R.id.quest_0_progress, R.id.quest_1_progress, R.id.quest_2_progress, R.id.quest_3_progress)

                    for (i in 0 until 4) {
                        val visible = widgetData.getBoolean("quest_${i}_visible", false)
                        if (visible) {
                            setViewVisibility(questIds[i], android.view.View.VISIBLE)
                            val qName = widgetData.getString("quest_${i}_name", "Quest ${i+1}")
                            val qProg = widgetData.getInt("quest_${i}_progress", 0)
                            setTextViewText(nameIds[i], qName)
                            setProgressBar(progIds[i], 100, qProg, false)
                        } else {
                            setViewVisibility(questIds[i], android.view.View.GONE)
                        }
                    }
                }
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
