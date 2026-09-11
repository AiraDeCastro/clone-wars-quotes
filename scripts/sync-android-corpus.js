// Copies corpus/quotes.json (source of truth) into the Android app module's
// bundled assets. Run manually after editing the corpus; not wired into the
// pre-commit hook because android/ won't apply on every contributor's
// machine the way the Node tooling does. A real fix — a Gradle task that
// does this automatically as part of preBuild — is tracked in TASKS.md.

const fs = require("node:fs");
const path = require("node:path");

const SOURCE = path.join(__dirname, "..", "corpus", "quotes.json");
const DEST = path.join(__dirname, "..", "android", "app", "src", "main", "assets", "quotes.json");

fs.copyFileSync(SOURCE, DEST);
console.log(`Synced ${SOURCE} -> ${DEST}`);
