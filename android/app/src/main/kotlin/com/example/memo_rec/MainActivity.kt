package ro.meteo.anm

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL_SCREEN    = "meteo_anm/screen"
    private val CHANNEL_BAROMETER = "ro.meteo.anm/barometer"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ── Ecran aprins în Car Mode ──────────────────────────────────────────
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_SCREEN)
            .setMethodCallHandler { call, result ->
                if (call.method == "setKeepScreenOn") {
                    val activ = call.argument<Boolean>("activ") ?: false
                    if (activ) {
                        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                    } else {
                        window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                    }
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }

        // ── Barometru → altitudine curentă ───────────────────────────────────
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_BAROMETER)
            .setStreamHandler(object : EventChannel.StreamHandler {

                private var sensorManager: SensorManager? = null
                private var listener: SensorEventListener? = null

                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
                    val barometru = sensorManager?.getDefaultSensor(Sensor.TYPE_PRESSURE)

                    if (barometru == null) {
                        events?.error("NO_SENSOR", "Barometru indisponibil", null)
                        return
                    }

                    listener = object : SensorEventListener {
                        override fun onSensorChanged(event: SensorEvent?) {
                            if (event != null && event.values.isNotEmpty()) {
                                events?.success(event.values[0].toDouble())
                            }
                        }
                        override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
                    }

                    sensorManager?.registerListener(
                        listener,
                        barometru,
                        SensorManager.SENSOR_DELAY_NORMAL
                    )
                }

                override fun onCancel(arguments: Any?) {
                    sensorManager?.unregisterListener(listener)
                    listener = null
                    sensorManager = null
                }
            })
    }
}
