package com.caloriewheel.app.service

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Broadcast receiver that reschedules the reset alarm after device boot.
 * Alarms are lost when the device restarts, so we need to reschedule them.
 */
class BootReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            // Reschedule the daily reset alarm
            ResetScheduler.scheduleReset(context)
        }
    }
}
