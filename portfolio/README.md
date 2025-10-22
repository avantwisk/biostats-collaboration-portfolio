# Biostatistical Consulting & Collaboration Portfolio

**Author:** Alexander van Twisk
**Programme:** MSc Biostatistics, Stellenbosch University
**Module:** Biostatistical Consulting & Collaboration

---

## Overview

This portfolio documents my learning journey through the Biostatistical Consulting & Collaboration module, including my three-month internship at Scigenix Pty (Ltd) in Pretoria, South Africa.

The portfolio is built using [Quarto](https://quarto.org/), an open-source scientific and technical publishing system, and includes:

- **Internship Report**: Detailed account of my internship experience, work outputs, and reflections
- **Module Reflections**: Daily reflections following the Gibbs Reflective Cycle
- **Learning Outcomes**: Evidence of achievement of module learning outcomes
- **Coursework Integration**: How the module connects to the broader MSc curriculum
- **Artefacts**: Repository of supporting evidence

---

## Prerequisites

To build and preview this portfolio website, you need:

### 1. Quarto

**Installation:**

- **macOS** (using Homebrew):
  ```bash
  brew install quarto
  ```

- **macOS/Windows/Linux** (manual installation):
  - Download from [https://quarto.org/docs/get-started/](https://quarto.org/docs/get-started/)
  - Follow installation instructions for your operating system

**Verify installation:**
```bash
quarto --version
```

### 2. R (Optional but Recommended)

If you plan to include R code in your portfolio:

- Download from [https://cran.r-project.org/](https://cran.r-project.org/)
- Install RStudio or use Positron (VS Code extension)

---

## Project Structure

```
portfolio/
├── _quarto.yml                    # Quarto configuration
├── README.md                      # This file
├── index.qmd                      # Home page
├── styles/
│   └── custom.css                 # Custom styling
├── images/
│   ├── logo.svg                   # Logo (TODO: add)
│   └── headshot.jpg               # Headshot (TODO: add)
├── internship/
│   ├── index.qmd                  # Internship report landing
│   ├── introduction.qmd
│   ├── learning-objectives.qmd
│   ├── relation-to-coursework.qmd
│   ├── work-outputs.qmd
│   └── reflection.qmd
├── reflections/
│   ├── index.qmd                  # Reflections landing
│   ├── week-01/                   # Week 1 reflections (Days 1-5)
│   └── week-02/                   # Week 2 reflections (Days 1-5)
├── learning-outcomes/
│   └── index.qmd
├── coursework/
│   └── index.qmd
└── artefacts/
    └── index.qmd
```

---

## Building the Portfolio

### Preview the Website (Development)

To preview the website locally with live reloading:

```bash
cd portfolio
quarto preview
```

This will:
- Start a local web server
- Open the site in your default browser
- Automatically reload when you save changes to `.qmd` files

**Default URL:** `http://localhost:XXXX` (port number will be displayed in terminal)

### Render the Website (Production)

To render the complete website to HTML:

```bash
cd portfolio
quarto render
```

This will:
- Generate all HTML files
- Create the `_site/` directory with the complete website
- Process all `.qmd` files and apply styling

**Output location:** `_site/` directory

### Publish the Website

#### Option 1: GitHub Pages

```bash
quarto publish gh-pages
```

#### Option 2: Netlify

```bash
quarto publish netlify
```

#### Option 3: Manual Deployment

Copy the contents of `_site/` to your web server.

---

## Customization Guide

### Adding Images

1. Add your images to the `images/` directory:
   - `headshot.jpg` - Your professional headshot
   - `logo.svg` - University or personal logo

2. Update references in `index.qmd`:
   ```markdown
   ![Your Name](images/headshot.jpg){width=200px}
   ```

### Updating Content

All content is written in Quarto Markdown (`.qmd` files). Key files to update:

1. **Home Page** (`index.qmd`):
   - Replace TODO markers with personal information
   - Add your contact details

2. **Internship Report** (`internship/*.qmd`):
   - Content is already extracted from your PDF
   - Review and add any missing details or reflections

3. **Daily Reflections** (`reflections/week-*/day-*.qmd`):
   - Fill in session topics and dates from module timetable
   - Write reflections following the Gibbs Reflective Cycle
   - Ensure each reflection is ≥300 words
   - Link to relevant artefacts

4. **Learning Outcomes** (`learning-outcomes/index.qmd`):
   - Add specific examples of how you achieved each outcome
   - Link to relevant portfolio sections

5. **Coursework** (`coursework/index.qmd`):
   - List your MSc modules
   - Describe how they relate to consulting work

6. **Artefacts** (`artefacts/index.qmd`):
   - Upload artefacts (presentations, assignments, code)
   - Add links and descriptions

### Modifying Styling

Edit `styles/custom.css` to customize:
- Colors
- Fonts
- Spacing
- Table styles
- Callout boxes

### Changing Configuration

Edit `_quarto.yml` to modify:
- Website title and description
- Navigation structure
- Sidebar contents
- Theme (currently using `cosmo`)
- Footer text

---

## Development Workflow

### Recommended Workflow in Positron (VS Code)

1. **Open the project:**
   ```bash
   cd /path/to/portfolio
   code .
   ```

2. **Start preview in terminal:**
   ```bash
   quarto preview
   ```

3. **Edit `.qmd` files** in VS Code

4. **Save files** - changes will auto-reload in browser

5. **View in browser** to check formatting

6. **Commit changes** regularly:
   ```bash
   git add .
   git commit -m "Update reflection for Week 1, Day 1"
   ```

### Quality Checks Before Submission

- [ ] All TODO markers addressed
- [ ] Images added (headshot, logos)
- [ ] All 10 daily reflections completed (≥300 words each)
- [ ] Artefacts uploaded and linked
- [ ] Spelling and grammar checked
- [ ] All links working
- [ ] `quarto render` completes without errors
- [ ] Website displays correctly in multiple browsers
- [ ] PDF export works (if required): `quarto render --to pdf`

---

## Troubleshooting

### Common Issues

**Issue:** `quarto: command not found`
**Solution:** Ensure Quarto is installed and in your PATH. Try `brew install quarto` on macOS.

**Issue:** Preview not updating
**Solution:** Stop and restart `quarto preview`, or clear browser cache.

**Issue:** Images not displaying
**Solution:** Check file paths are correct and images exist in `images/` directory.

**Issue:** Sidebar not showing
**Solution:** Verify `sidebar:` specification in YAML frontmatter of `.qmd` files matches sidebar IDs in `_quarto.yml`.

**Issue:** Render errors
**Solution:** Check terminal output for specific error messages. Common issues:
- YAML formatting errors
- Missing closing brackets in markdown links
- Invalid cross-references

### Getting Help

- **Quarto Documentation:** [https://quarto.org/docs/guide/](https://quarto.org/docs/guide/)
- **Quarto Community:** [https://github.com/quarto-dev/quarto-cli/discussions](https://github.com/quarto-dev/quarto-cli/discussions)
- **Markdown Guide:** [https://quarto.org/docs/authoring/markdown-basics.html](https://quarto.org/docs/authoring/markdown-basics.html)

---

## Assessment Rubrics

This portfolio is assessed against the following rubrics (from Portfolio of Evidence of Learning 2019):

### Overall Portfolio Impression (22 points)
- Form (spelling, grammar, writing quality): 4 points
- Visual appeal and originality: 6 points
- Organization: 4 points
- Content and knowledge of key concepts: 8 points

### Student Reflection (28 points)
Each reflection assessed on:
1. Clear link between reflection and artefact
2. In-depth, insightful, critical analysis
3. Detailed examples, references, connections
4. Honest, realistic self-assessment
5. Evidence of progress toward goals
6. Future goals clearly outlined
7. Vivid impressions creating connection with audience

### Presentation (10 points)
If oral presentation required.

**Total:** 100 points (including assignments)

---

## License

This portfolio is submitted as part of academic coursework for the MSc Biostatistics programme at Stellenbosch University.

© 2025 Alexander van Twisk. All rights reserved.

---

## Contact

**Author:** Alexander van Twisk
**Email:** TODO
**Institution:** Stellenbosch University
**Programme:** MSc Biostatistics
**Year:** 2025

---

## Acknowledgments

- Dr. Xan Swart (Internship Supervisor, Scigenix)
- Module Coordinators and Lecturers
- Scigenix Pty (Ltd) team
- Biostatistical Consulting & Collaboration Module Team
