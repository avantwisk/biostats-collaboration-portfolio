# Repository Guidelines

## Project Structure & Module Organization
The Quarto project lives at the repository root. `_quarto.yml` drives navigation and global settings. Content sources stay grouped by theme: `internship/` for report sections, `reflections/week-01|week-02/` for daily logs, plus `learning-outcomes/`, `coursework/`, and `artefacts/`. Assets reside in `images/`, while custom styling belongs in `styles/custom.css`. Generated HTML is emitted to `_site/`; do not edit files there directly because each render overwrites them.

## Build, Test, and Development Commands
Run commands from the repository root. `quarto preview` launches a hot-reloading dev server; add `--port 4242` if the default port conflicts. `quarto render` performs a clean production build into `_site/`. Use `quarto publish gh-pages` to push the rendered site to GitHub Pages once the build passes locally. When debugging, `quarto check` validates dependencies and project metadata.

## Coding Style & Naming Conventions
Author narrative content in Quarto Markdown with meaningful headings and limited line wrapping. Keep YAML front matter indented with two spaces to match `_quarto.yml`. Follow existing slug patterns such as `day-01.qmd` for reflections and `index.qmd` for landing pages. Store images as lowercase, hyphenated filenames in `images/`, and reference them with relative paths. Extend styling in `styles/custom.css`, using descriptive class names and concise comments for nontrivial rules.

## Testing Guidelines
Before opening a pull request, run `quarto render` and review the console for warnings. Manually inspect key pages in the rendered `_site/`, ensuring navigation links, cross-references, and downloads resolve. For navigation or configuration edits, run `quarto check` to confirm metadata consistency. Use the README quality checklist to verify reflections, artefacts, and assets stay complete.

## Commit & Pull Request Guidelines
History favours concise summary lines such as `Remove large PDFs from repo`; keep commits scoped to a single theme and use sentence case in 50 characters or fewer. Reference related reflections or artefacts in the body when context is helpful. Pull requests should describe the change, note outstanding TODOs, and include screenshots or preview URLs when layout shifts. Link coursework milestones or issues so reviewers can trace academic requirements.

## Content & Assets
Archive supporting documents in `artefacts/` and cite them from the relevant reflection. Optimise images before adding them to `images/` to keep the repository lightweight. For internship updates, refresh `internship/index.qmd` first so navigation highlights the latest summary, then cascade changes to companion pages.
