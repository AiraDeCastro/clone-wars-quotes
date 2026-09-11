using ColdOpen.WidgetProvider.Core;
using Xunit;

namespace ColdOpen.WidgetProvider.Core.Tests;

public class QuoteCorpusTests
{
    private const string SampleJson = """
    [
      {
        "text": "Heroes are made by the path they choose, not the powers they are graced with.",
        "episodeTitle": "Rookies",
        "season": 1,
        "episode": 5,
        "arc": "Malevolence"
      }
    ]
    """;

    [Fact]
    public void ParsesAWellFormedCorpus()
    {
        var quotes = QuoteCorpus.Parse(SampleJson);
        Assert.Single(quotes);
        Assert.False(string.IsNullOrEmpty(quotes[0].Text));
    }

    [Fact]
    public void ParsesTheKnownSeedEntryCorrectly()
    {
        var quotes = QuoteCorpus.Parse(SampleJson);
        Assert.Contains(quotes, q => q.EpisodeTitle == "Rookies" && q.Season == 1 && q.Episode == 5);
    }
}
