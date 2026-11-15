#!/usr/bin/env node
// Serve the built site (site/public/) the way GitHub Pages does.
//
// Quartz emits extensionless links (`./themes/how-ideas-travel`), which Pages
// resolves to `how-ideas-travel.html` or `how-ideas-travel/index.html`. A plain
// static server (python -m http.server) does not, so every in-page link 404s
// in a local preview even though the deployed site is fine. This server
// applies the same resolution, and serves 404.html for a real miss.
//
// Usage: node scripts/serve-site.js [port]      (default 8766)
// Via make: `make site-preview` (after `make site-build`).

import { createServer } from 'node:http';
import { readFileSync, existsSync, statSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, resolve, join, extname, normalize } from 'node:path';

const __dirname = dirname(fileURLToPath(import.meta.url));
const root = resolve(__dirname, '..', 'site', 'public');
const port = Number(process.argv[2]) || 8766;

if (!existsSync(root)) {
  console.error('serve-site: site/public/ not found — run `make site-build` first');
  process.exit(1);
}

const TYPES = {
  '.html': 'text/html; charset=utf-8', '.css': 'text/css; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8', '.json': 'application/json; charset=utf-8',
  '.jsonl': 'application/x-ndjson; charset=utf-8', '.xml': 'application/xml; charset=utf-8',
  '.svg': 'image/svg+xml', '.png': 'image/png', '.jpg': 'image/jpeg', '.jpeg': 'image/jpeg',
  '.webp': 'image/webp', '.gif': 'image/gif', '.ico': 'image/x-icon', '.pdf': 'application/pdf',
  '.woff': 'font/woff', '.woff2': 'font/woff2', '.txt': 'text/plain; charset=utf-8',
  '.md': 'text/markdown; charset=utf-8',
};

const isFile = (p) => existsSync(p) && statSync(p).isFile();

// Pages' resolution order: the path itself, then .html, then /index.html.
function resolveFile(urlPath) {
  const rel = normalize(decodeURIComponent(urlPath)).replace(/^(\.\.[/\\])+/, '');
  const base = join(root, rel);
  if (!base.startsWith(root)) return null;
  for (const candidate of [base, `${base}.html`, join(base, 'index.html')]) {
    if (isFile(candidate)) return candidate;
  }
  return null;
}

createServer((req, res) => {
  const urlPath = new URL(req.url, 'http://localhost').pathname;
  let file = null;
  try { file = resolveFile(urlPath); } catch { /* malformed escape → 404 */ }
  let status = 200;
  if (!file) {
    status = 404;
    file = join(root, '404.html');
    if (!isFile(file)) { res.writeHead(404, { 'Content-Type': 'text/plain' }); res.end('404'); return; }
  }
  res.writeHead(status, {
    'Content-Type': TYPES[extname(file).toLowerCase()] || 'application/octet-stream',
    'Cache-Control': 'no-store',
  });
  res.end(readFileSync(file));
}).listen(port, () => {
  console.log(`serve-site: http://localhost:${port}/  (site/public, GitHub Pages URL resolution)`);
});
