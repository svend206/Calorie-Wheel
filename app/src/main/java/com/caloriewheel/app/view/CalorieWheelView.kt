package com.caloriewheel.app.view

import android.content.Context
import android.graphics.*
import android.util.AttributeSet
import android.view.GestureDetector
import android.view.HapticFeedbackConstants
import android.view.MotionEvent
import android.view.View
import com.caloriewheel.app.R
import com.caloriewheel.app.data.CalorieDataStore
import kotlin.math.atan2
import kotlin.math.cos
import kotlin.math.min
import kotlin.math.sin

/**
 * Custom view that displays a rotatable calorie wheel.
 * The wheel shows calorie values around its circumference.
 * Users rotate the wheel to set their current calorie intake.
 */
class CalorieWheelView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0
) : View(context, attrs, defStyleAttr) {

    interface OnCalorieChangeListener {
        fun onCalorieChanged(calories: Int)
    }

    var onCalorieChangeListener: OnCalorieChangeListener? = null

    private val dataStore = CalorieDataStore.getInstance(context)

    // Paints
    private val wheelPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.FILL
    }

    private val wheelRimPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.STROKE
        strokeWidth = 8f
    }

    private val notchPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.STROKE
        strokeWidth = 4f
        color = Color.WHITE
    }

    private val textPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        textAlign = Paint.Align.CENTER
        color = Color.WHITE
    }

    private val windowPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.FILL
        color = Color.WHITE
    }

    private val windowTextPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        textAlign = Paint.Align.CENTER
        typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
    }

    private val pointerPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.FILL
    }

    // Gradient colors
    private val gradientColors = intArrayOf(
        Color.parseColor("#4CAF50"),  // Green
        Color.parseColor("#8BC34A"),  // Light Green
        Color.parseColor("#FFEB3B"),  // Yellow
        Color.parseColor("#FF9800"),  // Orange
        Color.parseColor("#F44336")   // Red
    )

    // Dimensions
    private var centerX = 0f
    private var centerY = 0f
    private var wheelRadius = 0f
    private var innerRadius = 0f
    private var windowWidth = 0f
    private var windowHeight = 0f

    // Rotation state
    private var currentRotation = 0f  // in degrees
    private var previousAngle = 0f
    private var lastNotchIndex = -1

    // Gesture detection
    private val gestureDetector = GestureDetector(context, object : GestureDetector.SimpleOnGestureListener() {
        override fun onLongPress(e: MotionEvent) {
            // Long press opens settings
            performLongClick()
        }
    })

    init {
        // Initialize rotation based on current calories
        updateRotationFromCalories()
    }

    override fun onSizeChanged(w: Int, h: Int, oldw: Int, oldh: Int) {
        super.onSizeChanged(w, h, oldw, oldh)

        centerX = w / 2f
        centerY = h / 2f
        wheelRadius = min(w, h) / 2f * 0.85f
        innerRadius = wheelRadius * 0.55f

        // Window dimensions
        windowWidth = wheelRadius * 0.5f
        windowHeight = wheelRadius * 0.25f

        // Update text sizes based on view size
        textPaint.textSize = wheelRadius * 0.08f
        windowTextPaint.textSize = wheelRadius * 0.18f

        // Update stroke widths
        wheelRimPaint.strokeWidth = wheelRadius * 0.02f
        notchPaint.strokeWidth = wheelRadius * 0.01f
    }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)

        drawWheel(canvas)
        drawNotches(canvas)
        drawWindow(canvas)
        drawPointer(canvas)
    }

    private fun drawWheel(canvas: Canvas) {
        // Create gradient based on current calorie percentage
        val percentage = dataStore.getPercentage()
        val gradientColorIndex = (percentage * (gradientColors.size - 1)).toInt()
            .coerceIn(0, gradientColors.size - 2)

        val startColor = gradientColors[gradientColorIndex]
        val endColor = gradientColors[(gradientColorIndex + 1).coerceAtMost(gradientColors.size - 1)]

        // Radial gradient for the wheel
        val gradient = RadialGradient(
            centerX, centerY, wheelRadius,
            intArrayOf(
                blendColors(startColor, Color.WHITE, 0.3f),
                startColor,
                blendColors(startColor, Color.BLACK, 0.2f)
            ),
            floatArrayOf(0f, 0.7f, 1f),
            Shader.TileMode.CLAMP
        )
        wheelPaint.shader = gradient

        // Draw the wheel circle
        canvas.drawCircle(centerX, centerY, wheelRadius, wheelPaint)

        // Draw inner circle (darker)
        val innerGradient = RadialGradient(
            centerX, centerY, innerRadius,
            intArrayOf(
                Color.parseColor("#2C2C2C"),
                Color.parseColor("#1A1A1A")
            ),
            null,
            Shader.TileMode.CLAMP
        )
        wheelPaint.shader = innerGradient
        canvas.drawCircle(centerX, centerY, innerRadius, wheelPaint)
        wheelPaint.shader = null

        // Draw rim
        wheelRimPaint.color = blendColors(startColor, Color.BLACK, 0.3f)
        canvas.drawCircle(centerX, centerY, wheelRadius, wheelRimPaint)
        canvas.drawCircle(centerX, centerY, innerRadius, wheelRimPaint)
    }

    private fun drawNotches(canvas: Canvas) {
        val notchCount = dataStore.getNotchCount()
        val anglePerNotch = 360f / notchCount
        val increment = dataStore.increment

        for (i in 0 until notchCount) {
            // Calculate angle with rotation
            val angle = (i * anglePerNotch + currentRotation - 90) // -90 to start from top

            val angleRad = Math.toRadians(angle.toDouble())

            // Draw notch line
            val notchInnerRadius = wheelRadius * 0.88f
            val notchOuterRadius = wheelRadius * 0.98f

            val startX = centerX + notchInnerRadius * cos(angleRad).toFloat()
            val startY = centerY + notchInnerRadius * sin(angleRad).toFloat()
            val endX = centerX + notchOuterRadius * cos(angleRad).toFloat()
            val endY = centerY + notchOuterRadius * sin(angleRad).toFloat()

            // Thicker notch for major values (every 500 calories)
            val calorieValue = i * increment
            val isMajorNotch = calorieValue % 500 == 0

            notchPaint.strokeWidth = if (isMajorNotch) wheelRadius * 0.02f else wheelRadius * 0.01f
            notchPaint.alpha = if (isMajorNotch) 255 else 180
            canvas.drawLine(startX, startY, endX, endY, notchPaint)

            // Draw calorie text for major notches
            if (isMajorNotch && notchCount <= 100) {
                val textRadius = wheelRadius * 0.75f
                val textX = centerX + textRadius * cos(angleRad).toFloat()
                val textY = centerY + textRadius * sin(angleRad).toFloat()

                canvas.save()
                canvas.translate(textX, textY)
                canvas.rotate(angle + 90)
                textPaint.alpha = 200
                canvas.drawText(calorieValue.toString(), 0f, textPaint.textSize / 3, textPaint)
                canvas.restore()
            }
        }
    }

    private fun drawWindow(canvas: Canvas) {
        // Draw window background at the top
        val windowRect = RectF(
            centerX - windowWidth / 2,
            centerY - wheelRadius - windowHeight * 0.3f,
            centerX + windowWidth / 2,
            centerY - wheelRadius + windowHeight * 1.2f
        )

        // Window with rounded corners
        val cornerRadius = windowHeight * 0.3f

        // Shadow
        windowPaint.color = Color.parseColor("#40000000")
        val shadowOffset = 4f
        canvas.drawRoundRect(
            RectF(windowRect.left + shadowOffset, windowRect.top + shadowOffset,
                windowRect.right + shadowOffset, windowRect.bottom + shadowOffset),
            cornerRadius, cornerRadius, windowPaint
        )

        // Window background
        windowPaint.color = Color.WHITE
        canvas.drawRoundRect(windowRect, cornerRadius, cornerRadius, windowPaint)

        // Window border
        wheelRimPaint.color = Color.parseColor("#333333")
        canvas.drawRoundRect(windowRect, cornerRadius, cornerRadius, wheelRimPaint)

        // Draw current calorie value
        val currentCalories = dataStore.currentCalories
        windowTextPaint.color = getColorForCalories(currentCalories)

        val textY = windowRect.centerY() + windowTextPaint.textSize / 3
        canvas.drawText(currentCalories.toString(), centerX, textY, windowTextPaint)

        // Draw "cal" label
        val labelPaint = Paint(textPaint).apply {
            textSize = windowTextPaint.textSize * 0.35f
            color = Color.GRAY
        }
        canvas.drawText("cal", centerX, textY + windowTextPaint.textSize * 0.5f, labelPaint)
    }

    private fun drawPointer(canvas: Canvas) {
        // Draw a triangular pointer at the top pointing to the current value
        val pointerPath = Path()

        val pointerHeight = wheelRadius * 0.08f
        val pointerWidth = wheelRadius * 0.06f

        val pointerTop = centerY - wheelRadius + pointerHeight
        val pointerBase = centerY - wheelRadius - 5f

        pointerPath.moveTo(centerX, pointerTop)
        pointerPath.lineTo(centerX - pointerWidth / 2, pointerBase)
        pointerPath.lineTo(centerX + pointerWidth / 2, pointerBase)
        pointerPath.close()

        pointerPaint.color = Color.parseColor("#333333")
        canvas.drawPath(pointerPath, pointerPaint)
    }

    override fun onTouchEvent(event: MotionEvent): Boolean {
        gestureDetector.onTouchEvent(event)

        when (event.action) {
            MotionEvent.ACTION_DOWN -> {
                previousAngle = getAngle(event.x, event.y)
                return true
            }
            MotionEvent.ACTION_MOVE -> {
                val currentAngle = getAngle(event.x, event.y)
                var deltaAngle = currentAngle - previousAngle

                // Handle wrap-around
                if (deltaAngle > 180) deltaAngle -= 360
                if (deltaAngle < -180) deltaAngle += 360

                currentRotation += deltaAngle
                previousAngle = currentAngle

                // Update calories based on rotation
                updateCaloriesFromRotation()

                invalidate()
                return true
            }
            MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> {
                // Snap to nearest notch
                snapToNearestNotch()
                return true
            }
        }
        return super.onTouchEvent(event)
    }

    private fun getAngle(x: Float, y: Float): Float {
        val dx = x - centerX
        val dy = y - centerY
        return Math.toDegrees(atan2(dy.toDouble(), dx.toDouble())).toFloat()
    }

    private fun updateCaloriesFromRotation() {
        val notchCount = dataStore.getNotchCount()
        val anglePerNotch = 360f / notchCount
        val increment = dataStore.increment

        // Normalize rotation to 0-360
        var normalizedRotation = currentRotation % 360
        if (normalizedRotation < 0) normalizedRotation += 360

        // Calculate notch index (inverted because rotation goes opposite to value)
        val notchIndex = ((360 - normalizedRotation) / anglePerNotch).toInt() % notchCount

        val newCalories = notchIndex * increment

        // Provide haptic feedback when crossing a notch
        if (notchIndex != lastNotchIndex) {
            performHapticFeedback(HapticFeedbackConstants.CLOCK_TICK)
            lastNotchIndex = notchIndex
        }

        if (newCalories != dataStore.currentCalories) {
            dataStore.currentCalories = newCalories
            onCalorieChangeListener?.onCalorieChanged(newCalories)
        }
    }

    private fun updateRotationFromCalories() {
        val notchCount = dataStore.getNotchCount()
        val anglePerNotch = 360f / notchCount
        val increment = dataStore.increment

        val notchIndex = dataStore.currentCalories / increment
        currentRotation = 360 - (notchIndex * anglePerNotch)
        lastNotchIndex = notchIndex
    }

    private fun snapToNearestNotch() {
        val notchCount = dataStore.getNotchCount()
        val anglePerNotch = 360f / notchCount

        // Round to nearest notch
        var normalizedRotation = currentRotation % 360
        if (normalizedRotation < 0) normalizedRotation += 360

        val notchIndex = ((normalizedRotation + anglePerNotch / 2) / anglePerNotch).toInt() % notchCount
        currentRotation = notchIndex * anglePerNotch

        updateCaloriesFromRotation()
        invalidate()
    }

    private fun getColorForCalories(calories: Int): Int {
        val percentage = calories.toFloat() / dataStore.dailyGoal
        return when {
            percentage < 0.5f -> Color.parseColor("#4CAF50")  // Green
            percentage < 0.75f -> Color.parseColor("#FF9800") // Orange
            else -> Color.parseColor("#F44336")               // Red
        }
    }

    private fun blendColors(color1: Int, color2: Int, ratio: Float): Int {
        val inverseRatio = 1 - ratio
        val r = (Color.red(color1) * inverseRatio + Color.red(color2) * ratio).toInt()
        val g = (Color.green(color1) * inverseRatio + Color.green(color2) * ratio).toInt()
        val b = (Color.blue(color1) * inverseRatio + Color.blue(color2) * ratio).toInt()
        return Color.rgb(r, g, b)
    }

    /**
     * Refresh the view when data changes externally.
     */
    fun refresh() {
        updateRotationFromCalories()
        invalidate()
    }

    /**
     * Set calories programmatically.
     */
    fun setCalories(calories: Int) {
        dataStore.currentCalories = dataStore.snapToIncrement(calories)
        updateRotationFromCalories()
        invalidate()
    }
}
