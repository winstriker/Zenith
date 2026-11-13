package it.winstriker.zenith

import android.content.ActivityNotFoundException
import android.content.Intent
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "zenith/file_opener")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "open" -> {
                        val path = call.argument<String>("path")
                        val mimeType = call.argument<String>("mimeType") ?: "*/*"
                        if (path == null) {
                            result.error("BAD_ARGS", "Missing 'path'", null)
                            return@setMethodCallHandler
                        }
                        openFile(File(path), mimeType, result)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    // Opens an app-owned file (under filesDir/exports) in the system viewer via
    // FileProvider. A content:// URI with a read grant needs no storage permission.
    private fun openFile(file: File, mimeType: String, result: MethodChannel.Result) {
        if (!file.exists()) {
            result.error("NOT_FOUND", "File not found: ${file.absolutePath}", null)
            return
        }
        try {
            val uri = FileProvider.getUriForFile(this, "$packageName.exports", file)
            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, mimeType)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            startActivity(intent)
            result.success(true)
        } catch (e: ActivityNotFoundException) {
            result.error("NO_APP", "No app found to open $mimeType files", null)
        } catch (e: IllegalArgumentException) {
            result.error("BAD_PATH", e.message ?: "File is outside the exports directory", null)
        }
    }
}
