# Audit: `content/index.md` — light pass (sections 1, 2, 5, 6)

File: `/home/petty/Github/corpetty/information-book/content/index.md` (1,384 words). Line numbers from `cat -n`.

## 1. Argument

**Thesis.** Landing page: complex ideas travel badly through modern media because every step both compresses and filters them, the filter is tuned for attention, and the answer is bridges rather than retreat.

**Does it earn it?** It does two jobs at once, a second summary and a site map, and now that `the-short-version.md` exists the summary half is redundant with it almost line for line (index L21–35 ≈ short version L19–21; index L45 ≈ short version L31). Specific problems:

- **"What the book argues" (L37–45) is not what the book argues.** Its three conclusions are: the medium sets the rules; three landing regimes; bridges not retreat. Missing entirely: the ownership/political-economy claim that the short version puts at the center ("the gates are *owned*"), the preservation/training split, the LLM chapter, and "survival, not victory." A reader who reads only this page thinks the book is about media effects and translation, not about who tunes the gates.
- **L15 makes a historical argument no chapter makes** ("Forty years ago a complex finding might take months … each was slow enough to act as a quality check. Today those checks have mostly collapsed"). The book's own Hammer-of-the-Witches case (Ch 5) argues that speed is *not* the variable; selection fit is. The index is offering a "things got faster" story the body rejects.
- **L33 states a superseded claim**: "Selection, not transport, is the stronger force." `data/claims.json` retired `selection-is-primary` in favor of `selection-is-the-tunable-mechanism`; the short version (L21) has the current version. The two front doors disagree.
- L9 and L49 both say "working draft." L51–55 announce "three ways in" and then L57–64 give eight bullets, so the numbered list and the bulleted list are two different maps of the same site.

**Single structural change.** Cut L19–35 to a three-sentence teaser that hands off to `[[the-short-version]]`, rewrite L37–45 so its three points match the short version's spine (compression is unavoidable; the gates are owned and tuned for attention; survive it with bridges and decoupled institutions), and merge the "three ways in" list with the bullets into one list. The page drops to ~700 words and stops competing with the file it links to.

## 2. Voice

**(a) Self-narration.** "the book" ×12: L21 "The book's starting picture"; L25 "the book breaks it into"; L27 "The book's claim is"; L39 "where the book lands"; L45 "The book argues for"; plus L9/L49 "working draft." Production voice: L39 "They're still being pressure-tested"; L49 "still being pressure-tested and polished"; L66 "being worked through in public. Pressure-tests welcome." Three "pressure-test"s on a landing page is a tic.

**(b) Reversals.** L17 "This isn't a story about villains. It's a story about a pipeline"; L31 "It's usually not the headline claim … What gets dropped is"; L33 "The most shareable idea wins, not the truest one"; L41 "doesn't mean paper vs. screens; it means the *test each gate applies*"; L45 "The fix is not to retreat"; L45 "not jacks-of-all-trades, but deep experts." Six in 45 lines.

**(c) Triads / cascades.** L13 "a headline, a thirty-second video, a chart someone screenshotted, or a thing a friend repeated at dinner" (this same list opens the short version L19; pick one home); L17 "oversimplified…, engineered…, or manufactured…"; L31 "the methodology, the 'only under these conditions,' the 'we're not sure yet'" (verbatim in short version L15); L33 "what's publishable, what's newsworthy, what's shareable, what gets clicked"; L25 parenthetical "(That's the simplified version; the book breaks it into a few more stages, but this is the spine.)" reads as an em-dash aside.

**(d) Tics.** quietly ×1 (L17), load-bearing ×1 (L60, "every load-bearing term"), "actually" ×4 (L23, L25, L49, L59). Low tic density otherwise.

**(e) Punchlines.** L27 "You can't understand the problem holding just one."; L31 "The claim arrives; the manual for understanding it correctly does not."; L33 "Selection, not transport, is the stronger force."; L35 "and the filter is tuned to something other than truth."; L41 "Change the medium and you change what's even possible."

**(f)** None.

**Two rewrites.**

*L15–17 original (~190 words)* → (~80 words), dropping the unsupported history:
> That re-telling has always happened. What the book adds is that two different things happen at every hand-off, and only one of them is anyone's decision. The idea gets compressed, which is nobody's fault. And it gets chosen over a thousand others by a gate with its own test, and today the tests that matter most are tuned to reward reaction. This isn't a story about villains. It's a story about who sets the tests and what that costs.

