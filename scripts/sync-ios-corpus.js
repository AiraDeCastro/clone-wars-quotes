// Copies corpus/quotes.json (source of truth) into the ColdOpenCore Swift
// package's bundled resource. Run manually after editing the corpus; not
// wired into the pre-commit hook because ios/ won't exist/apply on every
// contributor's machine the way the Node tooling does. A real fix — an
// Xcode "Run Script" build phase that does this automatically — is tracked
// in TASKS.md.

const fs = require("node:fs");
const path = require("node:path");

const SOURCE = path.join(__dirname, "..", "corpus", "quotes.json");
const DEST = path.join(__dirname, "..", "ios", "ColdOpenCore", "Sources", "ColdOpenCore", "Resources", "quotes.json");

fs.copyFileSync(SOURCE, DEST);
console.log(`Synced ${SOURCE} -> ${DEST}`);
