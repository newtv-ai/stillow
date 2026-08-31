package com.stillow.stillow

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.provider.OpenableColumns
import java.util.ArrayList
import java.util.HashMap
import com.ryanheise.audioservice.AudioServiceFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceFragmentActivity() {
    private val userSoundsChannelName = "com.stillow.stillow/user_sounds"
    private var pendingPick: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, userSoundsChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "pick" -> pickAudio(result)
                    "probe" -> {
                        val uri = call.argument<String>("uri")
                        if (uri.isNullOrEmpty()) {
                            result.success(-1)
                        } else {
                            result.success(probe(Uri.parse(uri)))
                        }
                    }
                    "persist" -> {
                        val uri = call.argument<String>("uri")
                        if (uri.isNullOrEmpty()) {
                            result.error("missing_uri", "Missing selected file URI.", null)
                        } else {
                            try {
                                persist(Uri.parse(uri))
                                result.success(null)
                            } catch (error: SecurityException) {
                                result.error(
                                    "persist_failed",
                                    "Could not keep access to the selected file.",
                                    error.message,
                                )
                            }
                        }
                    }
                    "release" -> {
                        val uri = call.argument<String>("uri")
                        if (!uri.isNullOrEmpty()) {
                            release(Uri.parse(uri))
                        }
                        result.success(null)
                    }
                    "beginPlayback", "endPlayback" -> result.success(null)
                    else -> result.notImplemented()
                }
            }
    }

    override fun getInitialRoute(): String? =
        if (isPrivacyIntent(intent)) "/privacy" else super.getInitialRoute()

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        if (isPrivacyIntent(intent)) {
            flutterEngine?.navigationChannel?.pushRoute("/privacy")
        }
    }

    @Suppress("DEPRECATION")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != REQUEST_PICK_AUDIO) return
        val pending = pendingPick
        pendingPick = null
        if (pending == null) return
        if (resultCode != Activity.RESULT_OK) {
            pending.success(null)
            return
        }
        val uris = linkedSetOf<Uri>()
        data?.clipData?.let { clip ->
            for (index in 0 until clip.itemCount) {
                clip.getItemAt(index).uri?.let(uris::add)
            }
        }
        data?.data?.let(uris::add)
        if (uris.isEmpty()) {
            pending.success(null)
            return
        }
        try {
            val payload = ArrayList<HashMap<String, Any?>>(uris.size)
            for (uri in uris) {
                try {
                    payload.add(
                        hashMapOf(
                            "fileName" to fileNameFor(uri),
                            "sourcePath" to uri.toString(),
                            "declaredSize" to probe(uri).coerceAtLeast(0),
                            "mimeType" to contentResolver.getType(uri)?.lowercase(),
                        ),
                    )
                } catch (_: SecurityException) {
                    continue
                }
            }
            if (payload.isEmpty()) {
                pending.error(
                    "pick_failed",
                    "Could not read any selected audio file.",
                    null,
                )
            } else {
                pending.success(payload)
            }
        } catch (error: Exception) {
            pending.error("pick_failed", error.message, null)
        }
    }

    private fun pickAudio(result: MethodChannel.Result) {
        if (pendingPick != null) {
            result.error("already_picking", "A file picker is already open.", null)
            return
        }
        pendingPick = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "audio/*"
            putExtra(
                Intent.EXTRA_MIME_TYPES,
                arrayOf("audio/mpeg", "audio/mp4", "audio/x-m4a"),
            )
            putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
        }
        @Suppress("DEPRECATION")
        startActivityForResult(intent, REQUEST_PICK_AUDIO)
    }

    private fun fileNameFor(uri: Uri): String {
        var name: String? = null
        contentResolver.query(
            uri,
            arrayOf(OpenableColumns.DISPLAY_NAME),
            null,
            null,
            null,
        )?.use { cursor ->
            if (cursor.moveToFirst()) {
                val index = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                if (index >= 0) name = cursor.getString(index)
            }
        }
        val resolved = name?.takeIf { it.isNotBlank() }
            ?: uri.lastPathSegment?.substringAfterLast('/')
            ?: "audio.mp3"
        val lower = resolved.lowercase()
        if (lower.endsWith(".mp3") || lower.endsWith(".m4a")) return resolved
        val mime = contentResolver.getType(uri)?.lowercase()
        val extension = when (mime) {
            "audio/mpeg", "audio/mp3" -> ".mp3"
            "audio/mp4", "audio/x-m4a" -> ".m4a"
            else -> ""
        }
        return resolved + extension
    }

    private fun persist(uri: Uri) {
        contentResolver.takePersistableUriPermission(
            uri,
            Intent.FLAG_GRANT_READ_URI_PERMISSION,
        )
    }

    private fun probe(uri: Uri): Long {
        contentResolver.query(
            uri,
            arrayOf(OpenableColumns.SIZE),
            null,
            null,
            null,
        )?.use { cursor ->
            if (cursor.moveToFirst()) {
                val index = cursor.getColumnIndex(OpenableColumns.SIZE)
                if (index >= 0 && !cursor.isNull(index)) {
                    val size = cursor.getLong(index)
                    if (size > 0) return size
                }
            }
        }
        contentResolver.openAssetFileDescriptor(uri, "r")?.use { descriptor ->
            val length = descriptor.length
            if (length > 0) return length
        }
        contentResolver.openInputStream(uri)?.use { input ->
            return if (input.read() < 0) 0 else 1
        }
        return -1
    }

    private fun release(uri: Uri) {
        try {
            contentResolver.releasePersistableUriPermission(
                uri,
                Intent.FLAG_GRANT_READ_URI_PERMISSION,
            )
        } catch (_: SecurityException) {
            // Permission may already have been released.
        }
    }

    private fun isPrivacyIntent(intent: Intent?): Boolean =
        intent?.action == "androidx.health.ACTION_SHOW_PERMISSIONS_RATIONALE" ||
            intent?.action == "android.intent.action.VIEW_PERMISSION_USAGE"

    companion object {
        private const val REQUEST_PICK_AUDIO = 7101
    }
}
