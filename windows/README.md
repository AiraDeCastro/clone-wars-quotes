# Windows Widget Scaffold

This is a source-level scaffold for the Windows widget provider, written on a machine that **is** actually Windows 11 (unlike the iOS/macOS scaffold, which needed a Mac) — but with no .NET SDK, MSBuild, or Visual Studio installed (confirmed: `dotnet`, `msbuild` both absent). **Nothing in here has been restored, compiled, packaged, or deployed to a Widgets Board yet.**

Unlike WidgetKit and Jetpack Glance, the third-party Windows widget API (the **Widget Service API**, via `Microsoft.Windows.Widgets.Providers` in the Windows App SDK) is niche enough that it wasn't safe to scaffold from memory alone — before writing any code here, the actual current Microsoft Learn documentation ["Implement a widget provider in a C# Windows App"](https://learn.microsoft.com/windows/apps/develop/widgets/implement-widget-provider-cs) was fetched and read in full, and the COM plumbing below is adapted closely from its reference code rather than reconstructed from training-data memory. Where this scaffold goes beyond that doc (see "Where this scaffold extrapolates" below), treat it as lower-confidence than the rest.

## What's here

- `WidgetProvider.Core/` — a plain `net8.0` class library, **no Windows-specific dependency on purpose** (mirrors `ColdOpenCore` on iOS and `:core` on Android): `Quote`, `QuoteCorpus`, `QuoteSelector` (random no-repeat-until-exhausted), and `QuoteCardTemplate` (the Adaptive Card JSON + per-update data payload). Because it targets plain `net8.0`, this is the one piece of the Windows scaffold that could in principle be built/tested on any OS with a .NET SDK, not just Windows.
- `WidgetProvider.Core.Tests/` — xUnit tests for the above (`dotnet test` once a .NET SDK is available).
- `WidgetProvider/` — the actual widget provider executable: `ColdOpenWidgetProvider.cs` (implements `IWidgetProvider`: `CreateWidget`, `DeleteWidget`, `OnActionInvoked`, `OnWidgetContextChanged`, `Activate`, `Deactivate`), `FactoryHelper.cs` (COM class-factory boilerplate, adapted near-verbatim from Microsoft's sample), and `Program.cs` (registers the provider via `CoRegisterClassObject`).
- `WidgetProvider.Package/Package.appxmanifest` — the manifest content that registers this as a COM server and a widget provider with the Widgets Board (the `com:Extension` and `uap3:Extension` blocks), adapted from Microsoft's example. **This is not a complete, standalone manifest** — see "Deliberately missing" below.

## Unlike iOS/Android: manual refresh comes almost for free

The widget's Adaptive Card template (`QuoteCardTemplate.Template`) includes an `Action.Execute` button with `verb: "refresh"`, and `ColdOpenWidgetProvider.OnActionInvoked` already handles that verb by calling `UpdateWidget`. Because the same `IWidgetProvider` callback interface handles both lifecycle events and user actions, wiring a working "new quote" button didn't need a separate mechanism the way iOS needs an `AppIntent` or Android needs a Glance click action — it's the same code path as `CreateWidget`/`Activate`. Untested, but structurally it's already there, unlike on the other two platforms at this stage.

## Deliberately missing: the `.wapproj` packaging project

Only packaged (MSIX) apps can register as widget providers. The actual **Windows Application Packaging Project** (`.wapproj`) that wraps `WidgetProvider.exe` and carries `Package.appxmanifest` isn't scaffolded here — a `.wapproj` is a Visual-Studio-specific project type (distinct `ProjectTypeGuids`, packaging-specific MSBuild targets) that's meaningfully riskier to hand-author from memory than a plain SDK-style `.csproj`, and there was no way to verify one here. Create it the supported way once you have Visual Studio:

1. **File → Add → New Project → Windows Application Packaging Project**, name it `WidgetProvider.Package`, target version 1809+.
2. Add a project reference to `WidgetProvider`.
3. Add this to the generated `.wapproj` file: a `PackageReference` for `Microsoft.WindowsAppSDK` with `<IncludeAssets>build</IncludeAssets>` (see the manifest's own comment header for the exact snippet from Microsoft's doc).
4. Replace the generated `Package.appxmanifest` with (or merge in the `Extensions` from) `WidgetProvider.Package/Package.appxmanifest` in this folder.
5. Add the referenced images under `Images/` and `ProviderAssets/` — see `WidgetProvider.Package/ProviderAssets/README.md`, none exist yet.

## Where this scaffold extrapolates beyond the fetched doc

The doc's own walkthrough builds a mock weather/counter widget with no packaging-project-level detail beyond one example manifest. Everything below is a reasonable extension, not confirmed against a second source:

- **`EntryPoint="Windows.FullTrustApplication"` and the `runFullTrust` restricted capability** in `Package.appxmanifest` — standard for packaging a full-trust Win32/console exe (the "Desktop Bridge" pattern), but not something the fetched doc itself showed.
- **Adaptive Card styling** — `QuoteCardTemplate` deliberately doesn't hard-code text/background colors, since it's unconfirmed whether/how Widgets Board lets a card override host theming for the "deep space-navy" look in CLAUDE.md's design direction.

The `Microsoft.WindowsAppSDK` NuGet version pin used to be in this list too — it's now confirmed (`2.4.0`, verified against NuGet.org as the current stable release on 2026-09-11, not a preview), so it's no longer a guess. Still worth a quick re-check before restoring if this scaffold sits untouched for a long stretch.

## A GUID placeholder that must stay consistent

`Program.cs`'s `clsidFactory`, `Package.appxmanifest`'s `com:Class Id`, and its `CreateInstance ClassId` all use the same placeholder GUID (`6041f1cb-d544-4bec-8d4b-fd9e733060f5`), generated once for this scaffold via `crypto.randomUUID()` rather than Visual Studio's `Tools → Create GUID` (no Visual Studio here). It's internally consistent, but regenerate it before any real distribution, and update all three places if you do.

## Verify the logic first

```bash
cd windows/WidgetProvider.Core
dotnet test ../WidgetProvider.Core.Tests
```

(once a .NET SDK is available). This runs `QuoteSelectorTests` and `QuoteCorpusTests` without needing Windows App SDK, MSIX packaging, or a Widgets Board at all.

Before building `WidgetProvider` itself, sync the bundled corpus:

```bash
npm run sync:windows
```

(from the repo root — copies `corpus/quotes.json` into `windows/WidgetProvider/quotes.json`. Manual for now, same pattern as `sync:ios`/`sync:android`.)

## Known gaps (see TASKS.md for the tracked version of this list)

- **Not yet built, packaged, or deployed anywhere.** First real task: does `WidgetProvider.Core` even compile and pass its tests with a real .NET SDK?
- **No `.wapproj` packaging project** — see above.
- **No-repeat selection's in-memory pool won't survive a provider restart** — see the doc comment on `QuoteSelector`.
- **No app icons/screenshots** — `Package.appxmanifest` references several PNGs that don't exist (see `WidgetProvider.Package/ProviderAssets/README.md`).
