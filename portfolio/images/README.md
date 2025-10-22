# Images Directory

This directory contains images used throughout the portfolio website.

## Required Images

### 1. headshot.jpg
- **Purpose:** Your professional headshot for the home page
- **Recommended size:** 400x400 pixels (square)
- **Format:** JPEG or PNG
- **Usage:** Appears on [index.qmd](../index.qmd)

### 2. logo.svg (Optional)
- **Purpose:** Stellenbosch University or personal logo
- **Format:** SVG (preferred) or PNG
- **Usage:** Can be added to navbar or footer

## Adding Images

1. Add your images to this directory
2. Update references in the `.qmd` files:
   ```markdown
   ![Description](images/your-image.jpg){width=300px}
   ```

## Image Guidelines

- **File size:** Keep images under 1MB for faster loading
- **Resolution:** Use high-quality images (at least 72 DPI for web)
- **Format:**
  - Use JPEG for photographs
  - Use PNG for graphics with transparency
  - Use SVG for logos and vector graphics
- **Naming:** Use descriptive, lowercase names with hyphens (e.g., `profile-photo.jpg`)

## Current Status

- [ ] `headshot.jpg` - TODO: Add your professional headshot
- [ ] `logo.svg` - TODO: Add Stellenbosch University logo (optional)

---

**Note:** Until you add your actual images, placeholder text will display on the website.
