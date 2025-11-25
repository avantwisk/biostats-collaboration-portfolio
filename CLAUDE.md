# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Quarto-based portfolio website for the MSc Biostatistics "Biostatistical Consulting & Collaboration" module at Stellenbosch University. The portfolio documents a 3-month internship at Scigenix Pty (Ltd), daily reflections following the Gibbs Reflective Cycle, learning outcomes, and supporting artefacts.

## Build & Development Commands

All commands should be run from the repository root.

### Preview the Website (Development)
```bash
quarto preview
```
- Starts a local development server with live reload
- Opens in default browser at `http://localhost:XXXX`
- Automatically reloads when `.qmd` files are saved
- Use `--port 4242` if the default port conflicts

### Render the Website (Production)
```bash
quarto render
```
- Generates complete HTML site to `docs/` directory (configured as `output-dir` in `_quarto.yml`)
- Processes all `.qmd` files matching patterns in `_quarto.yml` render section
- Note: Output goes to `docs/` not `_site/` (as configured in project settings)

### Validate Installation & Configuration
```bash
quarto check
```
- Validates Quarto installation and project metadata
- Useful for debugging configuration issues

### Publish to GitHub Pages
```bash
quarto publish gh-pages
```
- Pushes rendered site to GitHub Pages
- Only run after local build succeeds

## Architecture & Structure

### Quarto Configuration
- **`_quarto.yml`**: Central configuration file controlling navigation, theming, and build behavior
  - `project.output-dir: docs` - builds to `docs/` for GitHub Pages compatibility
  - `project.render` - lists specific patterns/files to render (not all .qmd files are rendered)
  - `website.navbar` - top navigation menu with dropdowns
  - `website.sidebar` - contextual sidebars for internship and reflections sections
  - `format.html` - global HTML settings including theme (cosmo), grid layout, and custom CSS

### Content Organization
Content is organized thematically into top-level directories:

- **`internship/*.qmd`**: Internship report sections (introduction, learning objectives, work outputs, reflection, relation to coursework)
- **`reflections/week-01/*.qmd` & `reflections/week-02/*.qmd`**: Daily reflections following Gibbs Reflective Cycle
  - Week 1 (Block 2): 4 days covering professional conduct, scientific writing, collaboration, leadership
  - Week 2 (Block 1): 3 days covering ASCCR framework, POWER structure, practice consultations
- **`learning-outcomes/index.qmd`**: Evidence of module learning outcome achievement (currently commented out in navbar)
- **`coursework/index.qmd`**: Integration with broader MSc curriculum (currently commented out in navbar)
- **`artefacts/index.qmd`**: Repository of supporting evidence and work samples
- **`index.qmd`**: Portfolio home page with student introduction and navigation

### Assets & Styling
- **`images/`**: Image assets (headshot, logos, etc.)
- **`styles/custom.css`**: Custom CSS extending the cosmo theme
- **`artefacts/files/`**: Supporting documents referenced from reflections
- **`docs/`**: Build output directory (do not edit directly - regenerated on each render)

### Navigation Pattern
The site uses two navigation mechanisms:
1. **Top navbar**: Global navigation with dropdown menus (configured in `_quarto.yml` → `website.navbar`)
2. **Contextual sidebars**: Appear on internship and reflection pages (configured in `_quarto.yml` → `website.sidebar`)
   - Each sidebar has an `id` (e.g., `internship`, `reflections`)
   - Pages must specify `sidebar: internship` or `sidebar: reflections` in their YAML frontmatter to activate the appropriate sidebar

## Content Authoring Guidelines

### Quarto Markdown (.qmd) Files
- Use meaningful section headings (##, ###) for navigation and TOC generation
- Keep YAML frontmatter indented with 2 spaces to match project conventions
- Use relative paths for images: `![Description](images/filename.jpg)`
- Cross-reference other pages using relative links: `[Text](path/to/file.qmd)`

### Naming Conventions
- Reflection files: `day-01.qmd`, `day-02.qmd`, etc.
- Landing pages: `index.qmd`
- Images: lowercase with hyphens (e.g., `headshot.jpg`, `logo-scigenix.svg`)

### Adding New Content
When adding new reflection days or sections:
1. Create the `.qmd` file in the appropriate directory
2. Add it to `_quarto.yml` in both `project.render` and the relevant `sidebar.contents`
3. Add navbar menu item if needed in `website.navbar`
4. Run `quarto preview` to verify navigation works correctly

## Quality Assurance

### Pre-Submission Checklist (from README)
Run through these checks before finalizing:
- All TODO markers addressed
- Images added and displaying correctly
- All reflections completed (≥300 words each following Gibbs Reflective Cycle)
- Artefacts uploaded and properly linked
- Spelling and grammar checked
- All links resolve correctly
- `quarto render` completes without errors or warnings
- Website displays correctly in multiple browsers

### Testing Changes
1. Run `quarto render` and check console for warnings/errors
2. Manually inspect rendered pages in `docs/` directory
3. Test navigation links and cross-references
4. Verify image paths and artefact downloads work
5. Run `quarto check` for configuration/metadata validation

## Git Workflow

### Commit Conventions
- Use concise, descriptive commit messages in sentence case (≤50 characters)
- Scope commits to single themes (e.g., "Add Week 2 Day 1 reflection")
- Reference related sections in commit body when helpful
- Example: "Update artefacts index with seminar presentation"

### Branch Strategy
- Main development branch: `dev`
- Main/production branch: `main`
- Create PRs from `dev` to `main` for major milestones

## Special Considerations

### Academic Context
This portfolio is assessed against specific rubrics:
- **Overall Portfolio Impression (22 points)**: Form, visual appeal, organization, content/knowledge
- **Student Reflection (28 points)**: Each reflection must demonstrate clear artefact linkage, critical analysis, detailed examples, honest self-assessment, progress evidence, and future goals
- **Minimum reflection length**: ≥300 words per daily reflection

### Existing Guidelines
The repository includes `AGENTS.md` with condensed guidelines for automated agents. Key points from that file:
- Generated HTML in `docs/` should never be edited directly
- Run commands from repository root
- Use `quarto check` for debugging
- Store images with lowercase, hyphenated filenames
- Follow existing slug patterns (e.g., `day-01.qmd`)
- Keep commits scoped and use concise summary lines

### File Management
- **Do not commit** build artifacts from `.quarto/` (already in `.gitignore`)
- **Do commit** the `docs/` directory (used for GitHub Pages hosting)
- **Optimize images** before adding to reduce repository size
- **Archive supporting documents** in `artefacts/files/` subdirectories

## Reference Information

- **Quarto Documentation**: https://quarto.org/docs/guide/
- **Markdown Basics**: https://quarto.org/docs/authoring/markdown-basics.html
- **Student**: Alexander van Twisk, MSc Biostatistics, Stellenbosch University
- **Module**: Biostatistical Consulting & Collaboration
- **Internship**: Scigenix Pty (Ltd), Pretoria, South Africa (23 June - 30 September 2025)
- **Supervisor**: Dr Xan Swart
