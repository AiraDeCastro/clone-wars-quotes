namespace ColdOpen.WidgetProvider.Core;

/// <summary>
/// A single cold-open narration line. Mirrors the schema in
/// <c>corpus/schema.json</c> at the repo root — keep the two in sync if
/// either changes.
/// </summary>
public sealed record Quote(string Text, string EpisodeTitle, int Season, int Episode, string Arc);
