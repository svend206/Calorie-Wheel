package com.caloriewheel.app.service

import android.appwidget.AppWidgetManager
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import com.caloriewheel.app.data.CalorieDataStore
import com.caloriewheel.app.widget.CalorieWidgetProvider

/**
 * Broadcast receiver that handles the 3am daily reset.
 * Resets calories to 0 and updates any widgets.
 */
class ResetReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        // Reset calories
        val dataStore = CalorieDataStore.getInstance(context)
        dataStore.resetCalories()

        // Update widgets
        updateWidgets(context)

        // Reschedule for the next day
        ResetScheduler.scheduleReset(context)
    }

    private fun updateWidgets(context: Context) {
        val appWidgetManager = AppWidgetManager.getInstance(context)
        val widgetComponent = ComponentName(context, CalorieWidgetProvider::class.java)
        val appWidgetIds = appWidgetManager.getAppWidgetIds(widgetComponent)

        for (appWidgetId in appWidgetIds) {
            CalorieWidgetProvider.updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }
}
