// Validates corpus/quotes.json against the shape described in corpus/schema.json.
// Used as the lint step (`npm run lint:corpus`); also imported by
// scripts/build-corpus.js so the build step validates before compiling.

const fs = require("node:fs");
const path = require("node:path");

const CORPUS_PATH = path.join(__dirname, "..", "corpus", "quotes.json");

const REQUIRED_FIELDS = ["text", "episodeTitle", "season", "episode", "arc"];

function validateCorpus(entries) {
  const errors = [];

  if (!Array.isArray(entries)) {
    return ["corpus must be a JSON array"];
  }

  const seenText = new Map();

  entries.forEach((entry, index) => {
    const where = `entry[${index}]`;

    if (typeof entry !== "object" || entry === null || Array.isArray(entry)) {
      errors.push(`${where}: must be an object`);
      return;
    }

    for (const field of REQUIRED_FIELDS) {
      if (!(field in entry)) {
        errors.push(`${where}: missing required field "${field}"`);
      }
    }

    const extraFields = Object.keys(entry).filter((k) => !REQUIRED_FIELDS.includes(k));
    for (const field of extraFields) {
      errors.push(`${where}: unexpected field "${field}"`);
    }

    if ("text" in entry && (typeof entry.text !== "string" || entry.text.trim().length === 0)) {
      errors.push(`${where}: "text" must be a non-empty string`);
    }
    if ("episodeTitle" in entry && (typeof entry.episodeTitle !== "string" || entry.episodeTitle.trim().length === 0)) {
      errors.push(`${where}: "episodeTitle" must be a non-empty string`);
    }
    if ("arc" in entry && (typeof entry.arc !== "string" || entry.arc.trim().length === 0)) {
      errors.push(`${where}: "arc" must be a non-empty string`);
    }
    if ("season" in entry && (!Number.isInteger(entry.season) || entry.season < 1)) {
      errors.push(`${where}: "season" must be a positive integer`);
    }
    if ("episode" in entry && (!Number.isInteger(entry.episode) || entry.episode < 1)) {
      errors.push(`${where}: "episode" must be a positive integer`);
    }

    if (typeof entry.text === "string") {
      const key = entry.text.trim().toLowerCase();
      if (seenText.has(key)) {
        errors.push(`${where}: duplicate quote text (also at entry[${seenText.get(key)}])`);
      } else {
        seenText.set(key, index);
      }
    }
  });

  return errors;
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

  console.log(`Corpus valid: ${entries.length} quote(s).`);
}

if (require.main === module) {
  main();
}

module.exports = { validateCorpus, CORPUS_PATH };
