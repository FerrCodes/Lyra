package com.ferrriiidev.lyra

import android.content.ContentUris
import android.content.Intent
import android.provider.MediaStore
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : AudioServiceActivity() {
    private val CHANNEL = "com.lyra/media_store"
    private val PICK_IMAGE_CHANNEL = "com.lyra/pick_image"
    private var pendingImageResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 1. KANAL ASLI MILIKMU (Jangan diubah)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getSongs") {
                try {
                    val songs = getSongsFromMediaStore()
                    result.success(songs)
                } catch (e: Exception) {
                    result.error("MEDIASTORE_ERROR", "Gagal membaca lagu: ${e.message}", null)
                }
            } else {
                result.notImplemented()
            }
        }

        // 2. KANAL BARU: Memaksa buka Samsung Gallery Layar Penuh
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PICK_IMAGE_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "pickImage") {
                pendingImageResult = result
                // Intent ini memaksa aplikasi Galeri bawaan HP (Samsung Gallery) terbuka
                val intent = Intent(Intent.ACTION_PICK, MediaStore.Images.Media.EXTERNAL_CONTENT_URI)
                intent.type = "image/*"
                startActivityForResult(intent, 1001)
            } else {
                result.notImplemented()
            }
        }
    }

    // Menangkap hasil dari Galeri Samsung
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == 1001) {
            if (resultCode == RESULT_OK && data != null) {
                val uri = data.data
                if (uri != null) {
                    try {
                        // 1. GANTI cacheDir MENJADI filesDir (Agar permanen)
                        val file = File(filesDir, "playlist_cover_${System.currentTimeMillis()}.jpg")
                        
                        // 2. GUNAKAN .use {} (Otomatis menutup stream meskipun error)
                        contentResolver.openInputStream(uri)?.use { inputStream ->
                            FileOutputStream(file).use { outputStream ->
                                inputStream.copyTo(outputStream)
                            }
                        }
                        
                        pendingImageResult?.success(file.absolutePath)
                    } catch (e: Exception) {
                        pendingImageResult?.error("PICK_ERROR", e.message, null)
                    }
                } else {
                    pendingImageResult?.success(null)
                }
            } else {
                pendingImageResult?.success(null) // User membatalkan
            }
            pendingImageResult = null
        }
    }

    // 3. FUNGSI PEMINDAI LAGU MILIKMU (Tetap utuh)
    private fun getSongsFromMediaStore(): List<Map<String, Any>> {
        val songs = mutableListOf<Map<String, Any>>()
        val collection = MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
        val projection = arrayOf(
            MediaStore.Audio.Media._ID,
            MediaStore.Audio.Media.TITLE,
            MediaStore.Audio.Media.ARTIST,
            MediaStore.Audio.Media.ALBUM,
            MediaStore.Audio.Media.DURATION,
            MediaStore.Audio.Media.DATA,
            MediaStore.Audio.Media.ALBUM_ID
        )
        
        val selection = "${MediaStore.Audio.Media.IS_MUSIC} != 0 AND ${MediaStore.Audio.Media.DURATION} > 0"
        val sortOrder = "${MediaStore.Audio.Media.TITLE} ASC"

        contentResolver.query(collection, projection, selection, null, sortOrder)?.use { cursor ->
            val idColumn = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media._ID)
            val titleColumn = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.TITLE)
            val artistColumn = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.ARTIST)
            val albumColumn = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.ALBUM)
            val durationColumn = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.DURATION)
            val dataColumn = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.DATA)
            val albumIdColumn = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.ALBUM_ID)

            while (cursor.moveToNext()) {
                val id = cursor.getLong(idColumn)
                val title = cursor.getString(titleColumn) ?: "Unknown Title"
                val artist = cursor.getString(artistColumn) ?: "Unknown Artist"
                val album = cursor.getString(albumColumn) ?: "Unknown Album"
                val duration = cursor.getLong(durationColumn)
                val data = cursor.getString(dataColumn)
                val albumId = cursor.getLong(albumIdColumn)

                songs.add(mapOf(
                    "id" to id.toString(),
                    "title" to title,
                    "artist" to artist,
                    "album" to album,
                    "duration" to duration,
                    "path" to data,
                    "albumId" to albumId.toString()
                ))
            }
        }
        return songs
    }
}