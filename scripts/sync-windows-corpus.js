// Copies corpus/quotes.json (source of truth) into the Windows widget
// provider project so it ships as Content next to WidgetProvider.exe. Run
// manually after editing the corpus; not wired into the pre-commit hook
// because windows/ won't apply on every contributor's machine the way the
// Node tooling does. A real fix — an MSBuild target that does this
// automatically — is tracked in TASKS.md.

const fs = require("node:fs");
const path = require("node:path");

const SOURCE = path.join(__dirname, "..", "corpus", "quotes.json");
const DEST = path.join(__dirname, "..", "windows", "WidgetProvider", "quotes.json");

fs.copyFileSync(SOURCE, DEST);
console.log(`Synced ${SOURCE} -> ${DEST}`);
