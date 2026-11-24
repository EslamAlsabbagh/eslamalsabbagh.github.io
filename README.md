# eslamalsabbagh.github.io

Personal portfolio site, served at <https://eslamalsabbagh.github.io/>.

## Layout

```
site/                     hand-written static HTML/CSS — the indexable surface
  index.html                        -> /
  about/ projects/ contact/         -> /about/ /projects/ /contact/
  projects/hr-workforce-platform/   -> case study
  projects/ticketing-cashier-system/-> case study
  projects/legal-task-manager/      -> case study
  demo/ demos/ticketing/ demos/legal-tasks/
                                    -> placeholders, replaced by the Flutter builds
  404.html robots.txt sitemap.xml
  assets/css/main.css               single stylesheet
  assets/js/site.js                 progressive enhancement: scroll reveal, counters
  assets/img/og.jpg                 1200x630 social card
demo_app/                 HR platform demo            -> /demo/
demo_ticketing/           ticketing & cashier demo    -> /demos/ticketing/
demo_legal/               legal task manager demo     -> /demos/legal-tasks/
.github/workflows/deploy.yml
```

## The demos

Each demo is the production Flutter app with its backend swapped out, so
there is no server behind it and it makes no network calls:

- `demo_app/` — repositories implemented against an in-memory store.
- `demo_legal/` — each repository keeps its API and reads and writes
  `lib/demo/demo_store.dart`, which re-states the database's RLS and trigger rules.
- `demo_ticketing/` — repositories are handed `lib/demo/backend.dart`, which
  answers the same database functions with the same JSON and error codes. The
  counter's SQLite store is an in-memory port, and printing goes to an
  on-screen tray.

The ticketing and legal demos take `?as=<role>` and `?lang=ar` to open signed in
(`cashier|supervisor|admin` and `manager|lawyer|admin`). Build and test locally with
Flutter 3.44.5 (`.fvmrc`), for example:

```sh
cd demo_ticketing
fvm flutter test
fvm flutter build web --release --no-web-resources-cdn --base-href /demos/ticketing/
```

The site's script (`site/assets/js/site.js`) only enhances: pages are complete without it,
and every animation is off under `prefers-reduced-motion`.

## Why the home page is not Flutter

Flutter Web has no HTML renderer as of 3.29 — CanvasKit and skwasm both paint into a
`<canvas>`, so a crawler sees an empty `<body>`. The pages that need to rank are therefore
plain HTML with no build step, and Flutter is used only for the interactive demo at `/demo/`.

## Deployment

GitHub Actions (`.github/workflows/deploy.yml`), triggered on push to `master`. The job
assembles `site/` into `_site/`, tests and builds each demo into its path, runs an NDA gate
over the output, and publishes to Pages.

The **NDA gate** fails the deploy if any denied term reaches the built output, or if the demo references a backend — it must make no network calls.

The deny-list is held in the `NDA_DENYLIST` repository secret (comma-separated) rather than in the workflow file, because this repository is public and naming the client here would leak precisely what the gate exists to prevent.

## Crawl control

`robots.txt` allows everything and points at the sitemap. The demos are deliberately **not**
disallowed: each carries `<meta name="robots" content="noindex,nofollow">`, and a crawler has
to be able to fetch the page in order to read that tag. Disallowing it in `robots.txt`
would leave the URL eligible for bare-URL indexing while hiding the noindex instruction.

The demos are also excluded from `sitemap.xml`.

## Local preview

```sh
mkdir -p _site && cp -r site/. _site/ && cd _site && python -m http.server 8080
```

Root-absolute paths (`/assets/...`) require serving from the assembled `_site`, not from
`site/` directly.
