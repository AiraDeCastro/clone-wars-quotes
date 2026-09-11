using System.Text.Json;
using System.Text.Json.Serialization;

namespace ColdOpen.WidgetProvider.Core;

/// <summary>
/// Parses the quote corpus. Takes raw JSON in, hands <see cref="Quote"/>s
/// back — no dependency on where the JSON came from, so the widget
/// provider project is responsible for actually locating and reading
/// <c>quotes.json</c> (see WidgetProvider/WidgetProvider.cs).
/// </summary>
public static class QuoteCorpus
{
    private sealed record QuoteDto(
        [property: JsonPropertyName("text")] string Text,
        [property: JsonPropertyName("episodeTitle")] string EpisodeTitle,
        [property: JsonPropertyName("season")] int Season,
        [property: JsonPropertyName("episode")] int Episode,
        [property: JsonPropertyName("arc")] string Arc);

    public static IReadOnlyList<Quote> Parse(string json)
    {
        var dtos = JsonSerializer.Deserialize<List<QuoteDto>>(json)
            ?? throw new InvalidDataException("Corpus JSON did not deserialize to a list.");

        return dtos
            .Select(d => new Quote(d.Text, d.EpisodeTitle, d.Season, d.Episode, d.Arc))
            .ToList();
    }

    public static IReadOnlyList<Quote> Load(string path) => Parse(File.ReadAllText(path));
}
