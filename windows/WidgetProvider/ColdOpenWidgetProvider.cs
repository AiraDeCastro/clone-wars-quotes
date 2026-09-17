using ColdOpen.WidgetProvider.Core;
using Microsoft.Windows.Widgets.Providers;

namespace ColdOpen.WidgetProvider;

/// <summary>
/// Implements <see cref="IWidgetProvider"/>, the interface the Widgets
/// Board host calls to drive widget lifecycle and updates. Structure is
/// adapted from Microsoft's own walkthrough (Implement a widget provider in
/// a C# Windows App), swapping their mock weather/counter data for our
/// quote corpus.
/// </summary>
internal sealed class ColdOpenWidgetProvider : IWidgetProvider
{
    // '\u001F' (ASCII Unit Separator) joins shown quote texts in
    // CustomState — a real narration sentence won't contain a control
    // character, so this can't be confused with a comma or other
    // punctuation the text itself might contain.
    private const char StateDelimiter = '\u001F';

    private static readonly Dictionary<string, string> RunningWidgetIds = new();
    private static readonly ManualResetEvent EmptyWidgetListEventField = new(false);

    private readonly QuoteSelector _selector;

    public ColdOpenWidgetProvider()
    {
        var corpusPath = Path.Combine(AppContext.BaseDirectory, "quotes.json");
        var quotes = QuoteCorpus.Load(corpusPath);

        // Recover any widgets already pinned before this process started
        // (e.g. after a computer restart or a provider crash). _selector is
        // one shared instance for the whole process (not per-widget), so on
        // resume it only needs ONE widget's CustomState, not all of them —
        // every pinned widget's CustomState is written with the same shared
        // "already shown" set on every update (see UpdateWidget below), so
        // any one of them is a valid seed.
        var runningWidgets = WidgetManager.GetDefault().GetWidgetInfos();
        var seedState = runningWidgets
            .Select(info => info.CustomState)
            .FirstOrDefault(state => !string.IsNullOrEmpty(state));
        _selector = new QuoteSelector(quotes, alreadyShown: DecodeShownTexts(seedState));

        foreach (var info in runningWidgets)
        {
            var id = info.WidgetContext.Id;
            RunningWidgetIds[id] = id;
        }
    }

    public void CreateWidget(WidgetContext widgetContext)
    {
        RunningWidgetIds[widgetContext.Id] = widgetContext.Id;
        UpdateWidget(widgetContext.Id);
    }

    public void DeleteWidget(string widgetId, string customState)
    {
        RunningWidgetIds.Remove(widgetId);
        if (RunningWidgetIds.Count == 0)
        {
            EmptyWidgetListEventField.Set();
        }
    }

    public void OnActionInvoked(WidgetActionInvokedArgs actionInvokedArgs)
    {
        if (actionInvokedArgs.Verb != "refresh")
        {
            return;
        }

        var widgetId = actionInvokedArgs.WidgetContext.Id;
        if (RunningWidgetIds.ContainsKey(widgetId))
        {
            UpdateWidget(widgetId);
        }
    }

    public void OnWidgetContextChanged(WidgetContextChangedArgs contextChangedArgs)
    {
        var widgetId = contextChangedArgs.WidgetContext.Id;
        if (RunningWidgetIds.ContainsKey(widgetId))
        {
            UpdateWidget(widgetId);
        }
    }

    public void Activate(WidgetContext widgetContext)
    {
        if (RunningWidgetIds.ContainsKey(widgetContext.Id))
        {
            UpdateWidget(widgetContext.Id);
        }
    }

    public void Deactivate(string widgetId)
    {
        // No per-widget teardown needed yet.
    }

    private void UpdateWidget(string widgetId)
    {
        var quote = _selector.Next();
        if (quote is null)
        {
            return;
        }

        var updateOptions = new WidgetUpdateRequestOptions(widgetId);
        updateOptions.Template = QuoteCardTemplate.Template;
        updateOptions.Data = QuoteCardTemplate.BuildData(quote);
        updateOptions.CustomState = EncodeShownTexts(_selector.ShownTexts);
        WidgetManager.GetDefault().UpdateWidget(updateOptions);
    }

    // NOTE: this stores the full TEXT of every shown quote, which will grow
    // to a non-trivial string once the full ~130-quote corpus exists (worst
    // case: every quote's text concatenated). A compact index-based
    // encoding — e.g. the SQLite `id` column corpus/quotes.sqlite already
    // has for exactly this "cheap no-repeat query" purpose — would be
    // better, but adopting it here means first deciding how the Windows
    // provider reads the corpus at all (it still reads the flat
    // quotes.json, like iOS/Android — see the "no platform reads
    // quotes.sqlite yet" task in TASKS.md). Logged as a follow-on rather
    // than solved incidentally here.
    private static string EncodeShownTexts(IEnumerable<string> shownTexts) =>
        string.Join(StateDelimiter, shownTexts);

    private static IEnumerable<string> DecodeShownTexts(string? state) =>
        string.IsNullOrEmpty(state) ? Enumerable.Empty<string>() : state.Split(StateDelimiter);

    public static ManualResetEvent GetEmptyWidgetListEvent() => EmptyWidgetListEventField;
}
