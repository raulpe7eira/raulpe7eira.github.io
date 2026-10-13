# CLAUDE.md

## Project Overview

Personal website for Raul Pereira (raulpe7eira) — a software engineer with 20+ years of experience. Hosted on GitHub Pages at https://raulpe7eira.tech.

## Architecture

The published site lives in `docs/` (GitHub Pages source: branch `main`, folder `/docs`; `docs/.nojekyll` disables Jekyll). Everything outside `docs/` (README, LICENSE, this file, future generator) is not served.

Two static HTML pages — `docs/index.html` (English, served at `/`) and `docs/pt/index.html` (Portuguese, served at `/pt/`) — with no build tools, no dependencies, and no frameworks. Styles and scripts are shared files under `docs/assets/`; SVG icons stay inline in the HTML.

**Any text or markup change must be made in both pages** (translated where applicable), keeping them in sync. Style and script changes go in `docs/assets/` and apply to all pages at once. Local paths are root-absolute (e.g. `/images/cover.jpg`, `/assets/css/base.css`), so test with a local server rooted at `docs/`, not `file://`.

There are also two resume pages — `resume/index.html` (English, `/resume/`) and `pt/resume/index.html` (Portuguese, `/pt/resume/`) — generated from the LinkedIn export. They share the home pages' header (avatar + name + subtitle linking to the home), toolbar (Resume/Currículo toggle, EN/PT, theme) and footer. **Any markup change to these shared parts must be made in all 4 pages** (`docs/index.html`, `docs/pt/index.html`, `docs/resume/index.html`, `docs/pt/resume/index.html`); their styles and scripts are already shared via `docs/assets/`.

## Key Files (all under `docs/`)

- `index.html` — English page
- `pt/index.html` — Portuguese (PT-BR) page, same structure as `index.html`
- `resume/index.html` — English resume page (generated from the LinkedIn data)
- `pt/resume/index.html` — Portuguese resume page, same structure as `resume/index.html`
- `assets/css/base.css` — shared styles (tokens, 9 themes as `html[data-theme=…]`, layout, header, toolbar, footer)
- `assets/css/resume.css` — resume-only styles, scoped under `.rs`
- `assets/js/theme.js` — theme panel; a one-line inline script in each `<head>` applies the saved theme before first paint
- `assets/js/nav.js` — Resume/Currículo toggle (slide, then navigate) and the header intro on entry/reload
- `resume/raul-pereira-da-silva-resume.pdf` / `pt/resume/raul-pereira-da-silva-curriculo.pdf` — downloadable resume PDFs
- `resume/thumb.png` / `pt/resume/thumb.png` — resume thumbnails
- `resume/lg/` — company/client logos used by both resume pages (`sq-*` square employer logos, `cl-*` client logos)
- `CNAME` — custom domain config (`raulpe7eira.tech`)
- `.nojekyll` — serve files as-is (no Jekyll)
- `404.html` — any unknown address redirects to the home page (`/pt/` for paths under `/pt`)
- `robots.txt` — search engine directives
- `sitemap.xml` — sitemap for search engines
- `llms.txt` — LLM-readable site description
- `images/cover.jpg` — hero background image
- `images/og-image.jpg` — social preview image
- `images/favicons/` — all favicon and app icon files

## Features

- **Bilingual**: English (`/`, default) and Portuguese (`/pt/`) as separate indexable pages, linked via `hreflang` alternates (in `<head>` and `sitemap.xml`); the EN/PT button is a link to the other page
- **Resume**: `/resume/` and `/pt/resume/`, reached via the Resume/Currículo toggle in the toolbar and the "professional experience" link; listed in `sitemap.xml` and `llms.txt`
- **9 themes**: Dracula (default), Nord, Gruvbox, Catppuccin, Solarized Dark, Tokyo Night, Rose Pine, One Dark, Dark — defined in `base.css`, selected via `data-theme` on `<html>`, persisted in localStorage (`theme`)
- **SEO**: Open Graph, Twitter Card, JSON-LD (Person schema), canonical URL, meta description, hreflang alternates — all localized per page
- **Analytics**: Google Analytics (G-4QXLD8YPLP, loaded by `docs/assets/js/analytics.js` only on raulpe7eira.tech) + Plausible Analytics (site script `pa-*.js`, init in `analytics.js`; outbound links and file downloads toggled in the Plausible dashboard; ignores localhost by itself)
- **Social icons**: GitHub, LinkedIn, X, Bluesky, Instagram, Facebook, Strava, IMDb, Last.fm, Email — using inline SVG from Simple Icons
- **Responsive**: 3 breakpoints (480px, 768px, 1200px)
- **Accessibility**: Semantic HTML, ARIA labels, keyboard navigable

## Tech Stack

- Plain HTML/CSS/JS (no build step; resume pages are generated offline)
- Google Fonts (Inter)
- GitHub Pages (static hosting)
- CSS custom properties for theming

## Conventions

- No inline `style="…"` attributes, `<style>` blocks or `onclick` handlers (except the standalone `404.html`): CSS in `docs/assets/css/`, JS in `docs/assets/js/` (loaded with `defer`); the only inline script is the head theme snippet
- Theme colors use CSS variables (`--bg`, `--fg`, `--comment`, `--cyan`, `--green`, `--orange`, `--pink`, `--purple`, `--red`, `--yellow`)
- Footer colors (heart red, R3M green, TECH purple) and theme-panel swatches are fixed in `base.css` and do not change with themes; hovering the footer link scales it and makes the heart beat
- Header hover grows the header and spins the avatar; when the site is entered, reloaded or opened in a new tab (not on internal navigation or back/forward) `nav.js` replays that hover once via the `.intro` class; disabled with `prefers-reduced-motion`
- External links use `target="_blank" rel="noopener noreferrer"`
- Portuguese content elements have `-pt` suffix IDs, English have `-en` suffix
- SVG icons use `viewBox="0 0 24 24"` from Simple Icons
