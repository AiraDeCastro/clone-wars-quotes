package com.coldopen.app

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.coldopen.core.Quote
import com.coldopen.core.QuoteCorpus

/**
 * Placeholder companion screen — just enough to prove the app can load the
 * shared corpus via :core. The real searchable browser is a P1 task
 * (TASKS.md M3).
 */
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            MaterialTheme {
                Surface {
                    ColdOpenPlaceholderScreen(quote = loadFirstQuote())
                }
            }
        }
    }

    private fun loadFirstQuote(): Quote? = runCatching {
        assets.open("quotes.json").use { QuoteCorpus.load(it) }.firstOrNull()
    }.getOrNull()
}

@Composable
private fun ColdOpenPlaceholderScreen(quote: Quote?) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(24.dp),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        if (quote != null) {
            Text(text = quote.text, style = MaterialTheme.typography.titleMedium)
            Text(
                text = "${quote.episodeTitle} — S${quote.season}E${quote.episode}",
                style = MaterialTheme.typography.bodySmall,
            )
        } else {
            Text(text = "Failed to load corpus.")
        }
    }
}
