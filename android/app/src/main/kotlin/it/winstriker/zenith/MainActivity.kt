package it.winstriker.zenith

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import android.os.Build
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private companion object {
        const val REQUEST_SAVE_BACKUP = 4201
        const val REQUEST_PICK_BACKUP = 4202
    }

    // Pending Dart call waiting for a system file picker to return.
    private var pendingBackupResult: MethodChannel.Result? = null
    private var pendingBackupSource: File? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Material You accent from the wallpaper, Android 12+ only.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "zenith/system_colors")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "accent" -> result.success(
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                            getColor(android.R.color.system_accent1_500)
                        } else {
                            null
                        },
                    )
                    else -> result.notImplemented()
                }
            }
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
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "zenith/backup_files")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "saveAs" -> {
                        val path = call.argument<String>("path")
                        val name = call.argument<String>("name")
                        val mimeType = call.argument<String>("mimeType") ?: "application/octet-stream"
                        if (path == null || name == null) {
                            result.error("BAD_ARGS", "Missing 'path' or 'name'", null)
                            return@setMethodCallHandler
                        }
                        val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                            addCategory(Intent.CATEGORY_OPENABLE)
                            type = mimeType
                            putExtra(Intent.EXTRA_TITLE, name)
                        }
                        startPicker(intent, REQUEST_SAVE_BACKUP, result, File(path))
                    }
                    "pick" -> {
                        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                            addCategory(Intent.CATEGORY_OPENABLE)
                            // Backups can come back from other apps with odd
                            // MIME types; the Dart side validates the content.
                            type = "*/*"
                        }
                        startPicker(intent, REQUEST_PICK_BACKUP, result, null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun startPicker(
        intent: Intent,
        requestCode: Int,
        result: MethodChannel.Result,
        source: File?,
    ) {
        if (pendingBackupResult != null) {
            result.error("BUSY", "A file picker is already open", null)
            return
        }
        pendingBackupResult = result
        pendingBackupSource = source
        try {
            startActivityForResult(intent, requestCode)
        } catch (e: ActivityNotFoundException) {
            pendingBackupResult = null
            pendingBackupSource = null
            result.error("NO_APP", "No file manager available", null)
        }
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode != REQUEST_SAVE_BACKUP && requestCode != REQUEST_PICK_BACKUP) {
            super.onActivityResult(requestCode, resultCode, data)
            return
        }
        val result = pendingBackupResult ?: return
        val source = pendingBackupSource
        pendingBackupResult = null
        pendingBackupSource = null

        val uri: Uri? = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            result.success(if (requestCode == REQUEST_SAVE_BACKUP) false else null)
            return
        }
        // Copy off the main thread; backups with photos can be a few MB.
        Thread {
            try {
                if (requestCode == REQUEST_SAVE_BACKUP) {
                    contentResolver.openOutputStream(uri)!!.use { out ->
                        source!!.inputStream().use { it.copyTo(out) }
                    }
                    runOnUiThread { result.success(true) }
                } else {
                    val target = File(cacheDir, "imported_backup")
                    contentResolver.openInputStream(uri)!!.use { input ->
                        target.outputStream().use { input.copyTo(it) }
                    }
                    runOnUiThread { result.success(target.absolutePath) }
                }
            } catch (e: Exception) {
                runOnUiThread { result.error("IO", e.message ?: "File copy failed", null) }
            }
        }.start()
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
