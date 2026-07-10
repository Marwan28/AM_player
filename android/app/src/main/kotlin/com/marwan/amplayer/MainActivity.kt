package com.marwan.amplayer

import android.content.ContentUris
import android.content.res.Configuration
import android.os.Build
import android.provider.MediaStore
import cl.puntito.simple_pip_mode.PipCallbackHelper
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity: AudioServiceActivity() {
    private val pipCallbackHelper = PipCallbackHelper()
    private val mediaStoreChannel = "am_player/media_store"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        pipCallbackHelper.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            mediaStoreChannel
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "queryAudio" -> Thread {
                    try {
                        val songs = queryAudioFromMediaStore()
                        runOnUiThread { result.success(songs) }
                    } catch (error: Exception) {
                        runOnUiThread {
                            result.error(
                                "MEDIA_STORE_QUERY_FAILED",
                                error.message,
                                null
                            )
                        }
                    }
                }.start()
                "queryVideos" -> Thread {
                    try {
                        val videos = queryVideosFromMediaStore()
                        runOnUiThread { result.success(videos) }
                    } catch (error: Exception) {
                        runOnUiThread {
                            result.error(
                                "MEDIA_STORE_QUERY_FAILED",
                                error.message,
                                null
                            )
                        }
                    }
                }.start()
                "audioLibrarySignature" -> Thread {
                    try {
                        val signature = queryAudioLibrarySignature()
                        runOnUiThread { result.success(signature) }
                    } catch (error: Exception) {
                        runOnUiThread {
                            result.error(
                                "MEDIA_STORE_QUERY_FAILED",
                                error.message,
                                null
                            )
                        }
                    }
                }.start()
                "videoLibrarySignature" -> Thread {
                    try {
                        val signature = queryVideoLibrarySignature()
                        runOnUiThread { result.success(signature) }
                    } catch (error: Exception) {
                        runOnUiThread {
                            result.error(
                                "MEDIA_STORE_QUERY_FAILED",
                                error.message,
                                null
                            )
                        }
                    }
                }.start()
                else -> result.notImplemented()
            }
        }
    }

    override fun onPictureInPictureModeChanged(
        isInPictureInPictureMode: Boolean,
        newConfig: Configuration?
    ) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)
        pipCallbackHelper.onPictureInPictureModeChanged(isInPictureInPictureMode)
    }

    private fun queryAudioFromMediaStore(): List<Map<String, Any?>> {
        val audioUri = MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
        val bucketColumn = "bucket_display_name"
        val relativePathColumn = "relative_path"
        val projection = mutableListOf(
            MediaStore.Audio.Media._ID,
            MediaStore.Audio.Media.TITLE,
            MediaStore.Audio.Media.DISPLAY_NAME,
            MediaStore.Audio.Media.DATA,
            MediaStore.Audio.Media.DURATION,
            MediaStore.Audio.Media.DATE_MODIFIED,
            MediaStore.Audio.Media.SIZE,
            MediaStore.Audio.Media.ARTIST,
            bucketColumn
        )
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            projection.add(relativePathColumn)
        }
        val songs = mutableListOf<Map<String, Any?>>()

        contentResolver.query(
            audioUri,
            projection.toTypedArray(),
            null,
            null,
            "${MediaStore.Audio.Media.DATE_MODIFIED} DESC"
        )?.use { cursor ->
            val idIndex = cursor.getColumnIndex(MediaStore.Audio.Media._ID)
            val titleIndex = cursor.getColumnIndex(MediaStore.Audio.Media.TITLE)
            val displayNameIndex = cursor.getColumnIndex(MediaStore.Audio.Media.DISPLAY_NAME)
            val dataIndex = cursor.getColumnIndex(MediaStore.Audio.Media.DATA)
            val durationIndex = cursor.getColumnIndex(MediaStore.Audio.Media.DURATION)
            val modifiedIndex = cursor.getColumnIndex(MediaStore.Audio.Media.DATE_MODIFIED)
            val sizeIndex = cursor.getColumnIndex(MediaStore.Audio.Media.SIZE)
            val artistIndex = cursor.getColumnIndex(MediaStore.Audio.Media.ARTIST)
            val bucketIndex = cursor.getColumnIndex(bucketColumn)
            val relativePathIndex = cursor.getColumnIndex(relativePathColumn)

            while (cursor.moveToNext()) {
                val id = cursor.safeLong(idIndex)
                val contentUri = ContentUris.withAppendedId(audioUri, id).toString()
                val dataPath = cursor.safeString(dataIndex)
                val path = if (dataPath.isNullOrBlank()) contentUri else dataPath
                val title = cursor.safeString(titleIndex)
                    ?: cursor.safeString(displayNameIndex)?.substringBeforeLast(".")
                    ?: File(path).nameWithoutExtension
                val folderPath = when {
                    path.startsWith("content://") -> cursor.safeString(relativePathIndex) ?: "Audio"
                    else -> File(path).parent ?: cursor.safeString(relativePathIndex) ?: "Audio"
                }
                val folderName = cursor.safeString(bucketIndex)
                    ?: File(folderPath).name.ifBlank { "Audio" }

                songs.add(
                    mapOf(
                        "id" to id.toString(),
                        "title" to title,
                        "path" to path,
                        "uri" to contentUri,
                        "folderId" to folderPath,
                        "folderName" to folderName,
                        "durationMs" to cursor.safeLong(durationIndex),
                        "modifiedMs" to cursor.safeLong(modifiedIndex) * 1000L,
                        "sizeBytes" to cursor.safeLong(sizeIndex),
                        "artist" to cursor.safeString(artistIndex)
                    )
                )
            }
        }

        return songs
    }

    private fun queryAudioLibrarySignature(): String {
        val audioUri = MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
        val projection = arrayOf(
            MediaStore.Audio.Media._ID,
            MediaStore.Audio.Media.DATE_MODIFIED,
            MediaStore.Audio.Media.SIZE,
            MediaStore.Audio.Media.DURATION
        )
        var count = 0L
        var latestModified = 0L
        var fingerprint = 0L

        contentResolver.query(
            audioUri,
            projection,
            null,
            null,
            "${MediaStore.Audio.Media._ID} ASC"
        )?.use { cursor ->
            val idIndex = cursor.getColumnIndex(MediaStore.Audio.Media._ID)
            val modifiedIndex =
                cursor.getColumnIndex(MediaStore.Audio.Media.DATE_MODIFIED)
            val sizeIndex = cursor.getColumnIndex(MediaStore.Audio.Media.SIZE)
            val durationIndex = cursor.getColumnIndex(MediaStore.Audio.Media.DURATION)

            while (cursor.moveToNext()) {
                val id = cursor.safeLong(idIndex)
                val modified = cursor.safeLong(modifiedIndex)
                val size = cursor.safeLong(sizeIndex)
                val duration = cursor.safeLong(durationIndex)
                count += 1
                latestModified = maxOf(latestModified, modified)
                fingerprint = fingerprint xor
                    (id * 31L + modified * 17L + size * 13L + duration)
            }
        }

        return "$count:$latestModified:$fingerprint"
    }

    private fun queryVideosFromMediaStore(): List<Map<String, Any?>> {
        val videoUri = MediaStore.Video.Media.EXTERNAL_CONTENT_URI
        val projection = arrayOf(
            MediaStore.Video.Media._ID,
            MediaStore.Video.Media.DISPLAY_NAME,
            MediaStore.Video.Media.DATA,
            MediaStore.Video.Media.DURATION,
            MediaStore.Video.Media.DATE_MODIFIED,
            MediaStore.Video.Media.SIZE,
            MediaStore.Video.Media.WIDTH,
            MediaStore.Video.Media.HEIGHT,
            MediaStore.Video.Media.BUCKET_ID,
            MediaStore.Video.Media.BUCKET_DISPLAY_NAME
        )
        val videos = mutableListOf<Map<String, Any?>>()

        contentResolver.query(
            videoUri,
            projection,
            null,
            null,
            "${MediaStore.Video.Media.DATE_MODIFIED} DESC"
        )?.use { cursor ->
            val idIndex = cursor.getColumnIndex(MediaStore.Video.Media._ID)
            val nameIndex =
                cursor.getColumnIndex(MediaStore.Video.Media.DISPLAY_NAME)
            val dataIndex = cursor.getColumnIndex(MediaStore.Video.Media.DATA)
            val durationIndex = cursor.getColumnIndex(MediaStore.Video.Media.DURATION)
            val modifiedIndex =
                cursor.getColumnIndex(MediaStore.Video.Media.DATE_MODIFIED)
            val sizeIndex = cursor.getColumnIndex(MediaStore.Video.Media.SIZE)
            val widthIndex = cursor.getColumnIndex(MediaStore.Video.Media.WIDTH)
            val heightIndex = cursor.getColumnIndex(MediaStore.Video.Media.HEIGHT)
            val bucketIdIndex = cursor.getColumnIndex(MediaStore.Video.Media.BUCKET_ID)
            val bucketNameIndex =
                cursor.getColumnIndex(MediaStore.Video.Media.BUCKET_DISPLAY_NAME)

            while (cursor.moveToNext()) {
                val id = cursor.safeLong(idIndex)
                val contentUri = ContentUris.withAppendedId(videoUri, id).toString()
                val dataPath = cursor.safeString(dataIndex)
                val path = if (dataPath.isNullOrBlank()) contentUri else dataPath
                val title = (cursor.safeString(nameIndex) ?: File(path).name)
                    .ifBlank { "Video" }
                val folderPath = if (path.startsWith("content://")) {
                    "Videos"
                } else {
                    File(path).parent ?: "Videos"
                }
                val folderId = cursor.safeString(bucketIdIndex) ?: folderPath
                val folderName = cursor.safeString(bucketNameIndex)
                    ?: File(folderPath).name.ifBlank { "Videos" }

                videos.add(
                    mapOf(
                        "assetId" to id.toString(),
                        "title" to title,
                        "path" to path,
                        "folderId" to folderId,
                        "folderName" to folderName,
                        "durationMs" to cursor.safeLong(durationIndex),
                        "modifiedMs" to cursor.safeLong(modifiedIndex) * 1000L,
                        "sizeBytes" to cursor.safeLong(sizeIndex),
                        "width" to cursor.safeLong(widthIndex),
                        "height" to cursor.safeLong(heightIndex)
                    )
                )
            }
        }

        return videos
    }

    private fun queryVideoLibrarySignature(): String {
        val videoUri = MediaStore.Video.Media.EXTERNAL_CONTENT_URI
        val projection = arrayOf(
            MediaStore.Video.Media._ID,
            MediaStore.Video.Media.DATE_MODIFIED,
            MediaStore.Video.Media.SIZE,
            MediaStore.Video.Media.DURATION
        )
        var count = 0L
        var latestModified = 0L
        var fingerprint = 0L

        contentResolver.query(
            videoUri,
            projection,
            null,
            null,
            "${MediaStore.Video.Media._ID} ASC"
        )?.use { cursor ->
            val idIndex = cursor.getColumnIndex(MediaStore.Video.Media._ID)
            val modifiedIndex =
                cursor.getColumnIndex(MediaStore.Video.Media.DATE_MODIFIED)
            val sizeIndex = cursor.getColumnIndex(MediaStore.Video.Media.SIZE)
            val durationIndex = cursor.getColumnIndex(MediaStore.Video.Media.DURATION)

            while (cursor.moveToNext()) {
                val id = cursor.safeLong(idIndex)
                val modified = cursor.safeLong(modifiedIndex)
                val size = cursor.safeLong(sizeIndex)
                val duration = cursor.safeLong(durationIndex)
                count += 1
                latestModified = maxOf(latestModified, modified)
                fingerprint = fingerprint xor
                    (id * 31L + modified * 17L + size * 13L + duration)
            }
        }

        return "$count:$latestModified:$fingerprint"
    }

    private fun android.database.Cursor.safeString(index: Int): String? {
        if (index < 0 || isNull(index)) return null
        return getString(index)
    }

    private fun android.database.Cursor.safeLong(index: Int): Long {
        if (index < 0 || isNull(index)) return 0L
        return getLong(index)
    }
}
