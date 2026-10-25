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

    // كشف المحاكي: بصمة النظام + بيانات الصانع + خصائص qemu + ملفات الأجهزة الافتراضية
    // + حزم BlueStacks/Nox/LDPlayer/MEmu + ملفاتها + معمارية x86 + hypervisor
    // إشارة قوية واحدة تكفي؛ الضعيفة تُحسم مجتمعة.
    // الهواوي الحقيقية (HUAWEI/kirin/arm64/release-keys) لا تطابق أي إشارة هنا.
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

        val emulatorPackages = listOf(
            "com.bluestacks.appmart", "com.bluestacks.settings",
            "com.bluestacks.BstCommandProcessor", "com.bluestacks.home",
            "com.bignox.app.store.hd", "com.bignox.google.installer",
            "com.android.flysilkworm", "com.android.flysilkworm.coldlaunch",
            "com.microvirt.launcher", "com.microvirt.download"
        )
        for (pkg in emulatorPackages) {
            try {
                packageManager.getPackageInfo(pkg, 0)
                return true
            } catch (_: Exception) {
            }
        }

        val emulatorFiles = listOf(
            "/data/bluestacks.prop", "/data/.bluestacks.prop",
            "/sdcard/windows/BstSharedFolder",
            "/storage/emulated/0/windows/BstSharedFolder",
            "/data/data/com.bluestacks.settings",
            "/dev/socket/qemud",
            "/system/lib/libc_malloc_debug_qemu.so"
        )
        if (emulatorFiles.any { File(it).exists() }) return true

        if (Build.SUPPORTED_ABIS.any { it.lowercase().startsWith("x86") }) return true
        if (sysProp("ro.build.characteristics").contains("emulator")) return true

        val extendedTokens = listOf(
            "bluestacks", "bst", "nox", "ttvm", "ldplayer", "memu",
            "vbox86pcs", "android_x86"
        )
        if (extendedTokens.any {
                fingerprint.contains(it) || manufacturer.contains(it) ||
                    model.contains(it) || brand.contains(it) ||
                    device.contains(it) || product.contains(it) ||
                    hardware.contains(it) || board.contains(it)
            }
        ) return true
        if (listOf(
                "ro.build.display.id", "ro.build.version.incremental",
                "ro.build.description", "ro.product.system.device"
            ).any { prop -> extendedTokens.any { t -> sysProp(prop).contains(t) } }
        ) return true

        try {
            File("/proc/cpuinfo").readLines().any { line ->
                line.startsWith("flags") && line.contains("hypervisor")
            }.let { if (it) return true }
        } catch (_: Exception) {
        }

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
