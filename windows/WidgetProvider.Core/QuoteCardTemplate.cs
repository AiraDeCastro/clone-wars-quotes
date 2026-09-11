using System.Text.Json;

namespace ColdOpen.WidgetProvider.Core;

/// <summary>
/// The Adaptive Card template (and its per-update data payload) used for
/// the Cold Open widget, in both its small and medium sizes.
///
/// Deliberately doesn't hard-code text/background colors: Adaptive Cards
/// generally inherit contrast-safe styling from the host's own theme, and
/// this hasn't been render-tested against the actual Widgets Board to know
/// whether/how to safely override that for the "deep space-navy" design
/// direction in CLAUDE.md — tracked as a follow-on in TASKS.md rather than
/// guessed at here.
/// </summary>
public static class QuoteCardTemplate
{
    // ${quoteText} / ${attribution} are Adaptive Card data-binding
    // expressions, resolved against the JSON produced by BuildData below —
    // same pattern Microsoft's own widget provider sample uses for its
    // counting widget (see implement-widget-provider-cs.md).
    public const string Template = """
    {
        "$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
        "type": "AdaptiveCard",
        "version": "1.5",
        "body": [
            {
                "type": "TextBlock",
                "text": "${quoteText}",
                "wrap": true,
                "weight": "bolder",
                "size": "medium"
            },
            {
                "type": "TextBlock",
                "text": "${attribution}",
                "wrap": true,
                "isSubtle": true,
                "size": "small",
                "spacing": "small"
            }
        ],
        "actions": [
            {
                "type": "Action.Execute",
                "title": "New quote",
                "verb": "refresh"
            }
        ]
    }
    """;

    public static string BuildData(Quote quote)
    {
        var payload = new
        {
            quoteText = quote.Text,
            attribution = $"{quote.EpisodeTitle} · S{quote.Season}E{quote.Episode}",
        };
        return JsonSerializer.Serialize(payload);
    }
}
