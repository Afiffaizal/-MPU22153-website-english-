# Equipment Loan System

Responsive academic process study for Group 04. The user-supplied PDF provides paper, sky and landscape artwork. The current visual direction combines those assets with bold sans-serif typography and layered ambient movement inspired by the supplied Bike Bear reference. This is a presentation website, not a functioning equipment reservation service.

## Run

```sh
npm install
npm run dev
```

Open the local URL printed by Vite. Build with `npm run build`; the output is in `dist`.

## GitHub Pages

The `.github/workflows/pages.yml` workflow builds and deploys pushes to `main`. Repository Settings → Pages must use **GitHub Actions** as its source.

Deployment URL: https://afiffaizal.github.io/-MPU22153-website-english-/

`vite.config.js` sets the repository base path during GitHub Actions builds; local development keeps `/`. No API keys or deployment secrets are required in the repository.

## Content and assets

- `index.html`: page sections and process explanation.
- `content.js`: both ten-step flows, problems and group members.
- `style.css`: responsive and print layouts.
- `process.css`: compact connected process diagrams.
- `motion.css`: current visual direction, cloud animation and reduced-motion rules.
- `main.js`: process views, navigation and sequence-word highlighting.
- `public/assets`: locally hosted fonts and artwork extracted from the supplied reference PDF.
- `tools/check-site.mjs`: browser interaction and responsive checks; uses the installed Windows Chrome.
- `tools/check-motion.mjs`: verifies continuous cloud movement, absence of a pause control, reduced motion and responsive title fit.

The supplied PDF identifies the course as MPU 22153; the original site uses MPU22355. The new page follows the PDF. Names and matric numbers follow the original website, which also differs from the PDF in places. Confirm these details before submission.

Unverified performance numbers, fines and claims of guaranteed results from the old site have been removed. Expected benefits are explained without invented measurements. References are limited to the materials actually supplied.

Visual assets were supplied by the user, not newly generated. Confirm any necessary permission before public distribution. Font licenses are included with the assets.
