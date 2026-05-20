# Interpretive triple extraction — per-PDF agent

You are extracting **interpretive semantic triples** from a single academic
paper so they can be merged into the information-book authoring graph.
Every triple you emit will be tagged `interpretive: true` and rendered in
a distinct style in the viewer — authors filter or accept them as
candidates, not ground truth.

Aim for **precision over recall**: if you are not confident, omit the
triple.

## Inputs you receive

1. **Catalog**: `data/extraction-catalog.json` — list of all valid
   subject/object ids and the predicate vocabulary. **Only emit triples
   whose subject and object appear in the catalog**, except that the
   paper itself is referred to as `source:<your-source-slug>` (told to
   you in the dispatch prompt).
2. **PDF**: the paper to extract from (path given to you).
3. **Source slug**: the canonical id for this paper, e.g. `source:psychology-of-virality`.
4. **Output path**: write JSONL — one triple per line — to the path
   given to you.

## Primary predicates (in priority order)

These are the high-value extractions for a paper. Don't waste a
`mentions` when a stronger predicate fits.

- **`supports`** — Source → Claim. The paper provides positive evidence,
  data, or argument backing a specific Claim. Direction: paper as
  subject, claim as object.
  Example: `source:psychology-of-virality supports claim:complexity-virality-inverse`

- **`pressureTests`** — Source → Claim. The paper challenges,
  complicates, qualifies, or contradicts a Claim. Direction: paper as
  subject, claim as object. Use even when the paper agrees in spirit
  but reveals an edge case or condition the Claim doesn't address.
  Example: `source:memetics-critique pressureTests claim:selection-primary`

- **`evidencedBy`** — Concept / Mechanism / Question / Claim → Source.
  The paper substantively engages with a graph entity (provides
  operational definition, develops, applies, or critiques it).
  **Direction is reversed from supports/pressureTests:** the graph
  entity is the subject, the paper is the object.
  Example: `concept:memetic-fitness evidencedBy source:psychology-of-virality`

- **`mentions`** — last-resort weak link. Only when a stronger
  predicate doesn't fit and the paper substantively touches the node.
  Skip passing mentions entirely.

## Direction conventions — important

- `supports` / `pressureTests`: **paper is subject** (`source:<slug>`) —
  always your source slug, never a Concept or Mechanism. The **object**
  is the argument-bearing element the paper takes a stance on: a
  `claim:`, `mechanism:`, or `concept:`. A paper may support or
  pressure-test any of the three — but the subject is always the source.
  A triple like `concept:foo supports claim:bar` (concept as subject) is
  malformed and the aggregator will drop it; emit
  `source:<slug> supports claim:bar` instead.
- `evidencedBy`: **graph node is subject**, **paper is object**
  (`source:<slug>`).
- This asymmetry is intentional and matches the rest of the graph:
  Claims have things asserted *about* them by sources, while Concepts
  / Mechanisms accumulate evidentiary sources *about* themselves.

## Output schema (one JSON object per line)

```json
{
  "subject": "concept:memetic-fitness",
  "predicate": "evidencedBy",
  "object": "source:psychology-of-virality",
  "quote": "exact verbatim span from the paper, ≤ 240 chars",
  "pageApprox": 7,
  "confidence": "high",
  "rationale": "≤ 140 chars — what the paper is asserting and why this triple captures it"
}
```

- `quote` must be a verbatim span from the paper. Trim whitespace;
  escape quotes. Don't paraphrase.
- `pageApprox` is the page number where the quote appears (1-indexed;
  best estimate is fine).
- `confidence`: `high` (explicit, on-topic, unambiguous) / `medium`
  (implied or partially aligned) / `low` (only emit when the rationale
  is genuinely useful for authoring).
- `rationale` should explain in plain English what the paper is
  asserting and why this triple captures it.

## Style guard-rails

- **Precision > recall.** A good extraction is **15–40 high-signal
  triples** per paper. Don't pad with low-confidence triples.
- **Don't invent ids.** If the paper discusses something not in the
  catalog (e.g. a concept the ontology hasn't authored yet), skip the
  triple — but note it in the trailing `_note` line (see below).
- **De-dupe.** One quote per `(subject, predicate, object)` tuple.
  Pick the strongest passage if the paper repeats.
- **Use the aliases.** Each concept/mechanism/claim entry in the
  catalog has an `aliases[]` array. Recognize synonyms (e.g. "memetic
  fitness" / "fitness landscape" / "selection criteria" all map to
  `concept:memetic-fitness`).

## Handling large PDFs

For PDFs > 30 pages, use the `pages` parameter when reading — never
read the whole document at once. Suggested pass strategy:

1. Read abstract + introduction + conclusion first (pages 1-3 and last
   2-3 pages) to identify the paper's main contributions.
2. Read methods / results / discussion sections for the strongest
   evidentiary passages.
3. Skip extended technical proofs, citations sections, and supplementary
   material unless they contain a key passage.

## Optional trailing note

After your last triple line, you MAY emit one final line with diagnostic
info:

```json
{"_note": "≤ 280 chars — concepts you saw clearly but couldn't anchor to the catalog, suggestions for future extractions, or systemic observations about the paper"}
```

The aggregator parses this and surfaces it in `data/interpretive-notes.json`
for the human author — useful for spotting catalog gaps before the next
extraction run.

## Procedure

1. Read the catalog file.
2. Read the PDF (use `pages` for large documents).
3. Build a working list of triple candidates with quotes; review for
   precision. Drop the weakest 30%.
4. Write JSONL to the output path. Every line must parse as JSON; every
   subject and object id must be in the catalog or be `source:<your-slug>`.
5. Print a one-line stdout summary: `<n> triples written to <path>`.
