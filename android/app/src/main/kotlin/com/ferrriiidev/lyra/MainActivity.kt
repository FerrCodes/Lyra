package com.ferrriiidev.lyra

import android.content.ContentUris
import android.content.Intent
import android.media.MediaScannerConnection
import android.net.Uri
import android.provider.MediaStore
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.jaudiotagger.audio.AudioFileIO
import org.jaudiotagger.tag.FieldKey
import com.mpatric.mp3agic.Mp3File
import com.mpatric.mp3agic.ID3v2
import com.mpatric.mp3agic.ID3v24Tag
import java.io.FileInputStream
import java.io.File
import java.io.FileOutputStream

class MainActivity : AudioServiceActivity() {
    private val CHANNEL = "com.lyra/media_store"
    private val PICK_IMAGE_CHANNEL = "com.lyra/pick_image"
    
    private var pendingUpdateUri: Uri? = null
    private var pendingUpdateValues: android.content.ContentValues? = null
    private var pendingUpdateResult: MethodChannel.Result? = null
    private var pendingImageResult: MethodChannel.Result? = null
    private var permissionResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getSongs") {
                try {
                    result.success(getSongsFromMediaStore())
                } catch (e: Exception) {
                    result.error("MEDIASTORE_ERROR", "Gagal membaca lagu: ${e.message}", null)
                }
            } else if (call.method == "requestWritePermission") {
                val id = call.argument<String>("id")
                if (id == null) {
                    result.error("INVALID_ARGS", "ID lagu tidak valid.", null)
                    return@setMethodCallHandler
                }
                val uri = ContentUris.withAppendedId(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, id.toLong())
                permissionResult = result
                
                if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.R) {
                    val intentSender = MediaStore.createWriteRequest(contentResolver, listOf(uri)).intentSender
                    startIntentSenderForResult(intentSender, 2002, null, 0, 0, 0)
                } else {
                    permissionResult?.success(true)
                }
            } else if (call.method == "updateSongMetadata") {
                val id = call.argument<String>("id")
                if (id == null) {
                    result.error("INVALID_ARGS", "ID lagu tidak valid.", null)
                    return@setMethodCallHandler
                }
                val uri = ContentUris.withAppendedId(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, id.toLong())
                pendingUpdateUri = uri
                pendingUpdateResult = result
                pendingUpdateValues = android.content.ContentValues().apply {
                    put(MediaStore.Audio.Media.TITLE, call.argument<String>("title"))
                    put(MediaStore.Audio.Media.ARTIST, call.argument<String>("artist"))
                    put(MediaStore.Audio.Media.ALBUM, call.argument<String>("album"))
                }
                
                executeMetadataUpdate()
            } else if (call.method == "updateAlbumCover") {
                val id = call.argument<String>("id")
                val imagePath = call.argument<String>("imagePath")
                if (id != null && imagePath != null) {
                    Thread {
                        val uri = ContentUris.withAppendedId(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, id.toLong())
                        val success = writeCoverToFile(uri, imagePath)
                        runOnUiThread {
                            if (success) {
                                val filePath = getPathFromUri(uri)
                                if (filePath != null) {
                                    MediaScannerConnection.scanFile(this, arrayOf(filePath), null) { _, _ ->
                                        result.success(true)
                                    }
                                } else { result.success(true) }
                            } else {
                                result.error("COVER_FAILED", "Gagal menyimpan cover.", null)
                            }
                        }
                    }.start()
                }
            } else {
                result.notImplemented()
            }
        }

        // KANAL GAMBAR (JANGAN DIUBAH)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PICK_IMAGE_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "pickImage") {
                pendingImageResult = result
                val intent = Intent(Intent.ACTION_PICK, MediaStore.Images.Media.EXTERNAL_CONTENT_URI)
                intent.type = "image/*"
                startActivityForResult(intent, 1001)
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == 1001) {
            if (resultCode == RESULT_OK && data?.data != null) {
                try {
                    val file = File(filesDir, "playlist_cover_${System.currentTimeMillis()}.jpg")
                    contentResolver.openInputStream(data.data!!)?.use { input ->
                        FileOutputStream(file).use { output -> input.copyTo(output) }
                    }
                    pendingImageResult?.success(file.absolutePath)
                } catch (e: Exception) {
                    pendingImageResult?.error("PICK_ERROR", e.message, null)
                }
            } else {
                pendingImageResult?.success(null)
            }
            pendingImageResult = null
        } else if (requestCode == 2002) {
            if (resultCode == RESULT_OK) {
                permissionResult?.success(true)
            } else {
                permissionResult?.error("PERMISSION_DENIED", "Izin ditolak.", null)
            }
            permissionResult = null
        }
    }

    private fun executeMetadataUpdate() {
        Thread {
            try {
                val filePath = getPathFromUri(pendingUpdateUri!!)
                if (filePath != null) {
                    val success = writeTagsToFile(pendingUpdateUri!!, filePath, pendingUpdateValues!!)
                    runOnUiThread {
                        if (success) {
                            MediaScannerConnection.scanFile(this, arrayOf(filePath), null) { _, _ ->
                                pendingUpdateResult?.success(true)
                            }
                        } else {
                            pendingUpdateResult?.error("UPDATE_FAILED", "Gagal menulis tag.", null)
                        }
                    }
                } else {
                    runOnUiThread { pendingUpdateResult?.error("PATH_ERROR", "Path tidak ditemukan.", null) }
                }
            } catch (e: Exception) {
                runOnUiThread { pendingUpdateResult?.error("UPDATE_ERROR", e.message, null) }
            }
        }.start()
    }

    private fun getPathFromUri(uri: Uri): String? {
        val projection = arrayOf(MediaStore.Audio.Media.DATA)
        contentResolver.query(uri, projection, null, null, null)?.use { cursor ->
            if (cursor.moveToFirst()) return cursor.getString(cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.DATA))
        }
        return null
    }

    // MENGAMBIL EKSTENSI FILE DARI URI (Sesuai saran GPT)
    private fun getFileExtension(uri: Uri): String {
        var extension = "mp3"
        val projection = arrayOf(MediaStore.MediaColumns.DISPLAY_NAME)
        contentResolver.query(uri, projection, null, null, null)?.use { cursor ->
            if (cursor.moveToFirst()) {
                val displayName = cursor.getString(cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.DISPLAY_NAME))
                if (displayName != null && displayName.contains(".")) {
                    extension = displayName.substringAfterLast(".")
                }
            }
        }
        return extension
    }

    private fun writeTagsToFile(uri: Uri, path: String, values: android.content.ContentValues): Boolean {
        val originalFile = File(path)
        if (!originalFile.exists()) return false
        val tempFile = File(cacheDir, "temp_tag_${System.currentTimeMillis()}.${originalFile.extension}")
        return try {
            contentResolver.openInputStream(uri)?.use { input -> tempFile.outputStream().use { input.copyTo(it) } }
            
            val audioFile = AudioFileIO.read(tempFile)
            val tag = audioFile.tagOrCreateAndSetDefault
            values.getAsString(MediaStore.Audio.Media.TITLE)?.let { tag.setField(FieldKey.TITLE, it) }
            values.getAsString(MediaStore.Audio.Media.ARTIST)?.let { tag.setField(FieldKey.ARTIST, it) }
            values.getAsString(MediaStore.Audio.Media.ALBUM)?.let { tag.setField(FieldKey.ALBUM, it) }
            audioFile.commit()

            contentResolver.openOutputStream(uri, "wt")?.use { output -> tempFile.inputStream().use { input -> input.copyTo(output) } }
            true
        } catch (e: Exception) {
            e.printStackTrace()
            false
        } finally {
            if (tempFile.exists()) tempFile.delete()
        }
    }

    // SESUAI SARAN GPT
    private fun writeCoverToFile(uri: Uri, imagePath: String): Boolean {
        val ext = getFileExtension(uri)
        val tempFile = File(cacheDir, "temp_cover_${System.currentTimeMillis()}.$ext")
        
        return try {
            // 1. Salin file asli ke cache
            contentResolver.openInputStream(uri)?.use { input -> 
                tempFile.outputStream().use { input.copyTo(it) } 
            } ?: return false

            // 2. Baca file dengan Mp3agic
            val mp3file = Mp3File(tempFile)
            
            // 3. Gunakan ID3v24Tag
            val id3v2Tag = if (mp3file.hasId3v2Tag()) {
                mp3file.id3v2Tag
            } else {
                val newTag = ID3v24Tag() // <-- MENGGUNAKAN ID3v24Tag
                mp3file.id3v2Tag = newTag
                newTag
            }

            // 4. Masukkan gambar menggunakan method setAlbumImage()
            val imageData = File(imagePath).readBytes()
            id3v2Tag.setAlbumImage(imageData, "image/jpeg")

            // 5. Simpan ke file temp baru
            val finalTempFile = File(cacheDir, "final_cover_${System.currentTimeMillis()}.$ext")
            mp3file.save(finalTempFile.absolutePath)

            // 6. Tulis kembali ke file asli via URI
            contentResolver.openOutputStream(uri, "wt")?.use { output -> 
                finalTempFile.inputStream().use { input -> input.copyTo(output) } 
            }

            if (finalTempFile.exists()) finalTempFile.delete()
            
            true
        } catch (e: Exception) {
            e.printStackTrace()
            false
        } finally {
            // 7. Hapus file temp awal
            if (tempFile.exists()) tempFile.delete()
        }
    }

    private fun getSongsFromMediaStore(): List<Map<String, Any>> {
        val songs = mutableListOf<Map<String, Any>>()
        val collection = MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
        val projection = arrayOf(MediaStore.Audio.Media._ID, MediaStore.Audio.Media.TITLE, MediaStore.Audio.Media.ARTIST, MediaStore.Audio.Media.ALBUM, MediaStore.Audio.Media.DURATION, MediaStore.Audio.Media.DATA, MediaStore.Audio.Media.ALBUM_ID)
        val selection = "${MediaStore.Audio.Media.IS_MUSIC} != 0 AND ${MediaStore.Audio.Media.DURATION} > 0"
        contentResolver.query(collection, projection, selection, null, "${MediaStore.Audio.Media.TITLE} ASC")?.use { cursor ->
            while (cursor.moveToNext()) {
                songs.add(mapOf(
                    "id" to cursor.getLong(cursor.getColumnIndexOrThrow(MediaStore.Audio.Media._ID)).toString(),
                    "title" to (cursor.getString(cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.TITLE)) ?: "Unknown"),
                    "artist" to (cursor.getString(cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.ARTIST)) ?: "Unknown"),
                    "album" to (cursor.getString(cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.ALBUM)) ?: "Unknown"),
                    "duration" to cursor.getLong(cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.DURATION)),
                    "path" to cursor.getString(cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.DATA)),
                    "albumId" to cursor.getLong(cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.ALBUM_ID)).toString()
                ))
            }
        }
        return songs
    }
}