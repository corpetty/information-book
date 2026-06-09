import { PageLayout, SharedLayout } from "./quartz/cfg"
import * as Component from "./quartz/components"
import { Options as ExplorerOptions } from "./quartz/components/Explorer"

// Order the Explorer sidebar by the book's reading order (the prev/next chapter
// spine), instead of alphabetically. The list MUST stay inside this function:
// Quartz serializes sortFn with .toString() and re-evals it in the browser, so it
// cannot reference anything declared outside its own body. Slugs not listed here
// fall back to Quartz's default (folders first, then alphabetical).
const bookOrderSortFn: ExplorerOptions["sortFn"] = (a, b) => {
  const order = [
    // The 14-chapter spine, in reading order
    "the-information-landscape", // Ch 1
    "case-studies-and-three-realities", // Ch 2
    "info-time-limit", // Ch 3
    "optionality-vs-access", // Ch 4
    "complexity-virality-tradeoff", // Ch 5
    "selection-as-other-engine", // Ch 5b
    "truth-compression-and-when-each-wins", // Ch 5c
    "bridge-zone-distortion", // Ch 6
    "emotional-memetics", // Ch 7
    "preservation-vs-training", // Ch 8
    "integration-problem", // Ch 9
    "political-economy-of-attention", // Ch 10
    "ai-as-new-node", // Ch 11
    "infrastructure-for-integration", // Ch 12
    // Supporting material
    "glossary",
    "outline",
    "transport-vs-selection",
    "medium-and-manipulation",
    "three-layer-message",
    "myths-scale-and-bureaucracy",
    "bridge-nodes-and-versatile-expertise",
    "capture-taxonomy",
    "the-abyss",
    "general-theme",
  ]

  const ia = order.indexOf(a.slugSegment)
  const ib = order.indexOf(b.slugSegment)
  if (ia !== -1 && ib !== -1) return ia - ib
  if (ia !== -1) return -1
  if (ib !== -1) return 1

  // Fallback: Quartz default — folders first, then alphabetical
  if ((!a.isFolder && !b.isFolder) || (a.isFolder && b.isFolder)) {
    return a.displayName.localeCompare(b.displayName, undefined, {
      numeric: true,
      sensitivity: "base",
    })
  }
  return !a.isFolder && b.isFolder ? 1 : -1
}

// components shared across all pages
export const sharedPageComponents: SharedLayout = {
  head: Component.Head(),
  header: [],
  afterBody: [],
  footer: Component.Footer({
    links: {
      GitHub: "https://github.com/jackyzha0/quartz",
      "Discord Community": "https://discord.gg/cRFFHYye7t",
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
    Component.Explorer({ sortFn: bookOrderSortFn }),
  ],
  right: [
    Component.Graph(),
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
    Component.Explorer({ sortFn: bookOrderSortFn }),
  ],
  right: [],
}
