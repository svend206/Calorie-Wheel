package com.caloriewheel.app.data

import android.content.Context
import android.content.SharedPreferences
import java.util.Calendar

/**
 * Handles all calorie data storage and retrieval using SharedPreferences.
 * Stores current calories, daily goal, and last update date.
 */
class CalorieDataStore(context: Context) {

    companion object {
        private const val PREFS_NAME = "calorie_wheel_prefs"
        private const val KEY_CURRENT_CALORIES = "current_calories"
        private const val KEY_DAILY_GOAL = "daily_goal"
        private const val KEY_LAST_UPDATE_DATE = "last_update_date"
        private const val KEY_INCREMENT = "calorie_increment"

        const val DEFAULT_DAILY_GOAL = 2400
        const val DEFAULT_INCREMENT = 50

        @Volatile
        private var instance: CalorieDataStore? = null

        fun getInstance(context: Context): CalorieDataStore {
            return instance ?: synchronized(this) {
                instance ?: CalorieDataStore(context.applicationContext).also { instance = it }
            }
        }
    }

    private val prefs: SharedPreferences =
        context.applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    /**
     * Get the current calorie count.
     * Automatically resets if the date has changed (past 3am).
     */
    var currentCalories: Int
        get() {
            checkAndResetIfNewDay()
            return prefs.getInt(KEY_CURRENT_CALORIES, 0)
        }
        set(value) {
            val clampedValue = value.coerceIn(0, dailyGoal)
            prefs.edit()
                .putInt(KEY_CURRENT_CALORIES, clampedValue)
                .putString(KEY_LAST_UPDATE_DATE, getCurrentDateKey())
                .apply()
        }

    /**
     * Get or set the daily calorie goal.
     */
    var dailyGoal: Int
        get() = prefs.getInt(KEY_DAILY_GOAL, DEFAULT_DAILY_GOAL)
        set(value) {
            val clampedValue = value.coerceIn(500, 10000)
            prefs.edit().putInt(KEY_DAILY_GOAL, clampedValue).apply()
            // Also clamp current calories if they exceed new goal
            if (currentCalories > clampedValue) {
                currentCalories = clampedValue
            }
        }

    /**
     * Get or set the calorie increment (step size on wheel).
     */
    var increment: Int
        get() = prefs.getInt(KEY_INCREMENT, DEFAULT_INCREMENT)
        set(value) {
            val clampedValue = value.coerceIn(10, 100)
            prefs.edit().putInt(KEY_INCREMENT, clampedValue).apply()
        }

    /**
     * Reset calories to 0.
     */
    fun resetCalories() {
        prefs.edit()
            .putInt(KEY_CURRENT_CALORIES, 0)
            .putString(KEY_LAST_UPDATE_DATE, getCurrentDateKey())
            .apply()
    }

    /**
     * Check if we've passed 3am since last update and reset if so.
     */
    private fun checkAndResetIfNewDay() {
        val lastUpdateDate = prefs.getString(KEY_LAST_UPDATE_DATE, null)
        val currentDateKey = getCurrentDateKey()

        if (lastUpdateDate != null && lastUpdateDate != currentDateKey) {
            // Date has changed, reset calories
            prefs.edit()
                .putInt(KEY_CURRENT_CALORIES, 0)
                .putString(KEY_LAST_UPDATE_DATE, currentDateKey)
                .apply()
        } else if (lastUpdateDate == null) {
            // First time, just set the date
            prefs.edit()
                .putString(KEY_LAST_UPDATE_DATE, currentDateKey)
                .apply()
        }
    }

    /**
     * Get a date key that changes at 3am instead of midnight.
     * This ensures the reset happens at 3am.
     */
    private fun getCurrentDateKey(): String {
        val calendar = Calendar.getInstance()
        // Subtract 3 hours so the "day" starts at 3am
        calendar.add(Calendar.HOUR_OF_DAY, -3)
        val year = calendar.get(Calendar.YEAR)
        val dayOfYear = calendar.get(Calendar.DAY_OF_YEAR)
        return "$year-$dayOfYear"
    }

    /**
     * Get the number of notches on the wheel based on goal and increment.
     */
    fun getNotchCount(): Int {
        return dailyGoal / increment
    }

    /**
     * Snap a calorie value to the nearest increment.
     */
    fun snapToIncrement(calories: Int): Int {
        return ((calories + increment / 2) / increment) * increment
    }

    /**
     * Get the percentage of daily goal consumed.
     */
    fun getPercentage(): Float {
        return if (dailyGoal > 0) {
            (currentCalories.toFloat() / dailyGoal.toFloat()).coerceIn(0f, 1f)
        } else {
            0f
        }
    }
}
