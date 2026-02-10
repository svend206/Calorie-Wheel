# Calorie Wheel

A simple Android app for tracking daily calorie intake using an intuitive rotating wheel interface.

![Calorie Wheel](app/src/main/res/drawable/ic_launcher_new.xml)

## Features

- **Rotating Wheel Interface**: Spin the wheel to set your current calorie count
- **Home Screen Widget**: Quick-access widget showing your daily progress
- **Customizable Daily Goal**: Default 2400 calories, adjustable 500-10,000
- **Adjustable Increment**: Choose 10, 25, 50, or 100 calorie steps
- **Automatic Daily Reset**: Calories reset to 0 at 3:00 AM every day
- **Haptic Feedback**: Feel each notch as you rotate
- **Color Indicators**: Green → Orange → Red as you approach your goal
- **No Login Required**: All data stored locally on device

## How to Use

1. **Open the app** to see the full-screen calorie wheel
2. **Rotate the wheel** clockwise to increase calories, counter-clockwise to decrease
3. **The window at the top** shows your current calorie count
4. **Long-press the wheel** or tap the gear icon to access settings
5. **Add the widget** to your home screen for quick access

## Building the App

### Prerequisites

1. **Android Studio** (Arctic Fox or newer)
   - Download from: https://developer.android.com/studio

2. **JDK 17** or higher
   - Usually bundled with Android Studio

### Build Steps

1. **Open the project in Android Studio**
   ```
   File → Open → Navigate to the CalorieWheel folder
   ```

2. **Wait for Gradle sync**
   - Android Studio will automatically download dependencies
   - This may take a few minutes on first build

3. **Connect your Android device**
   - Enable Developer Options on your phone:
     - Go to Settings → About Phone
     - Tap "Build Number" 7 times
   - Enable USB Debugging:
     - Go to Settings → Developer Options
     - Enable "USB Debugging"
   - Connect via USB cable

4. **Build and Run**
   - Click the green "Run" button (▶) in Android Studio
   - Or press Shift+F10
   - Select your device from the list

### Building an APK

To create an APK file you can share:

1. **Menu → Build → Build Bundle(s) / APK(s) → Build APK(s)**

2. The APK will be created at:
   ```
   app/build/outputs/apk/debug/app-debug.apk
   ```

3. Transfer this file to any Android phone and install it

### Requirements

- **Minimum Android Version**: Android 8.0 (API 26)
- **Target Android Version**: Android 14 (API 34)
- **Permissions Required**:
  - `SCHEDULE_EXACT_ALARM` - For 3am daily reset
  - `RECEIVE_BOOT_COMPLETED` - To restore reset alarm after reboot
  - `VIBRATE` - For haptic feedback on wheel rotation

## Project Structure

```
CalorieWheel/
├── app/
│   ├── src/main/
│   │   ├── java/com/caloriewheel/app/
│   │   │   ├── MainActivity.kt          # Main wheel screen
│   │   │   ├── SettingsActivity.kt       # Settings screen
│   │   │   ├── data/
│   │   │   │   └── CalorieDataStore.kt   # Data storage
│   │   │   ├── view/
│   │   │   │   └── CalorieWheelView.kt   # Custom wheel view
│   │   │   ├── widget/
│   │   │   │   └── CalorieWidgetProvider.kt  # Home widget
│   │   │   └── service/
│   │   │       ├── ResetScheduler.kt     # 3am reset scheduler
│   │   │       ├── ResetReceiver.kt      # Reset handler
│   │   │       └── BootReceiver.kt       # Boot complete handler
│   │   └── res/
│   │       ├── layout/                   # UI layouts
│   │       ├── drawable/                 # Icons and graphics
│   │       ├── values/                   # Strings, colors, themes
│   │       └── xml/                      # Widget configuration
│   └── build.gradle.kts
├── build.gradle.kts
├── settings.gradle.kts
└── gradle.properties
```

## Adding the Widget

1. Long-press on your home screen
2. Tap "Widgets"
3. Find "Calorie Wheel Widget"
4. Drag it to your home screen
5. Tap the widget to open the full app

## Customization

### Change Daily Goal
1. Open the app
2. Tap the gear icon (or long-press the wheel)
3. Tap "Daily Calorie Goal"
4. Enter your desired goal (500-10,000)

### Change Increment
1. Open settings
2. Tap "Wheel Increment"
3. Choose: 10, 25, 50, or 100 calories per notch

### Reset Today's Calories
1. Open settings
2. Tap "Reset Calories"
3. Confirm to reset to 0

## Technical Details

### 3am Reset Logic
- The app calculates "days" based on a 3am boundary
- This means 2:59am is still "yesterday" and 3:00am is "today"
- Calories automatically reset when you first use the app after 3am
- An AlarmManager alarm also triggers the reset at exactly 3am

### Data Storage
- All data is stored in SharedPreferences
- No cloud sync or account required
- Data persists across app updates
- Uninstalling the app removes all data

## Troubleshooting

### Widget not updating
- Widgets update every 30 minutes automatically
- Opening the main app forces an immediate widget update
- Try removing and re-adding the widget

### Reset not happening at 3am
- On some devices, battery optimization may delay the alarm
- Go to Settings → Apps → Calorie Wheel → Battery
- Select "Don't optimize" or "Unrestricted"

### Haptic feedback not working
- Check that your phone's vibration is enabled
- Some devices may not support subtle haptic patterns

## License

This app is provided as-is for personal use.

---

Built with ❤️ for simple calorie tracking
