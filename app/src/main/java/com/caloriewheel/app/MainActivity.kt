package com.caloriewheel.app

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Intent
import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import com.caloriewheel.app.data.CalorieDataStore
import com.caloriewheel.app.databinding.ActivityMainBinding
import com.caloriewheel.app.service.ResetScheduler
import com.caloriewheel.app.view.CalorieWheelView
import com.caloriewheel.app.widget.CalorieWidgetProvider

/**
 * Main activity displaying the full-screen calorie wheel.
 */
class MainActivity : AppCompatActivity() {

    private lateinit var binding: ActivityMainBinding
    private lateinit var dataStore: CalorieDataStore

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityMainBinding.inflate(layoutInflater)
        setContentView(binding.root)

        dataStore = CalorieDataStore.getInstance(this)

        setupUI()
        setupListeners()

        // Schedule the daily reset alarm
        ResetScheduler.scheduleReset(this)
    }

    override fun onResume() {
        super.onResume()
        // Refresh the wheel when returning from settings
        binding.calorieWheel.refresh()
        updateDailyGoalDisplay()
    }

    private fun setupUI() {
        updateDailyGoalDisplay()
    }

    private fun setupListeners() {
        // Settings button
        binding.settingsButton.setOnClickListener {
            openSettings()
        }

        // Long press on wheel opens settings
        binding.calorieWheel.setOnLongClickListener {
            openSettings()
            true
        }

        // Calorie change listener to update widget
        binding.calorieWheel.onCalorieChangeListener = object : CalorieWheelView.OnCalorieChangeListener {
            override fun onCalorieChanged(calories: Int) {
                updateWidget()
            }
        }
    }

    private fun updateDailyGoalDisplay() {
        binding.dailyGoalValue.text = "${dataStore.dailyGoal} cal"
    }

    private fun openSettings() {
        startActivity(Intent(this, SettingsActivity::class.java))
    }

    private fun updateWidget() {
        // Update any widgets that are on the home screen
        val intent = Intent(this, CalorieWidgetProvider::class.java).apply {
            action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
            val widgetManager = AppWidgetManager.getInstance(this@MainActivity)
            val widgetComponent = ComponentName(this@MainActivity, CalorieWidgetProvider::class.java)
            val widgetIds = widgetManager.getAppWidgetIds(widgetComponent)
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, widgetIds)
        }
        sendBroadcast(intent)
    }
}
