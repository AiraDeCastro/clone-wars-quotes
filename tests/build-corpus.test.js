const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const { DatabaseSync } = require("node:sqlite");
const { buildDatabase } = require("../scripts/build-corpus.js");

function tempDbPath() {
  return path.join(os.tmpdir(), `coldopen-test-${Date.now()}-${Math.random().toString(16).slice(2)}.sqlite`);
}

test("writes one row per quote with the right columns", () => {
  const dbPath = tempDbPath();
  const quotes = [
    { text: "Quote one.", episodeTitle: "Ep One", season: 1, episode: 1, arc: "Arc A" },
    { text: "Quote two.", episodeTitle: "Ep Two", season: 1, episode: 2, arc: "Arc A" },
  ];

  try {
    buildDatabase(quotes, dbPath);

    const db = new DatabaseSync(dbPath);
    const rows = db.prepare("SELECT * FROM quotes ORDER BY id").all();
    db.close();

    assert.equal(rows.length, 2);
    assert.equal(rows[0].text, "Quote one.");
    assert.equal(rows[0].episode_title, "Ep One");
    assert.equal(rows[0].season, 1);
    assert.equal(rows[0].episode, 1);
    assert.equal(rows[0].arc, "Arc A");
  } finally {
    fs.rmSync(dbPath, { force: true });
  }
});

test("assigns sequential ids, usable for a no-repeat query against a shown-id list", () => {
  const dbPath = tempDbPath();
  const quotes = [
    { text: "A", episodeTitle: "E", season: 1, episode: 1, arc: "X" },
    { text: "B", episodeTitle: "E", season: 1, episode: 2, arc: "X" },
    { text: "C", episodeTitle: "E", season: 1, episode: 3, arc: "X" },
  ];

  try {
    buildDatabase(quotes, dbPath);
    const db = new DatabaseSync(dbPath);
    const ids = db.prepare("SELECT id FROM quotes ORDER BY id").all().map((r) => r.id);
    db.close();
    assert.deepEqual(ids, [1, 2, 3]);
  } finally {
    fs.rmSync(dbPath, { force: true });
  }
});

test("rebuilding overwrites rather than appending", () => {
  const dbPath = tempDbPath();
  const first = [{ text: "First run", episodeTitle: "E", season: 1, episode: 1, arc: "X" }];
  const second = [{ text: "Second run", episodeTitle: "E", season: 1, episode: 1, arc: "X" }];

  try {
    buildDatabase(first, dbPath);
    buildDatabase(second, dbPath);

    const db = new DatabaseSync(dbPath);
    const rows = db.prepare("SELECT * FROM quotes").all();
    db.close();

    assert.equal(rows.length, 1);
    assert.equal(rows[0].text, "Second run");
  } finally {
    fs.rmSync(dbPath, { force: true });
  }
});

test("building an empty corpus produces a valid, empty table", () => {
  const dbPath = tempDbPath();

  try {
    buildDatabase([], dbPath);
    const db = new DatabaseSync(dbPath);
    const rows = db.prepare("SELECT * FROM quotes").all();
    db.close();
    assert.equal(rows.length, 0);
  } finally {
    fs.rmSync(dbPath, { force: true });
  }
});