*L47–55 original* → (~70 words):
> ## Ways in
> If you have five minutes, read [[the-short-version|the short version]]. If you want the argument, start at [[the-information-landscape|Chapter 1]] and follow the *next →* link at the foot of each chapter. If you'd rather wander, every term is a page: follow the links, the backlinks panel, or the <a href="./graph/" data-router-ignore="true">ontology map</a>. Keep the [[glossary]] open either way.

## 5. Interlinking and searchability

**Unlinked terms with pages.** L31 transport → `mechanisms/transport`; L31 telephone game → `cases/telephone-game`; L31 instructions for how to read the claim → `three-layer-message`; L33 selection / gate → `mechanisms/selection`; L33 shareable → `concepts/memetic-fitness`; L41 medium → `medium-and-manipulation`, `concepts/technology-vs-medium`; L43 preserved / inverted / identity signal → `concepts/truth-compression-regimes`; L45 like-minded groups that wall off outside information → `concepts/echo-chambers-vs-bubbles`; L45 "lock in early on shaky answers" → `concepts/zollman-effect`; L45 bridges / deep experts trained to translate → `concepts/versatile-expertise`, `bridge-nodes-and-versatile-expertise`; L45 institutions that stay trusted → `concepts/survivable-polarization`. L64 links The Abyss externally only; `concepts/abyss.md` exists and should be linked alongside.

**Link-style inconsistency.** L53 uses a markdown link `[…](the-information-landscape)` while every other internal link on the page is a wikilink; the mixed form will break if Quartz's slug resolution changes.

**Cases.** Telephone game (L31) is the only case mentioned; unlinked.

**Sources.** None named. Harari/Postman/Mercier/O'Connor are the book's four pillars and a landing page could name them in one sentence with citation links (`citations/nexus-book`, `citations/amusing-ourselves-to-death`, `citations/not-born-yesterday`, `citations/misinformation-age`), which also helps search.

**Proposed frontmatter.**
```yaml
description: "Lossy is a working draft of a book about why complex ideas get compressed, filtered, and twisted on the way to a general audience, who tunes the filters, and what institutions can survive it. Start here."
aliases: [Lossy, home, landing page, how ideas get compressed, information pipeline book, transport and selection, Corey Petty book]
```

## 6. Reader-facing defects

- **Contradictions with the body.** L33 "Selection, not transport, is the stronger force" vs `claims.json` and short version L21 (selection is the *tunable* mechanism, not the stronger one). L15 "what's changed is the speed" vs Ch 5's Hammer/Copernicus reading. L45 "institutions … that stay trusted even when politics is polarized" vs Ch 12 Principle 3, which is explicitly about institutions that work *without* being trusted by everyone. L43 "set by the medium" vs glossary L61 "set by the selection gate" (reconcilable, but a reader meets both).
- **Stale / unsupported facts.** L15 "Forty years ago … months" (⚠ no source, and yellow journalism, radio and tabloids distorted at speed long before 1986). L62 "Most settled chapters: Ch 1 and Ch 5c": `chapters.json` has Ch 1 as `drafted` and Ch 5c as `in-workshop` like the rest, so nothing in the data marks 5c as more settled. L55 "The interactive ontology map below" — nothing is below; it is a link in the list.
- **Inside references / tooling.** L54 "the **backlinks** panel, and the **local graph** (right side of every page)" is layout-dependent (not on the right at phone width). L58 "Pick a starting view (Book overview / Argument map / …)" is the graph tool's menu, not book content. L61 "[[outline]] … written for the author." L63 "Foundational notes" links seven depth notes with no gloss of what a "note" is versus a chapter. L59 "<kbd>?</kbd>" and "Arrow keys to advance" are fine but belong on the talk page.
- **Repeated across files.** L13's dinner-table list and L31's triad are verbatim in the short version; L45's bridge prescription is in the short version and Ch 12.
- **General-reader trips.** L43's processed-meat example is the clearest passage on the page; keep it. L27 "You can't understand the problem holding just one" assumes the reader knows "just one" of what.

## Top 5 actions for this file

1. Fix L33 to the current claim ("selection is the only one of the two you can aim") and delete the L15 "forty years ago" history.
2. Rewrite "What the book argues" so its three points match the short version's spine (compression unavoidable / gates owned / survive with bridges and decoupled institutions).
3. Cut L19–35 to a teaser and hand off to `[[the-short-version]]`; merge the "three ways in" and the bullet list.
4. Convert L53 to a wikilink, link `concepts/abyss`, and add ~10 concept/case links at first use.
5. Remove the three "pressure-test" production lines and the "settled chapters" claim, or make them match `chapters.json`.
