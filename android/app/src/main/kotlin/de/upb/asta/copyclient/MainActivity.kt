package de.upb.asta.copyclient

import android.os.Bundle
import android.os.Environment

import io.flutter.app.FlutterActivity
import io.flutter.plugins.GeneratedPluginRegistrant
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
  private val DOWNLOAD_CHANNEL = "de.upb.copyclient/download_path"

  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    GeneratedPluginRegistrant.registerWith(this)

    MethodChannel(flutterView, DOWNLOAD_CHANNEL).setMethodCallHandler { call, result ->
      when {
        call.method == "getDownloadsDirectory" -> result.success(getDownloadsDirectory())
        else -> result.notImplemented()
      }
    }
  }

  private fun getDownloadsDirectory(): String {
    return Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS).getAbsolutePath();
  }
}
