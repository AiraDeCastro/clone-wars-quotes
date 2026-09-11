namespace ColdOpen.WidgetProvider.Core;

/// <summary>
/// Picks quotes at random without repeating one until the whole corpus has
/// been shown once, then reshuffles. Tracks state in memory only.
///
/// Unlike iOS's WidgetKit extension (a short-lived process per timeline
/// reload), the Windows widget provider here runs as a long-lived
/// out-of-process COM server that Windows generally keeps alive across
/// widget updates while widgets are pinned — so in the common case this
/// pool does persist longer than on iOS. But Microsoft's own reference
/// implementation explicitly plans for the provider process being
/// restarted (it rehydrates running widgets from
/// <c>WidgetManager.GetWidgetInfos()</c>'s <c>CustomState</c> on startup,
/// "in case of the computer restart or the provider crash") — and that
/// recovery path doesn't cover this pool's "already shown" set. So the same
/// fundamental gap as iOS/Android applies here too: real resilience across
/// restarts needs the pool persisted via
/// <c>WidgetUpdateRequestOptions.CustomState</c> (or local disk), not just
/// kept in memory. Not implemented yet — see TASKS.md.
/// </summary>
public sealed class QuoteSelector
{
    private readonly IReadOnlyList<Quote> _allQuotes;
    private readonly Random _random = new();
    private List<Quote> _pool;

    public QuoteSelector(IReadOnlyList<Quote> quotes)
    {
        _allQuotes = quotes;
        _pool = new List<Quote>(quotes);
    }

    /// <summary>
    /// Returns a random quote, removing it from the pool. Refills the pool
    /// from the full corpus once it's exhausted. Returns <c>null</c> only
    /// if the corpus itself is empty.
    /// </summary>
    public Quote? Next()
    {
        if (_pool.Count == 0)
        {
            _pool = new List<Quote>(_allQuotes);
        }
        if (_pool.Count == 0)
        {
            return null;
        }

        var index = _random.Next(_pool.Count);
        var quote = _pool[index];
        _pool.RemoveAt(index);
        return quote;
    }
}
