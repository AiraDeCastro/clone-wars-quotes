package com.coldopen.app.share

import android.app.Activity
import android.content.Intent
import android.graphics.Bitmap
import android.net.Uri
import android.os.Bundle
import androidx.core.content.FileProvider
import com.coldopen.core.Quote
import java.io.File
import java.io.FileOutputStream

/**
 * Invisible activity launched by the widget's share tap (Glance's
 * `actionStartActivity` in `ColdOpenWidget.kt` — a widget's own composable
 * click handler can't present a system share sheet directly, only start an
 * Activity or run a background action). Renders the card and hands it to
 * the OS share sheet via `ACTION_SEND`, then finishes immediately so the
 * user never actually sees an app screen — the Android equivalent of iOS's
 * widget-tap-deep-link-to-share-sheet flow, reached through an Activity
 * instead of a URL scheme since Glance can pass typed extras to an Activity
 * it starts directly. Declared with a translucent/no-display theme in
 * AndroidManifest.xml so there's no visible blank screen before the share
 * sheet appears.
 */
class ShareActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val quote = quoteFromIntent(intent)
        if (quote == null) {
            finish()
            return
        }

        val bitmap = ShareCardRenderer.render(quote, ShareCardSize.STORY_WIDTH, ShareCardSize.STORY_HEIGHT)
        val uri = saveToShareableFile(bitmap)
        if (uri == null) {
            finish()
            return
        }

        val sendIntent = Intent(Intent.ACTION_SEND).apply {
            type = "image/png"
            putExtra(Intent.EXTRA_STREAM, uri)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        startActivity(Intent.createChooser(sendIntent, null))
        finish()
    }

    private fun quoteFromIntent(intent: Intent): Quote? {
        val text = intent.getStringExtra(ShareIntentKeys.TEXT) ?: return null
        val episodeTitle = intent.getStringExtra(ShareIntentKeys.EPISODE_TITLE) ?: return null
        val arc = intent.getStringExtra(ShareIntentKeys.ARC) ?: return null
        val season = intent.getIntExtra(ShareIntentKeys.SEASON, -1)
        val episode = intent.getIntExtra(ShareIntentKeys.EPISODE, -1)
        if (season < 1 || episode < 1) return null
        return Quote(text = text, episodeTitle = episodeTitle, season = season, episode = episode, arc = arc)
    }

    /** Writes the rendered card to the app's cache dir and returns a `content://` URI another app can actually read — a raw file:// path or in-memory bitmap can't cross the ACTION_SEND boundary under scoped storage. */
    private fun saveToShareableFile(bitmap: Bitmap): Uri? = runCatching {
        val shareDir = File(cacheDir, "share_cards").apply { mkdirs() }
        val file = File(shareDir, "cold_open_share.png")
        FileOutputStream(file).use { out -> bitmap.compress(Bitmap.CompressFormat.PNG, 100, out) }
        FileProvider.getUriForFile(this, "$packageName.fileprovider", file)
    }.getOrNull()
}
