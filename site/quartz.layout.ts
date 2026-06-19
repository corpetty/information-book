import { PageLayout, SharedLayout } from "./quartz/cfg"
import * as Component from "./quartz/components"

// The Explorer sortFn lifts the chapter spine to the top in reading order so
// the sidebar reads like a table of contents; everything else (foundational
// notes, glossary, outline) follows alphabetically, and the generated
// graph-node folders (concepts, cases, mechanisms, questions, citations, …)
// collapse at the bottom.
//
// Self-contained: this is serialized with .toString() and run in the browser,
// so the reading-order list is inlined rather than closed over.
//
// CRITICAL: no nested *named* function (not even `const rank = (n) => …`).
// esbuild's keepNames wraps named functions as `__name(fn, "rank")`, and that
// wrapper survives .toString() into the Explorer's `data-data-fns` attribute,
// where the client runs it via `new Function` — a scope with no `__name`
// helper. The result is `ReferenceError: __name is not defined`, which kills
// the Explorer on every page. So the rank is inlined per-operand instead.
const readingOrderSortFn = (a: any, b: any): number => {
  const ORDER = [
    "index",
    "the-information-landscape",
    "case-studies-and-three-realities",
    "info-time-limit",
    "optionality-vs-access",
    "complexity-virality-tradeoff",
    "selection-as-other-engine",
    "truth-compression-and-when-each-wins",
    "bridge-zone-distortion",
    "emotional-memetics",
    "preservation-vs-training",
    "integration-problem",
    "political-economy-of-attention",
    "ai-as-new-node",
    "infrastructure-for-integration",
  ]
  // rank: chapters in reading order (0..N), then other root files (1e6),
  // then folders (2e6). Lower sorts first. Inlined per-operand (see above).
  const ra = a.isFolder ? 2_000_000 : ORDER.indexOf(a.slug ?? "") === -1 ? 1_000_000 : ORDER.indexOf(a.slug ?? "")
  const rb = b.isFolder ? 2_000_000 : ORDER.indexOf(b.slug ?? "") === -1 ? 1_000_000 : ORDER.indexOf(b.slug ?? "")
  if (ra !== rb) return ra - rb
  return a.displayName.localeCompare(b.displayName, undefined, {
    numeric: true,
    sensitivity: "base",
  })
}

// components shared across all pages
export const sharedPageComponents: SharedLayout = {
  head: Component.Head(),
  header: [],
  afterBody: [],
  footer: Component.Footer({
    links: {
      "The book on GitHub": "https://github.com/corpetty/information-book",
    },
  }),
}

// components for pages that display a single page (e.g. a single note)
export const defaultContentPageLayout: PageLayout = {
  beforeBody: [
    Component.ConditionalRender({
      component: Component.Breadcrumbs(),
      condition: (page) => page.fileData.slug !== "index",
    }),
    Component.ArticleTitle(),
    Component.ContentMeta(),
    Component.TagList(),
  ],
  left: [
    Component.PageTitle(),
    Component.MobileOnly(Component.Spacer()),
    Component.Flex({
      components: [
        {
          Component: Component.Search(),
          grow: true,
        },
        { Component: Component.Darkmode() },
        { Component: Component.ReaderMode() },
      ],
    }),
    Component.Explorer({
      title: "Contents",
      sortFn: readingOrderSortFn,
    }),
  ],
  right: [
    Component.Graph({
      // Local graph: the page's immediate neighbourhood. Drop the ubiquitous
      // tags so it shows real argument links, not tag co-membership.
      localGraph: {
        depth: 1,
        scale: 1.1,
        removeTags: ["information", "graph-node", "citation"],
      },
      // Global graph: the whole book. Tags off entirely — with `information`
      // on nearly every page, tag nodes collapse the structure into one hub;
      // the wikilink/citation structure is what's worth seeing.
      globalGraph: {
        depth: -1,
        showTags: false,
        focusOnHover: true,
        enableRadial: true,
      },
    }),
    Component.DesktopOnly(Component.TableOfContents()),
    Component.Backlinks(),
  ],
}

// components for pages that display lists of pages  (e.g. tags or folders)
export const defaultListPageLayout: PageLayout = {
  beforeBody: [Component.Breadcrumbs(), Component.ArticleTitle(), Component.ContentMeta()],
  left: [
    Component.PageTitle(),
    Component.MobileOnly(Component.Spacer()),
    Component.Flex({
      components: [
        {
          Component: Component.Search(),
          grow: true,
        },
        { Component: Component.Darkmode() },
      ],
    }),
    Component.Explorer({
      title: "Contents",
      sortFn: readingOrderSortFn,
    }),
  ],
  right: [],
}
