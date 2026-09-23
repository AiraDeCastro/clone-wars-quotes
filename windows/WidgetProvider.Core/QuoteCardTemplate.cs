using System.Text.Json;

namespace ColdOpen.WidgetProvider.Core;

/// <summary>
/// The Adaptive Card template (and its per-update data payload) used for
/// the Cold Open widget, across its small, medium, and large sizes.
///
/// Size handling lives entirely in this one shared template, not in C#
/// code that picks a different template string per size — Microsoft's own
/// "Implement a widget provider in a C# Windows App" doc shows this as the
/// supported alternative to branching on <c>WidgetContext.Size</c>, using
/// parallel <c>$when</c>-gated elements keyed on <c>$host.widgetSize</c>
/// (fetched and confirmed the exact syntax before writing this, since it's
/// Adaptive Card Templating Language, not something to guess at):
/// https://learn.microsoft.com/windows/apps/develop/widgets/implement-widget-provider-cs
///
/// A faction emblem was considered for the large size specifically (see
/// CLAUDE.md's design direction and the matching iOS/Android decision) but
/// deliberately left out here too — same two blockers: a design decision
/// and a quote-to-faction mapping the corpus schema doesn't have yet.
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
    // counting widget (see implement-widget-provider-cs.md). $when/
    // $host.widgetSize is the same doc's own documented syntax for
    // per-size conditional rendering within one template; only the "=="
    // comparison shown there is used below, deliberately not a guessed-at
    // "!=" or "||" the doc didn't demonstrate.
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
                "size": "medium",
                "$when": "${$host.widgetSize==\"small\"}"
            },
            {
                "type": "TextBlock",
                "text": "${quoteText}",
                "wrap": true,
                "weight": "bolder",
                "size": "medium",
                "$when": "${$host.widgetSize==\"medium\"}"
            },
            {
                "type": "TextBlock",
                "text": "${quoteText}",
                "wrap": true,
                "weight": "bolder",
                "size": "extraLarge",
                "$when": "${$host.widgetSize==\"large\"}"
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
