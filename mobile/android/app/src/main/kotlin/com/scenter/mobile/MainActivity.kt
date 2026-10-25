package com.scenter.mobile

import android.media.AudioAttributes
import android.media.AudioManager
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            getSystemService(AudioManager::class.java)
                ?.setAllowedCapturePolicy(AudioAttributes.ALLOW_CAPTURE_BY_NONE)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.scenter.mobile/device")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getAndroidId" -> {
                        result.success(
                            Settings.Secure.getString(contentResolver, Settings.Secure.ANDROID_ID)
                        )
                    }
                    "isEmulator" -> {
                        result.success(detectEmulator())
                    }
                    else -> {
                        result.notImplemented()
                    }
                }
            }
    }

    // كشف المحاكي: بصمة النظام + بيانات الصانع + خصائص qemu + ملفات الأجهزة الافتراضية.
    // إشارة قوية واحدة تكفي (waydroid/emulator/goldfish...)؛ الضعيفة تُحسم مجتمعة.
    // الهواوي الحقيقية (HUAWEI/kirin/release-keys) لا تطابق أي إشارة هنا.
    private fun detectEmulator(): Boolean {
        val fingerprint = Build.FINGERPRINT.lowercase()
        val manufacturer = Build.MANUFACTURER.lowercase()
        val brand = Build.BRAND.lowercase()
        val model = Build.MODEL.lowercase()
        val device = Build.DEVICE.lowercase()
        val product = Build.PRODUCT.lowercase()
        val hardware = Build.HARDWARE.lowercase()
        val board = Build.BOARD.lowercase()

        // إشارات قوية — وحدها تكفي
        val strongTokens = listOf(
            "waydroid", "emulator", "goldfish", "ranchu",
            "genymotion", "vbox86", "android sdk built for", "sdk_gphone"
        )
        if (strongTokens.any { fingerprint.contains(it) }) return true
        if (strongTokens.any { manufacturer.contains(it) }) return true
        if (strongTokens.any { model.contains(it) }) return true
        if (strongTokens.any { brand.contains(it) }) return true

        // خصائص النظام (reflection — بلا صلاحيات)
        if (sysProp("ro.kernel.qemu") == "1") return true
        val hw = sysProp("ro.hardware")
        if (listOf("goldfish", "ranchu", "vbox", "waydroid").any { hw.contains(it) }) return true

        // ملفات أجهزة افتراضية لا exist على جهاز حقيقي
        if (File("/dev/qemu_pipe").exists()) return true
        if (File("/dev/goldfish_pipe").exists()) return true

        // إشارات ضعيفة — تُحسم مجتمعة
        if (brand.startsWith("generic") && device.startsWith("generic")) return true
        if (product.startsWith("sdk") || product.contains("google_sdk") ||
            product.contains("simulator") || product.contains("waydroid")
        ) return true
        if (listOf("goldfish", "ranchu", "vbox86", "nox", "cutf").any { hardware.contains(it) }) return true
        if (listOf("goldfish", "ranchu", "vbox86").any { board.contains(it) }) return true

        return false
    }

    private fun sysProp(key: String): String {
        return try {
            val clazz = Class.forName("android.os.SystemProperties")
            val get = clazz.getMethod("get", String::class.java)
            (get.invoke(null, key) as? String)?.lowercase() ?: ""
        } catch (_: Exception) {
            ""
        }
    }
}
