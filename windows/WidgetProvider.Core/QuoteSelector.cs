namespace ColdOpen.WidgetProvider.Core;

/// <summary>
/// Picks quotes at random without repeating one until the whole corpus has
/// been shown once, then reshuffles.
///
/// Unlike iOS's WidgetKit extension (a short-lived process per timeline
/// reload), the Windows widget provider here runs as a long-lived
/// out-of-process COM server that Windows generally keeps alive across
/// widget updates while widgets are pinned — so in the common case
/// in-memory state persists longer than on iOS. But Microsoft's own
/// reference implementation explicitly plans for the provider process
/// being restarted (it rehydrates running widgets from
/// <c>WidgetManager.GetWidgetInfos()</c>'s <c>CustomState</c> on startup,
/// "in case of the computer restart or the provider crash").
///
/// This class stays free of that serialization concern — it exposes
/// <see cref="ShownTexts"/> so a caller can persist it (e.g. into
/// <c>WidgetUpdateRequestOptions.CustomState</c>) and pass it back in as
/// <paramref name="alreadyShown"/> on the next construction, keyed on
/// <c>Quote.Text</c> — the same uniqueness key the corpus validator
/// already enforces (<c>scripts/validate-corpus.js</c> rejects duplicate
/// <c>text</c> values), since <see cref="Quote"/> has no separate numeric
/// id at this layer. The actual <c>CustomState</c> read/write lives in
/// <c>ColdOpenWidgetProvider</c>, not here — see TASKS.md.
/// </summary>
public sealed class QuoteSelector
{
    private readonly IReadOnlyList<Quote> _allQuotes;
    private readonly Random _random = new();
    private List<Quote> _pool;
    private readonly HashSet<string> _shown;

    public QuoteSelector(IReadOnlyList<Quote> quotes, IEnumerable<string>? alreadyShown = null)
    {
        _allQuotes = quotes;
        _shown = alreadyShown is null ? new HashSet<string>() : new HashSet<string>(alreadyShown);
        _pool = quotes.Where(q => !_shown.Contains(q.Text)).ToList();
    }

    /// <summary>Text of every quote drawn since construction (or resumed via <c>alreadyShown</c>).</summary>
    public IReadOnlySet<string> ShownTexts => _shown;

    /// <summary>
    /// Returns a random quote, removing it from the pool. Refills the pool
    /// (and clears <see cref="ShownTexts"/>) once it's exhausted —
    /// including immediately, if resuming with every quote already marked
    /// shown. Returns <c>null</c> only if the corpus itself is empty.
    /// </summary>
    public Quote? Next()
    {
        if (_pool.Count == 0)
        {
            _pool = new List<Quote>(_allQuotes);
            _shown.Clear();
        }
        if (_pool.Count == 0)
        {
            return null;
        }

        var index = _random.Next(_pool.Count);
        var quote = _pool[index];
        _pool.RemoveAt(index);
        _shown.Add(quote.Text);
        return quote;
    }
}
