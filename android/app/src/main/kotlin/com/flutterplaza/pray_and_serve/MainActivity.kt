package com.flutterplaza.pray_and_serve

import android.os.Bundle
import android.provider.ContactsContract
import androidx.activity.enableEdgeToEdge
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "com.flutterplaza.pray_and_serve/contacts"

    override fun onCreate(savedInstanceState: Bundle?) {
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "getEmailForContact") {
                    val displayName = call.argument<String>("displayName")
                    if (displayName == null) {
                        result.error("invalid_arg", "displayName is required", null)
                        return@setMethodCallHandler
                    }
                    val email = queryEmailByName(displayName)
                    result.success(email)
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun queryEmailByName(displayName: String): String? {
        val cursor = contentResolver.query(
            ContactsContract.CommonDataKinds.Email.CONTENT_URI,
            arrayOf(ContactsContract.CommonDataKinds.Email.ADDRESS),
            "${ContactsContract.CommonDataKinds.Email.DISPLAY_NAME} = ?",
            arrayOf(displayName),
            null
        ) ?: return null

        cursor.use {
            if (it.moveToFirst()) {
                val idx = it.getColumnIndex(ContactsContract.CommonDataKinds.Email.ADDRESS)
                if (idx >= 0) return it.getString(idx)
            }
        }
        return null
    }
}
