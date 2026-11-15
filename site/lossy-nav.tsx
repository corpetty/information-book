// Lossy: the header bar and the sidebar's group labels.
//
// Two things the stock Quartz components cannot do, both driven by the
// ontology catalogs in ../data so they follow the book's structure:
//
//   BookBar        a slim bar above every page title. Left: the ways in
//                  (Read / Explore / Map / Glossary), with the current one
//                  marked. Right: where this page sits ("Part II · 6 of 18"
//                  for a chapter or interlude; "theme name · 2 of 17" for a
//                  card; "Theme 3 of 13" for a theme).
//
//                  On pages outside the read it also offers "Continue:
//                  Chapter 5b →", remembered in the reader's own browser.
//
//   sidebar labels the Explorer is a flat, ordered list (see quartz.ts). CSS
//                  ::before labels on the first entry of each group turn it
//                  into Start here / Part I … Part IV / Depth notes /
//                  Reference / Browse, without touching the Explorer itself.
//
//   ThemeTrail     on a card page, the cards of its theme in trail order
//                  with the current one marked. The sidebar lists cards by
//                  type (it mirrors the folders); this is where a reader sees
//                  them by theme.
//
// Used from quartz.ts: BookBar fills the (otherwise empty) `header` slot and
// ThemeTrail is added to the right sidebar. Both render at build time, so
// they read the catalogs directly; only the "continue" script runs in the
// browser.

import { existsSync, readFileSync } from "node:fs"
import { resolve } from "node:path"
import type { QuartzComponent, QuartzComponentProps } from "./quartz/components/types"
import { pathToRoot } from "./quartz/util/path"

type Part = { slug: string; ordinal: number; short: string; name: string }
type Chapter = { slug: string; ordinal: number; number: string; part: string; draftNote?: string }
type Note = { slug: string; role: string; readAfter?: string; navTitle?: string }
type Theme = { id: string; ordinal: number; label: string; members: string[] }
type Card = { id: string; label: string }

export function loadCatalogs(dataDir: string) {
  const read = (name: string) => JSON.parse(readFileSync(resolve(dataDir, name), "utf8"))
  return {
    parts: read("parts.json").parts as Part[],
    chapters: read("chapters.json").chapters as Chapter[],
    notes: read("notes.json").notes as Note[],
    themes: read("themes.json").themes as Theme[],
    cards: {
      concept: read("concepts.json").concepts as Card[],
      mechanism: read("mechanisms.json").mechanisms as Card[],
      case: read("case-studies.json").caseStudies as Card[],
      question: read("questions.json").questions as Card[],
    } as Record<string, Card[]>,
  }
}

export function findDataDir(candidates: string[]): string {
  const dir = candidates.find((d) => existsSync(resolve(d, "chapters.json")))
  if (!dir) throw new Error("cannot find the ontology catalogs (data/chapters.json); run the build from site/")
  return dir
}

const noteSlug = (id?: string) => (id ? id.replace(/^note:/, "") : undefined)
const CARD_DIRS: Record<string, string> = {
  concept: "concepts",
  mechanism: "mechanisms",
  case: "cases",
  question: "questions",
}

