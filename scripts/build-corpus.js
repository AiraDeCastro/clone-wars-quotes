// Compiles corpus/quotes.json into corpus/quotes.sqlite: the real
// JSON -> SQLite build step (previously a placeholder — see TASKS.md M1).
//
// Uses Node's built-in node:sqlite (available unflagged as of the Node
// version this repo targets) rather than an npm dependency, to keep the
// tooling's own dependency/audit surface exactly as small as it's been.
//
// Schema is deliberately minimal: one `quotes` table with an
// auto-incrementing `id`. That id is what makes an on-device
// "no-repeat-until-exhausted" query cheap later — a client tracks which
// ids it has already shown and asks for one NOT IN that list, rather than
// holding the whole corpus in memory the way today's per-platform
// QuoteSelector implementations still do. No other indexes yet: nothing
// queries by season/episode/arc client-side until the companion browser
// (TASKS.md M3, P1) exists.

const fs = require("node:fs");
const path = require("node:path");
const { DatabaseSync } = require("node:sqlite");
const { validateCorpus, CORPUS_PATH } = require("./validate-corpus.js");

const DB_PATH = path.join(__dirname, "..", "corpus", "quotes.sqlite");

function buildDatabase(entries, dbPath) {
  if (fs.existsSync(dbPath)) {
    fs.rmSync(dbPath);
  }

  const db = new DatabaseSync(dbPath);
  try {
    db.exec(`
      CREATE TABLE quotes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        text TEXT NOT NULL,
        episode_title TEXT NOT NULL,
        season INTEGER NOT NULL,
        episode INTEGER NOT NULL,
        arc TEXT NOT NULL
      )
    `);

    const insert = db.prepare(
      "INSERT INTO quotes (text, episode_title, season, episode, arc) VALUES (?, ?, ?, ?, ?)",
    );

    db.exec("BEGIN");
    for (const entry of entries) {
      insert.run(entry.text, entry.episodeTitle, entry.season, entry.episode, entry.arc);
    }
    db.exec("COMMIT");
  } finally {
    db.close();
  }
}

function main() {
  const raw = fs.readFileSync(CORPUS_PATH, "utf8");
  let entries;
  try {
    entries = JSON.parse(raw);
  } catch (err) {
    console.error(`Failed to parse ${CORPUS_PATH}: ${err.message}`);
    process.exit(1);
  }

  const errors = validateCorpus(entries);
  if (errors.length > 0) {
    console.error(`Corpus validation failed (${errors.length} issue(s)):`);
    for (const err of errors) console.error(`  - ${err}`);
    process.exit(1);
  }

  buildDatabase(entries, DB_PATH);
  console.log(`Built ${DB_PATH} with ${entries.length} quote(s).`);
}

if (require.main === module) {
  main();
}

module.exports = { buildDatabase };
