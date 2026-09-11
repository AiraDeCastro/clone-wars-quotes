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
    private static readonly Dictionary<string, string> RunningWidgetIds = new();
    private static readonly ManualResetEvent EmptyWidgetListEventField = new(false);

    private readonly QuoteSelector _selector;

    public ColdOpenWidgetProvider()
    {
        var corpusPath = Path.Combine(AppContext.BaseDirectory, "quotes.json");
        var quotes = QuoteCorpus.Load(corpusPath);
        _selector = new QuoteSelector(quotes);

        // Recover any widgets already pinned before this process started
        // (e.g. after a computer restart or a provider crash) — see
        // QuoteSelector's doc comment for what this recovery does and
        // doesn't cover.
        foreach (var info in WidgetManager.GetDefault().GetWidgetInfos())
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
        WidgetManager.GetDefault().UpdateWidget(updateOptions);
    }

    public static ManualResetEvent GetEmptyWidgetListEvent() => EmptyWidgetListEventField;
}
