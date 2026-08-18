# eslamalsabbagh.github.io

Personal portfolio site, served at <https://eslamalsabbagh.github.io/>.

## Layout

```
site/                     hand-written static HTML/CSS — the indexable surface
  index.html                        -> /
  about/ projects/ contact/         -> /about/ /projects/ /contact/
  projects/hr-workforce-platform/   -> the case study
  demo/                             -> placeholder, replaced by the Flutter build
  404.html robots.txt sitemap.xml
  assets/css/main.css               single stylesheet
  assets/img/og.png                 1200x630 social card
demo_app/                 (Phase 2) scrubbed Flutter build of the HR platform
.github/workflows/deploy.yml
```

## Why the home page is not Flutter

Flutter Web has no HTML renderer as of 3.29 — CanvasKit and skwasm both paint into a
`<canvas>`, so a crawler sees an empty `<body>`. The pages that need to rank are therefore
plain HTML with no build step, and Flutter is used only for the interactive demo at `/demo/`.

## Deployment

GitHub Actions (`.github/workflows/deploy.yml`), triggered on push to `master`. The job
assembles `site/` into `_site/`, builds `demo_app` into `_site/demo/` when that directory
exists, runs an NDA gate over the output, and publishes to Pages.

The **NDA gate** fails the deploy if any denied term reaches the built output, or if the demo references a backend — it must make no network calls.

The deny-list is held in the `NDA_DENYLIST` repository secret (comma-separated) rather than in the workflow file, because this repository is public and naming the client here would leak precisely what the gate exists to prevent.

## Crawl control

`robots.txt` allows everything and points at the sitemap. `/demo/` is deliberately **not**
disallowed: it carries `<meta name="robots" content="noindex,nofollow">`, and a crawler has
to be able to fetch the page in order to read that tag. Disallowing it in `robots.txt`
would leave the URL eligible for bare-URL indexing while hiding the noindex instruction.

`/demo/` is also excluded from `sitemap.xml`.

## Local preview

```sh
mkdir -p _site && cp -r site/. _site/ && cd _site && python -m http.server 8080
```

Root-absolute paths (`/assets/...`) require serving from the assembled `_site`, not from
`site/` directly.
