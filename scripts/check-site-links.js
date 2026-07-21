#!/usr/bin/env node
// Internal-link checker for the built Quartz site (site/public/).
//
// Walks every .html file, extracts href/src targets, and verifies each
// internal link resolves to a file that exists. Quartz emits pretty URLs:
// a link to `./foo` is served by `foo.html` or `foo/index.html`, and a
// directory link (`graph/`, `.`, `..`) by its `index.html`. The resolver
// mirrors that.
//
// External links (http/https/mailto/protocol-relative), pure in-page
// anchors (#section), and data: URIs are out of scope — this checks the
// site's own internal integrity, the class that silently 404s for readers
// (e.g. a citation page linking a PDF the build excluded).
//
// Exit 1 with a report if any internal link is broken. Run in CI after
// `make site-build`; locally: `node scripts/check-site-links.js`.

import { readFileSync, existsSync, readdirSync, statSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, resolve, relative, join } from 'node:path';

const __dirname = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(__dirname, '..');
const publicDir = resolve(repoRoot, 'site', 'public');

if (!existsSync(publicDir)) {
  console.error('check-site-links: site/public/ not found — run `make site-build` first');
  process.exit(1);
}

// Root-absolute links (notably in 404.html, which can't use relative paths)
// carry the deploy baseUrl path prefix, e.g. /information-book/static/….
// On GitHub Pages that prefix IS the site root; locally there's no such
// directory. Read it from quartz.config.yaml and strip it so absolute links
// resolve against publicDir the way they do on the deployment.
function basePathPrefix() {
  const cfg = readFileSync(resolve(repoRoot, 'site', 'quartz.config.yaml'), 'utf8');
  // YAML: `baseUrl: lossybook.com` (quotes optional; ignore trailing comments).
  const m = cfg.match(/^\s*baseUrl:\s*["']?([^"'\n#]+?)["']?\s*(?:#.*)?$/m);
  if (!m) return '';
  const url = m[1].trim();
  const path = url.includes('/') ? url.slice(url.indexOf('/')) : '';
  return path.replace(/\/$/, ''); // '/information-book'
}
const BASE_PREFIX = basePathPrefix();

function walk(dir) {
  const out = [];
  for (const e of readdirSync(dir, { withFileTypes: true })) {
    const p = join(dir, e.name);
    if (e.isDirectory()) out.push(...walk(p));
    else if (e.name.endsWith('.html')) out.push(p);
  }
  return out;
}

// Does a target path (absolute, no query/fragment) resolve to a real file
// under publicDir, honouring Quartz pretty-URL forms?
function resolves(absPath) {
  const candidates = [absPath];
  if (!/\.[a-z0-9]+$/i.test(absPath)) candidates.push(`${absPath}.html`);
  candidates.push(join(absPath, 'index.html'));
  return candidates.some(c => existsSync(c) && statSync(c).isFile());
}

const SKIP = /^(https?:|mailto:|tel:|data:|javascript:|#|\/\/)/i;
const htmlFiles = walk(publicDir);
const broken = [];
let checked = 0;

for (const file of htmlFiles) {
  const html = readFileSync(file, 'utf8');
  const fileDir = dirname(file);
  // href="…" and src="…" (single or double quoted)
  for (const m of html.matchAll(/(?:href|src)=["']([^"']+)["']/gi)) {
    const raw = m[1].trim();
    if (!raw || SKIP.test(raw)) continue;
    // Strip query + fragment; a bare fragment was already skipped above.
    const path = raw.split('#')[0].split('?')[0];
    if (!path) continue;
    checked++;
    let rooted = path;
    if (BASE_PREFIX && (rooted === BASE_PREFIX || rooted.startsWith(BASE_PREFIX + '/'))) {
      rooted = rooted.slice(BASE_PREFIX.length) || '/';
    }
    const abs = rooted.startsWith('/')
      ? join(publicDir, rooted)
      : resolve(fileDir, rooted);
    // Guard against links escaping the published tree.
    if (!abs.startsWith(publicDir)) {
      broken.push({ file, raw, reason: 'escapes site root' });
      continue;
    }
    if (!resolves(abs)) {
      broken.push({ file, raw, reason: 'target missing' });
    }
  }
}

console.log(`check-site-links: ${checked} internal links across ${htmlFiles.length} pages`);
if (broken.length) {
  console.error(`  ${broken.length} broken:`);
  for (const b of broken) {
    console.error(`    ${relative(publicDir, b.file)} → ${b.raw}  (${b.reason})`);
  }
  process.exit(1);
}
console.log('  all internal links resolve');
