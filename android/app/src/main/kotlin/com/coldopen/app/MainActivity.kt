package com.coldopen.app

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp
import com.coldopen.core.Quote
import com.coldopen.core.QuoteCorpus

/**
 * Companion quote browser (TASKS.md M3) — searchable by episode title,
 * arc, or the line itself, with a favorite toggle per row (the "in-app"
 * option for TASKS.md M3's favorite/pin item — a widget long-press isn't
 * really a custom action WidgetKit/Glance exposes). Loads the full corpus
 * once; filtering is done in-memory since 129 quotes is trivially small,
 * no need for anything fancier than a plain `contains(ignoreCase = true)`.
 */
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            MaterialTheme {
                Surface {
                    ColdOpenBrowserScreen(quotes = loadQuotes())
                }
            }
        }
    }

    private fun loadQuotes(): List<Quote> = runCatching {
        assets.open("quotes.json").use { QuoteCorpus.load(it) }
    }.getOrDefault(emptyList())
}

@Composable
private fun ColdOpenBrowserScreen(quotes: List<Quote>) {
    val context = LocalContext.current
    var query by remember { mutableStateOf("") }
    var favoriteTexts by remember { mutableStateOf(FavoritesStore.favoriteTexts(context)) }
    val filtered = remember(quotes, query) {
        if (query.isBlank()) {
            quotes
        } else {
            quotes.filter { quote ->
                quote.episodeTitle.contains(query, ignoreCase = true) ||
                    quote.arc.contains(query, ignoreCase = true) ||
                    quote.text.contains(query, ignoreCase = true)
            }
        }
    }

    Column(modifier = Modifier.fillMaxSize().padding(16.dp)) {
        OutlinedTextField(
            value = query,
            onValueChange = { query = it },
            label = { Text("Search by episode, arc, or line") },
            modifier = Modifier.fillMaxWidth(),
        )
        when {
            quotes.isEmpty() -> Text(text = "Failed to load corpus.", modifier = Modifier.padding(top = 24.dp))
            filtered.isEmpty() -> Text(text = "No quotes match \"$query\".", modifier = Modifier.padding(top = 24.dp))
            else -> LazyColumn {
                items(filtered, key = { it.text }) { quote ->
                    QuoteRow(
                        quote = quote,
                        isFavorite = favoriteTexts.contains(quote.text),
                        onToggleFavorite = {
                            FavoritesStore.toggleFavorite(context, quote)
                            favoriteTexts = FavoritesStore.favoriteTexts(context)
                        },
                    )
                }
            }
        }
    }
}

@Composable
private fun QuoteRow(quote: Quote, isFavorite: Boolean, onToggleFavorite: () -> Unit) {
    Row(modifier = Modifier.fillMaxWidth().padding(vertical = 12.dp)) {
        Column(modifier = Modifier.weight(1f)) {
            Text(text = quote.text, style = MaterialTheme.typography.bodyLarge)
            Text(
                text = "${quote.episodeTitle} · S${quote.season}E${quote.episode} · ${quote.arc}",
                style = MaterialTheme.typography.bodySmall,
            )
        }
        Text(
            text = if (isFavorite) "★" else "☆",
            style = MaterialTheme.typography.titleLarge,
            modifier = Modifier
                .padding(start = 8.dp)
                .clickable(onClick = onToggleFavorite)
                .semantics {
                    contentDescription = if (isFavorite) "Remove from favorites" else "Add to favorites"
                },
        )
    }
}
