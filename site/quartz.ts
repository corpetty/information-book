import { readFileSync } from "node:fs"
import { fileURLToPath } from "node:url"
import { dirname, resolve } from "node:path"
import { loadQuartzConfig, loadQuartzLayout } from "./quartz/plugins/loader/config-loader"
import * as ExternalPlugin from "./.quartz/plugins"
import { BookBar, ThemeTrail, findDataDir } from "./lossy-nav"

// Lossy: the sidebar in reading order, and the book bar.
//
// quartz.config.yaml holds everything it can; this file holds what YAML
// can't: the Explorer's sort / rename / filter functions, and the header
// component from lossy-nav.tsx. They turn the
// default file tree (folders first, then alphabetical) into the book's shape:
//
//   Start here      the reading path, the idea map, the short version
//   The read        chapters and interludes, in reading order
//   Depth notes     the notes that work one question through
//   Reference       glossary
//   Folders         themes (in the order of the argument), ideas, mechanisms,
//                   examples, open questions, sources, experiments
//
// The order comes from the ontology catalogs (data/chapters.json,
// data/notes.json, data/themes.json), so adding a chapter or an interlude
// there is all it takes to place it in the sidebar.
//
// The Explorer serialises these functions and runs them in the browser, so
// they cannot close over anything: each is built with `new Function` from
// source text that carries its data as a literal.

// The catalogs live in ../data relative to site/. Quartz bundles this file
// into a cache directory before running it, so import.meta.url is not a
// reliable anchor; the build always runs from site/, so try the working
// directory first and the file's own location second.
const here = dirname(fileURLToPath(import.meta.url))
const dataDir = findDataDir([
  resolve(process.cwd(), "..", "data"),
  resolve(here, "..", "data"),
  resolve(here, "..", "..", "data"),
])
const catalog = (name: string) => JSON.parse(readFileSync(resolve(dataDir, name), "utf8"))

type Chapter = { slug: string; ordinal: number; number: string; title: string; draftNote?: string }
type Note = { slug: string; role: string; readAfter?: string; navTitle?: string }
type Theme = { id: string; ordinal: number }

const chapters: Chapter[] = catalog("chapters.json").chapters
const notes: Note[] = catalog("notes.json").notes
const themes: Theme[] = catalog("themes.json").themes

const noteSlug = (id?: string) => (id ? id.replace(/^note:/, "") : undefined)

// Top-level pages, in the order a reader should meet them.
const sequence: string[] = ["reading-path", "explore", "the-short-version"]
for (const ch of [...chapters].sort((a, b) => a.ordinal - b.ordinal)) {
  const slug = noteSlug(ch.draftNote)
  if (slug) sequence.push(slug)
  for (const n of notes) if (n.readAfter === ch.slug) sequence.push(n.slug)
}
for (const n of notes) {
  if (n.role === "foundational-note" && !sequence.includes(n.slug)) sequence.push(n.slug)
}
sequence.push("glossary")
// Then the folders, most useful first, and the themes inside their folder.
const folders = ["themes", "concepts", "mechanisms", "cases", "questions", "citations", "experiments"]
const themeOrder = [...themes].sort((a, b) => a.ordinal - b.ordinal).map((t) => t.id)

const rank: Record<string, number> = {}
;[...sequence, ...folders, ...themeOrder].forEach((slug, i) => {
  if (!(slug in rank)) rank[slug] = i
})

// Entries are named for their place in the read, not their page title:
// "Chapter 8b: Intersubjective Truth" (whatever the note calls itself) and
// "Interlude: The Medium".
const names: Record<string, string> = {}
for (const ch of chapters) {
  const slug = noteSlug(ch.draftNote)
  if (slug) names[slug] = `Chapter ${ch.number}: ${ch.title}`
}
for (const n of notes) if (n.navTitle) names[n.slug] = n.navTitle

// Folders that are not for browsing: tag listings, and the raw source files
// (each has a page under Sources).
const hidden = ["tags", "sources"]

// Ranked entries first, in rank order; everything else alphabetically, with
// numbers compared as numbers.
const sortFn = new Function(
  "a",
  "b",
  `const rank = ${JSON.stringify(rank)};
  const ra = rank[a.slugSegment], rb = rank[b.slugSegment];
  if (ra !== undefined && rb !== undefined) return ra - rb;
  if (ra !== undefined) return -1;
  if (rb !== undefined) return 1;
  return a.displayName.localeCompare(b.displayName, undefined, { numeric: true, sensitivity: "base" });`,
)

const mapFn = new Function(
  "node",
  `const names = ${JSON.stringify(names)};
  if (!node.isFolder && names[node.slugSegment]) node.displayName = names[node.slugSegment];`,
)

const filterFn = new Function(
  "node",
  `const hidden = ${JSON.stringify(hidden)};
  return !(node.isFolder && hidden.includes(node.slugSegment));`,
)

ExternalPlugin.Explorer({
  title: "Contents",
  sortFn: sortFn as never,
  mapFn: mapFn as never,
  filterFn: filterFn as never,
})

const config = await loadQuartzConfig()
export default config

// The header slot is empty in the YAML layout; put the book bar there (ways
// in, and where the current page sits). Its stylesheet also labels the
// sidebar's groups. See lossy-nav.tsx.
export const layout = await loadQuartzLayout({
  defaults: {
    header: [BookBar(dataDir)],
  },
})

// On card pages, the theme's trail goes at the top of the right sidebar (above
// the graph, table of contents and backlinks the YAML layout puts there). The
// call above returns the live layout, so adding to its arrays is enough; a
// page type with its own right-hand list gets the same addition.
const trail = ThemeTrail(dataDir)
for (const slots of [layout.defaults, ...Object.values(layout.byPageType)]) {
  if (Array.isArray(slots.right) && !slots.right.includes(trail)) slots.right.unshift(trail)
}
