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
}
