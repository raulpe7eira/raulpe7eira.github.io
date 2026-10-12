# CLAUDE.md

## Project Overview

Personal website for Raul Pereira (raulpe7eira) — a software engineer with 20+ years of experience. Hosted on GitHub Pages at https://raulpe7eira.tech.

## Architecture

Two static HTML pages — `index.html` (English, served at `/`) and `pt/index.html` (Portuguese, served at `/pt/`) — with no build tools, no dependencies, and no frameworks. Each page is self-contained: CSS, JavaScript, and SVG icons are inline and duplicated in both files.

**Any text, markup, style, or script change must be made in both pages** (translated where applicable), keeping them in sync. In `pt/index.html`, local asset paths use `../` (e.g. `../images/cover.jpg`).

## Key Files

- `index.html` — English page (HTML + CSS + JS in one file)
- `pt/index.html` — Portuguese (PT-BR) page, same structure as `index.html`
- `CNAME` — custom domain config (`raulpe7eira.tech`)
- `robots.txt` — search engine directives
- `sitemap.xml` — sitemap for search engines
- `404.html` — custom error page
- `llms.txt` — LLM-readable site description
- `images/cover.jpg` — hero background image
- `images/favicons/` — all favicon and app icon files (31 files)

## Features

- **Bilingual**: English (`/`, default) and Portuguese (`/pt/`) as separate indexable pages, linked via `hreflang` alternates (in `<head>` and `sitemap.xml`); the EN/PT button is a link to the other page
- **9 themes**: Dracula (default), Nord, Gruvbox, Catppuccin, Solarized Dark, Tokyo Night, Rose Pine, One Dark, Dark — persisted in localStorage
- **SEO**: Open Graph, Twitter Card, JSON-LD (Person schema), canonical URL, meta description, hreflang alternates — all localized per page
- **Analytics**: Google Analytics (G-4QXLD8YPLP) + Plausible Analytics
- **Social icons**: GitHub, LinkedIn, X, Bluesky, Instagram, Facebook, Strava, IMDb, Last.fm, Email — using inline SVG from Simple Icons
- **Responsive**: 3 breakpoints (480px, 768px, 1200px)
- **Accessibility**: Semantic HTML, ARIA labels, keyboard navigable

## Tech Stack

- Plain HTML/CSS/JS (no build step)
- Google Fonts (Inter)
- GitHub Pages (static hosting)
- CSS custom properties for theming

## Conventions

- All CSS is in a `<style>` tag in the `<head>`
- All JS is in a `<script>` tag before `</body>`
- Theme colors use CSS variables (`--bg`, `--fg`, `--comment`, `--cyan`, `--green`, `--orange`, `--pink`, `--purple`, `--red`, `--yellow`)
- Footer colors (heart red, R3M green, TECH purple) are hardcoded and do not change with themes
- External links use `target="_blank" rel="noopener noreferrer"`
- Portuguese content elements have `-pt` suffix IDs, English have `-en` suffix
- SVG icons use `viewBox="0 0 24 24"` from Simple Icons
