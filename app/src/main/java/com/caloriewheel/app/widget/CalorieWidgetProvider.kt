package com.caloriewheel.app.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.widget.RemoteViews
import com.caloriewheel.app.MainActivity
import com.caloriewheel.app.R
import com.caloriewheel.app.data.CalorieDataStore

/**
 * Widget provider for the home screen calorie display widget.
 * Shows current calories, progress bar, and daily goal.
 * Tapping opens the main app with the full wheel.
 */
class CalorieWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)

        // Handle custom update actions
        if (intent.action == ACTION_UPDATE_WIDGET) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val appWidgetIds = intent.getIntArrayExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS)
            if (appWidgetIds != null) {
                onUpdate(context, appWidgetManager, appWidgetIds)
            }
        }
    }

    companion object {
        const val ACTION_UPDATE_WIDGET = "com.caloriewheel.UPDATE_WIDGET"

        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val dataStore = CalorieDataStore.getInstance(context)
            val currentCalories = dataStore.currentCalories
            val dailyGoal = dataStore.dailyGoal
            val percentage = (currentCalories.toFloat() / dailyGoal * 100).toInt().coerceIn(0, 100)

            // Create the RemoteViews
            val views = RemoteViews(context.packageName, R.layout.widget_calorie)

            // Update calorie display
            views.setTextViewText(R.id.widgetCalories, currentCalories.toString())

            // Update goal text
            views.setTextViewText(R.id.widgetGoal, "$currentCalories / $dailyGoal cal")

            // Update progress bar
            views.setProgressBar(R.id.widgetProgress, 100, percentage, false)

            // Set color based on percentage
            val color = when {
                percentage < 50 -> Color.parseColor("#4CAF50")  // Green
                percentage < 75 -> Color.parseColor("#FF9800")  // Orange
                else -> Color.parseColor("#F44336")              // Red
            }
            views.setTextColor(R.id.widgetCalories, color)

            // Create intent to open main app when widget is tapped
            val intent = Intent(context, MainActivity::class.java)
            val pendingIntent = PendingIntent.getActivity(
                context,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widgetRoot, pendingIntent)

            // Update the widget
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
