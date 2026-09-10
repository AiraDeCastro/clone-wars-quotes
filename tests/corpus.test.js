const test = require("node:test");
const assert = require("node:assert/strict");
const { validateCorpus } = require("../scripts/validate-corpus.js");

test("accepts a well-formed corpus", () => {
  const errors = validateCorpus([
    { text: "Sample quote.", episodeTitle: "Rookies", season: 1, episode: 5, arc: "Malevolence" },
  ]);
  assert.deepEqual(errors, []);
});

test("rejects a non-array corpus", () => {
  const errors = validateCorpus({ text: "not an array" });
  assert.ok(errors.length > 0);
});

test("flags a missing required field", () => {
  const errors = validateCorpus([
    { text: "Missing arc.", episodeTitle: "Rookies", season: 1, episode: 5 },
  ]);
  assert.ok(errors.some((e) => e.includes('missing required field "arc"')));
});

test("flags an unexpected field", () => {
  const errors = validateCorpus([
    { text: "Extra field.", episodeTitle: "Rookies", season: 1, episode: 5, arc: "Malevolence", speaker: "Narrator" },
  ]);
  assert.ok(errors.some((e) => e.includes('unexpected field "speaker"')));
});

test("flags non-positive-integer season/episode", () => {
  const errors = validateCorpus([
    { text: "Bad numbers.", episodeTitle: "Rookies", season: "1", episode: 0, arc: "Malevolence" },
  ]);
  assert.ok(errors.some((e) => e.includes('"season" must be a positive integer')));
  assert.ok(errors.some((e) => e.includes('"episode" must be a positive integer')));
});

test("flags duplicate quote text", () => {
  const errors = validateCorpus([
    { text: "Same line.", episodeTitle: "A", season: 1, episode: 1, arc: "Arc A" },
    { text: "same line.", episodeTitle: "B", season: 1, episode: 2, arc: "Arc B" },
  ]);
  assert.ok(errors.some((e) => e.includes("duplicate quote text")));
});

test("flags an empty text field", () => {
  const errors = validateCorpus([
    { text: "   ", episodeTitle: "Rookies", season: 1, episode: 5, arc: "Malevolence" },
  ]);
  assert.ok(errors.some((e) => e.includes('"text" must be a non-empty string')));
});
