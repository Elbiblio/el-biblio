package com.elbiblio.app

import android.app.AppOpsManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.os.Process
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
  private val usageAccessChannelName = "com.elbiblio.app/usage_access"
  private val overlayChannelName = "com.elbiblio.app/overlay"
  private var overlayAction: String? = null
  private var overlayPayload: String? = null

  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    readOverlayExtras(intent)
  }

  override fun onNewIntent(intent: Intent) {
    super.onNewIntent(intent)
    readOverlayExtras(intent)
  }

  private fun readOverlayExtras(intent: Intent?) {
    overlayAction = intent?.getStringExtra(OverlayResponseActivity.EXTRA_ACTION)
    overlayPayload = intent?.getStringExtra(OverlayResponseActivity.EXTRA_PAYLOAD)
  }

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)

    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, usageAccessChannelName)
      .setMethodCallHandler { call, result ->
        when (call.method) {
          "isUsageAccessGranted" -> result.success(isUsageAccessGranted())
          "openUsageAccessSettings" -> result.success(openUsageAccessSettings())
          else -> result.notImplemented()
        }
      }

    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, overlayChannelName)
      .setMethodCallHandler { call, result ->
        when (call.method) {
          "getOverlayAction" -> result.success(
            mapOf(
              "action" to overlayAction,
              "payload" to overlayPayload
            )
          )
          "consumeOverlayAction" -> {
            overlayAction = null
            overlayPayload = null
            result.success(null)
          }
          else -> result.notImplemented()
        }
      }
  }

  private fun isUsageAccessGranted(): Boolean {
    val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager

    val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
      appOps.unsafeCheckOpNoThrow(
        AppOpsManager.OPSTR_GET_USAGE_STATS,
        Process.myUid(),
        packageName
      )
    } else {
      @Suppress("DEPRECATION")
      appOps.checkOpNoThrow(
        AppOpsManager.OPSTR_GET_USAGE_STATS,
        Process.myUid(),
        packageName
      )
    }

    return mode == AppOpsManager.MODE_ALLOWED
  }

  private fun openUsageAccessSettings(): Boolean {
    return try {
      startActivity(
        Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS).apply {
          addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
      )
      true
    } catch (_: Exception) {
      false
    }
  }
}