// A label without its gloss: "Arsenic-life (Wolfe-Simon et al. 2010): died at
// consensus" reads as "Arsenic-life" in a list.
const shortLabel = (label: string) => {
  const cut = label.split(/ \(|: | — /)[0].trim()
  return cut.length >= 4 ? cut : label
}

/** Everything the bar, the labels and the trail need, worked out once. */
export function buildNavModel(dataDir: string) {
  const { parts, chapters, notes, themes, cards } = loadCatalogs(dataDir)
  const partBySlug = new Map(parts.map((p) => [p.slug, p]))
  const noteSlugs = new Set(notes.map((n) => n.slug))

  // The linear read: chapters by ordinal, each followed by its interludes.
  const read: { slug: string; part: Part; label: string }[] = []
  for (const ch of [...chapters].sort((a, b) => a.ordinal - b.ordinal)) {
    const part = partBySlug.get(ch.part)!
    const slug = noteSlug(ch.draftNote)
    if (slug) read.push({ slug, part, label: `Chapter ${ch.number}` })
    for (const n of notes) {
      if (n.readAfter === ch.slug) read.push({ slug: n.slug, part, label: n.navTitle ?? n.slug })
    }
  }
  const depthNotes = notes.filter((n) => n.role === "foundational-note").map((n) => n.slug)

  // slug → position text (and, for cards, the theme to link to)
  const position = new Map<string, { text: string; href?: string }>()
  read.forEach((r, i) => position.set(r.slug, { text: `${r.part.short} · ${i + 1} of ${read.length}` }))
  const orderedThemes = [...themes].sort((a, b) => a.ordinal - b.ordinal)
  // card page slug → its theme's trail
  const trails = new Map<string, { theme: Theme; items: { slug: string; label: string }[] }>()
  orderedThemes.forEach((t, ti) => {
    position.set(`themes/${t.id}`, { text: `Theme ${ti + 1} of ${orderedThemes.length}` })
    const items = t.members.flatMap((id) => {
      const [kind, slug] = id.split(":")
      const dir = CARD_DIRS[kind]
      const card = cards[kind]?.find((c) => c.id === slug)
      if (!dir || !card) return []
      // A card that shares its slug with a note has no card page: the note is its page.
      return [{ slug: noteSlugs.has(slug) ? slug : `${dir}/${slug}`, label: shortLabel(card.label) }]
    })
    items.forEach((item, i) => {
      if (!item.slug.includes("/")) return // a note, with its own place in the read
      position.set(item.slug, { text: `${t.label} · ${i + 1} of ${items.length}`, href: `themes/${t.id}` })
      trails.set(item.slug, { theme: t, items })
    })
  })

  // First entry of each sidebar group → its label.
  const labels: { slug?: string; folder?: string; label: string }[] = [{ slug: "reading-path", label: "Start here" }]
  let lastPart: string | undefined
  for (const r of read) {
    if (r.part.slug !== lastPart) labels.push({ slug: r.slug, label: `${r.part.short}: ${r.part.name}` })
    lastPart = r.part.slug
  }
  if (depthNotes.length) labels.push({ slug: depthNotes[0], label: "Depth notes" })
  labels.push({ slug: "glossary", label: "Reference" })
  labels.push({ folder: "themes", label: "Browse" })

  return {
    readSlugs: new Set([...read.map((r) => r.slug), ...depthNotes, "reading-path"]),
    // slug → short name, for the "Continue" link (chapters and interludes only)
    readLabels: Object.fromEntries(read.map((r) => [r.slug, r.label])),
    position,
    labels,
    trails,
  }
}

type Mode = "read" | "explore" | "glossary" | undefined

function modeOf(slug: string, readSlugs: Set<string>): Mode {
  if (slug === "glossary") return "glossary"
  if (slug === "explore" || /^(themes|concepts|mechanisms|cases|questions)\//.test(slug)) return "explore"
  if (readSlugs.has(slug) || slug === "the-short-version") return "read"
  return undefined
}

export function BookBar(dataDir: string): QuartzComponent {
  const model = buildNavModel(dataDir)

  const Bar: QuartzComponent = ({ fileData }: QuartzComponentProps) => {
    const slug = String(fileData.slug ?? "")
    const root = pathToRoot(slug as never)
    const to = (target: string) => `${root}/${target}`
    const mode = modeOf(slug, model.readSlugs)
    const pos = model.position.get(slug)
    const item = (m: Mode, href: string, label: string, title: string) => (
      <a href={href} class={m && m === mode ? "book-bar-link is-current" : "book-bar-link"} title={title}>
        {label}
      </a>
    )
    return (
      <nav class="book-bar" aria-label="Ways into the book" data-read={JSON.stringify(model.readLabels)}>
        <div class="book-bar-modes">
          {item("read", to("reading-path"), "Read", "The chapters in order, each in a sentence or two")}
          {item("explore", to("explore"), "Explore", "Every idea on its own short page, grouped by theme")}
          <a href={to("graph/")} class="book-bar-link" data-router-ignore="true" title="The whole argument as an interactive map">
            Map
          </a>
          {item("glossary", to("glossary"), "Glossary", "Plain-language definitions")}
        </div>
        <a class="book-bar-continue" hidden></a>
        {pos && (
          <div class="book-bar-position">
            {pos.href ? <a href={to(pos.href)}>{pos.text}</a> : pos.text}
          </div>
        )}
      </nav>
    )
  }

  const quote = (s: string) => `"${s.replace(/\\/g, "\\\\").replace(/"/g, '\\"')}"`
  const labelRules = model.labels
    .map((l) => {
      const selector = l.folder
        ? `.explorer-ul > li:has(> .folder-container[data-folderpath^="${l.folder}"])`
        : `.explorer-ul > li:has(> a[href$="/${l.slug}"])`
      return `${selector}::before { content: ${quote(l.label)}; }`
    })
    .join("\n")
  const labelSelectors = model.labels
    .map((l) =>
      l.folder
        ? `.explorer-ul > li:has(> .folder-container[data-folderpath^="${l.folder}"])::before`
        : `.explorer-ul > li:has(> a[href$="/${l.slug}"])::before`,
    )
    .join(",\n")

  Bar.css = `
.book-bar {
  display: flex;
  flex-wrap: wrap;
  align-items: baseline;
  justify-content: space-between;
  gap: 0.25rem 1.5rem;
  margin: 0 0 1rem;
  padding-bottom: 0.5rem;
  border-bottom: 1px solid var(--lightgray);
  font-size: 0.85rem;
}
.book-bar-modes {
  display: flex;
  flex-wrap: wrap;
  gap: 0.25rem 1.1rem;
}
.book-bar-link {
  color: var(--darkgray);
  font-weight: 600;
  text-decoration: none;
  background: none;
  padding: 0;
}
.book-bar-link:hover {
  color: var(--secondary);
}
.book-bar-link.is-current {
  color: var(--secondary);
  box-shadow: 0 2px 0 var(--secondary);
}
.book-bar-position {
  color: var(--gray);
}
.book-bar-continue {
  color: var(--secondary);
  font-weight: 600;
  text-decoration: none;
  background: none;
  padding: 0;
}
.book-bar-continue[hidden] {
  display: none;
}
.book-bar-position a {
  color: inherit;
  background: none;
  padding: 0;
  text-decoration: underline;
  text-underline-offset: 0.2em;
}

/* Sidebar group labels: the first entry of each group carries its heading. */
${labelSelectors} {
  display: block;
  margin: 0.9rem 0 0.25rem;
  font-size: 0.72rem;
  font-weight: 700;
  letter-spacing: 0.07em;
  text-transform: uppercase;
  color: var(--gray);
}
.explorer-ul > li:first-child::before {
  margin-top: 0.1rem;
}
${labelRules}
`
  // "Continue where you left off". On a chapter or interlude, remember it (in
  // this browser only). Anywhere else, offer a link back to it. Runs on every
  // page view; Quartz fires "nav" on first load and on each in-site navigation.
  Bar.afterDOMLoaded = `
document.addEventListener("nav", () => {
  const bar = document.querySelector(".book-bar")
  const link = bar && bar.querySelector(".book-bar-continue")
  if (!bar || !link) return
  let names = {}
  try { names = JSON.parse(bar.dataset.read || "{}") } catch {}
  const slug = document.body.dataset.slug || ""
  const KEY = "lossy-last-read"
  try {
    if (names[slug]) {
      localStorage.setItem(KEY, JSON.stringify({ slug, path: location.pathname }))
      link.hidden = true
      return
    }
    const saved = JSON.parse(localStorage.getItem(KEY) || "null")
    if (saved && names[saved.slug]) {
      link.textContent = "Continue: " + names[saved.slug] + " \u2192"
      link.href = saved.path
      link.hidden = false
    } else {
      link.hidden = true
    }
  } catch {
    link.hidden = true
  }
})
`
  return Bar
}

export function ThemeTrail(dataDir: string): QuartzComponent {
  const model = buildNavModel(dataDir)

  const Trail: QuartzComponent = ({ fileData, displayClass }: QuartzComponentProps) => {
    const slug = String(fileData.slug ?? "")
    const trail = model.trails.get(slug)
    if (!trail) return null
    const root = pathToRoot(slug as never)
    return (
      <div class={displayClass ? `theme-trail ${displayClass}` : "theme-trail"}>
        <h3>
          <a href={`${root}/themes/${trail.theme.id}`}>{trail.theme.label}</a>
        </h3>
        <ol>
          {trail.items.map((item) =>
            item.slug === slug ? (
              <li class="is-current" aria-current="page">
                {item.label}
              </li>
            ) : (
              <li>
                <a href={`${root}/${item.slug}`}>{item.label}</a>
              </li>
            ),
          )}
        </ol>
      </div>
    )
  }

  Trail.css = `
.theme-trail h3 {
  margin: 0 0 0.4rem;
  font-size: 1rem;
}
.theme-trail h3 a {
  color: var(--dark);
  background: none;
  padding: 0;
  text-decoration: none;
}
.theme-trail ol {
  margin: 0;
  padding-left: 1.6rem;
  max-height: 16rem;
  overflow-y: auto;
  font-size: 0.85rem;
  line-height: 1.5;
}
.theme-trail li {
  color: var(--gray);
}
.theme-trail li a {
  color: var(--darkgray);
  background: none;
  padding: 0;
  text-decoration: none;
}
.theme-trail li a:hover {
  color: var(--secondary);
}
.theme-trail li.is-current {
  color: var(--secondary);
  font-weight: 600;
}
`
  return Trail
}
