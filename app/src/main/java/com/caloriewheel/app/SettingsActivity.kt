package com.caloriewheel.app

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Intent
import android.os.Bundle
import android.view.LayoutInflater
import android.widget.EditText
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import com.caloriewheel.app.data.CalorieDataStore
import com.caloriewheel.app.databinding.ActivitySettingsBinding
import com.caloriewheel.app.widget.CalorieWidgetProvider

/**
 * Settings activity for configuring daily calorie goal and increment.
 */
class SettingsActivity : AppCompatActivity() {

    private lateinit var binding: ActivitySettingsBinding
    private lateinit var dataStore: CalorieDataStore

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivitySettingsBinding.inflate(layoutInflater)
        setContentView(binding.root)

        dataStore = CalorieDataStore.getInstance(this)

        setupUI()
        setupListeners()
    }

    private fun setupUI() {
        updateSummaries()
    }

    private fun updateSummaries() {
        binding.dailyGoalSummary.text = "${dataStore.dailyGoal} calories"
        binding.incrementSummary.text = "${dataStore.increment} calories per notch"
    }

    private fun setupListeners() {
        binding.backButton.setOnClickListener {
            finish()
        }

        binding.dailyGoalSetting.setOnClickListener {
            showNumberInputDialog(
                title = getString(R.string.daily_goal_title),
                hint = "Enter a value between 500 and 10,000",
                currentValue = dataStore.dailyGoal,
                minValue = 500,
                maxValue = 10000
            ) { newValue ->
                dataStore.dailyGoal = newValue
                updateSummaries()
                updateWidget()
            }
        }

        binding.incrementSetting.setOnClickListener {
            showIncrementDialog()
        }

        binding.resetSetting.setOnClickListener {
            showResetConfirmDialog()
        }
    }

    private fun showNumberInputDialog(
        title: String,
        hint: String,
        currentValue: Int,
        minValue: Int,
        maxValue: Int,
        onConfirm: (Int) -> Unit
    ) {
        val dialogView = LayoutInflater.from(this)
            .inflate(R.layout.dialog_number_input, null)

        val titleView = dialogView.findViewById<TextView>(R.id.dialogTitle)
        val inputView = dialogView.findViewById<EditText>(R.id.numberInput)
        val hintView = dialogView.findViewById<TextView>(R.id.dialogHint)

        titleView.text = title
        inputView.setText(currentValue.toString())
        inputView.selectAll()
        hintView.text = hint

        AlertDialog.Builder(this, com.google.android.material.R.style.ThemeOverlay_Material3_MaterialAlertDialog)
            .setView(dialogView)
            .setPositiveButton(R.string.save) { _, _ ->
                val input = inputView.text.toString().toIntOrNull()
                if (input != null && input in minValue..maxValue) {
                    onConfirm(input)
                } else {
                    Toast.makeText(
                        this,
                        "Please enter a value between $minValue and $maxValue",
                        Toast.LENGTH_SHORT
                    ).show()
                }
            }
            .setNegativeButton(R.string.cancel, null)
            .show()
    }

    private fun showIncrementDialog() {
        val options = arrayOf("10 calories", "25 calories", "50 calories", "100 calories")
        val values = intArrayOf(10, 25, 50, 100)
        val currentIndex = values.indexOf(dataStore.increment).takeIf { it >= 0 } ?: 2

        AlertDialog.Builder(this, com.google.android.material.R.style.ThemeOverlay_Material3_MaterialAlertDialog)
            .setTitle(R.string.increment_title)
            .setSingleChoiceItems(options, currentIndex) { dialog, which ->
                dataStore.increment = values[which]
                updateSummaries()
                updateWidget()
                dialog.dismiss()
            }
            .setNegativeButton(R.string.cancel, null)
            .show()
    }

    private fun showResetConfirmDialog() {
        AlertDialog.Builder(this, com.google.android.material.R.style.ThemeOverlay_Material3_MaterialAlertDialog)
            .setTitle(R.string.reset_title)
            .setMessage(R.string.reset_confirm)
            .setPositiveButton(R.string.yes) { _, _ ->
                dataStore.resetCalories()
                Toast.makeText(this, R.string.reset_done, Toast.LENGTH_SHORT).show()
                updateWidget()
            }
            .setNegativeButton(R.string.no, null)
            .show()
    }

    private fun updateWidget() {
        val intent = Intent(this, CalorieWidgetProvider::class.java).apply {
            action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
            val widgetManager = AppWidgetManager.getInstance(this@SettingsActivity)
            val widgetComponent = ComponentName(this@SettingsActivity, CalorieWidgetProvider::class.java)
            val widgetIds = widgetManager.getAppWidgetIds(widgetComponent)
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, widgetIds)
        }
        sendBroadcast(intent)
    }
}
