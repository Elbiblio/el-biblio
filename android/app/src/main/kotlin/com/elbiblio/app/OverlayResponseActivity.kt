package com.elbiblio.app

import android.app.Activity
import android.content.Intent
import android.os.Bundle

/**
 * Transparent trampoline activity for full-screen overlay notification actions.
 *
 * Notification actions (e.g. check-in, talk, skip) target this activity. It
 * forwards the action and payload to [MainActivity] as intent extras so the
 * Flutter engine can read them on launch and route accordingly.
 */
class OverlayResponseActivity : Activity() {

  companion object {
    const val EXTRA_ACTION = "com.elbiblio.app.OVERLAY_ACTION"
    const val EXTRA_PAYLOAD = "com.elbiblio.app.OVERLAY_PAYLOAD"
  }

  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)

    val action = intent.getStringExtra(EXTRA_ACTION) ?: "check_in"
    val payload = intent.getStringExtra(EXTRA_PAYLOAD)

    val mainIntent = Intent(this, MainActivity::class.java).apply {
      addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
      putExtra(EXTRA_ACTION, action)
      if (payload != null) putExtra(EXTRA_PAYLOAD, payload)
    }

    startActivity(mainIntent)
    finish()
  }
}
