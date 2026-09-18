package com.coldopen.app.share

import android.content.Context
import android.content.Intent
import android.net.Uri

/**
 * Direct-to-Instagram-Stories sharing, bypassing the generic OS share
 * sheet — implemented against Meta's documented mechanism: a specific
 * Intent action Instagram's own app listens for.
 * (developers.facebook.com/docs/instagram-platform/sharing-to-stories)
 *
 * **This can't actually work yet, and can't be made to from here.**
 * Instagram has required a registered Facebook App ID since January
 * 2023 — passed as `source_application` — and rejects the share
 * without one. That registration is an interactive step tied to a real
 * Meta for Developers account, the same shape of gap as iOS's App Group
 * identifier: this writes the real, doc-grounded integration, but
 * [FACEBOOK_APP_ID] stays a placeholder until someone actually
 * registers an app and fills it in. [isAvailable] is `false` while it's
 * blank, so [ShareActivity] safely falls back to the generic
 * `ACTION_SEND` share sheet rather than attempting a share Instagram
 * will just reject.
 */
object InstagramStorySharing {
    /** Set this to the real numeric Facebook App ID once one exists
     *  (developers.facebook.com → your app → Settings → Basic). Left
     *  blank deliberately — see the type's doc comment. */
    private const val FACEBOOK_APP_ID = ""

    private const val INSTAGRAM_PACKAGE = "com.instagram.android"
    private const val ADD_TO_STORY_ACTION = "com.instagram.share.ADD_TO_STORY"

    fun isAvailable(context: Context): Boolean {
        if (FACEBOOK_APP_ID.isEmpty()) return false
        val probeIntent = Intent(ADD_TO_STORY_ACTION)
        return context.packageManager.resolveActivity(probeIntent, 0) != null
    }

    /**
     * Launches Instagram's Stories composer with [imageUri] as the
     * background. Returns `false` (having done nothing) if [isAvailable]
     * is `false` — the caller should fall back to the generic share
     * sheet in that case, not treat it as an error.
     */
    fun share(context: Context, imageUri: Uri): Boolean {
        if (!isAvailable(context)) return false

        val intent = Intent(ADD_TO_STORY_ACTION).apply {
            setDataAndType(imageUri, "image/png")
            putExtra("source_application", FACEBOOK_APP_ID)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        // Instagram isn't launched through the standard chooser flow here,
        // so the read grant on the intent alone isn't enough — it needs an
        // explicit grant to Instagram's package too.
        context.grantUriPermission(INSTAGRAM_PACKAGE, imageUri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
        context.startActivity(intent)
        return true
    }
}
