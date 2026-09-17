using ColdOpen.WidgetProvider.Core;
using Xunit;

namespace ColdOpen.WidgetProvider.Core.Tests;

public class QuoteSelectorTests
{
    [Fact]
    public void NeverRepeatsBeforeExhaustingThePool()
    {
        var quotes = Enumerable.Range(0, 5)
            .Select(i => new Quote($"Quote {i}", "Ep", 1, i + 1, "Arc"))
            .ToList();
        var selector = new QuoteSelector(quotes);

        var seen = new HashSet<string>();
        for (var i = 0; i < 5; i++)
        {
            var quote = selector.Next() ?? throw new InvalidOperationException("expected a quote");
            Assert.True(seen.Add(quote.Text), "quote repeated before pool exhausted");
        }
        Assert.Equal(5, seen.Count);
    }

    [Fact]
    public void RefillsPoolAfterExhaustion()
    {
        var quotes = new List<Quote> { new("Only one", "Ep", 1, 1, "Arc") };
        var selector = new QuoteSelector(quotes);

        Assert.Equal("Only one", selector.Next()?.Text);
        Assert.Equal("Only one", selector.Next()?.Text);
    }

    [Fact]
    public void EmptyCorpusReturnsNull()
    {
        var selector = new QuoteSelector(new List<Quote>());
        Assert.Null(selector.Next());
    }

    [Fact]
    public void ShownTextsAccumulatesAsQuotesAreDrawn()
    {
        var quotes = Enumerable.Range(0, 3)
            .Select(i => new Quote($"Quote {i}", "Ep", 1, i + 1, "Arc"))
            .ToList();
        var selector = new QuoteSelector(quotes);

        Assert.Empty(selector.ShownTexts);
        var first = selector.Next()!;
        Assert.Equal(new HashSet<string> { first.Text }, selector.ShownTexts);
        var second = selector.Next()!;
        Assert.Equal(new HashSet<string> { first.Text, second.Text }, selector.ShownTexts);
    }

    [Fact]
    public void ResumingWithASavedShownSetExcludesThoseQuotesUntilThePoolExhausts()
    {
        var quotes = Enumerable.Range(0, 3)
            .Select(i => new Quote($"Quote {i}", "Ep", 1, i + 1, "Arc"))
            .ToList();
        // Simulate a provider restart after "Quote 0" and "Quote 1" were already shown.
        var selector = new QuoteSelector(quotes, alreadyShown: new[] { "Quote 0", "Quote 1" });

        Assert.Equal("Quote 2", selector.Next()?.Text);
        // Pool is now exhausted (all 3 shown across the restart boundary) — refills.
        var seen = new HashSet<string>();
        for (var i = 0; i < 3; i++)
        {
            seen.Add(selector.Next()!.Text);
        }
        Assert.Equal(new HashSet<string> { "Quote 0", "Quote 1", "Quote 2" }, seen);
    }

    [Fact]
    public void ResumingWithEveryQuoteAlreadyShownRefillsImmediately()
    {
        var quotes = new List<Quote> { new("Only one", "Ep", 1, 1, "Arc") };
        var selector = new QuoteSelector(quotes, alreadyShown: new[] { "Only one" });

        Assert.Equal("Only one", selector.Next()?.Text);
    }

    [Fact]
    public void RefillingAfterExhaustionClearsTheShownSetNotJustThePool()
    {
        var quotes = new List<Quote> { new("Only one", "Ep", 1, 1, "Arc") };
        var selector = new QuoteSelector(quotes);

        selector.Next();
        Assert.Equal(new HashSet<string> { "Only one" }, selector.ShownTexts);
        selector.Next(); // triggers refill since the pool was already empty
        Assert.Equal(new HashSet<string> { "Only one" }, selector.ShownTexts);
    }
}
