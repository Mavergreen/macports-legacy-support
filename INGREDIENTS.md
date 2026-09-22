# Build ingredients

Everything baked into the shipped `.pkg`, and how a change to it reaches a release.

| Ingredient | Pinned in | Renovate | On a bump |
|---|---|---|---|
| macports-legacy-support source (own upstream) | `UPSTREAM_VERSION` | ✅ `github-tags` on `macports/macports-legacy-support` | `release.yml` cuts `<upstream>-mavericks.1` |
| Sparkle framework, MacOSX10.9 SDK | `Mavergreen/shipyard@v1` | ✅ github-actions manager tracks the tag | `@v1` is a *moving* tag: shipyard content changes without the pin changing, so nothing auto-repackages |

## No repackage-on-ingredient-bump caller here — deliberately

The family pattern (`repackage-on-ingredient-bump.yml` calling shipyard's reusable workflow)
turns an *ingredient* pin bump into a `-mavericks.(N+1)` repackage. This repo has no such pin: its
only versioned input is its own upstream, which is the `-mavericks.1` path `release.yml` already
owns, and its only other input is `shipyard@v1`, whose moving tag no path filter can observe.

A caller would therefore have nothing to watch. Add one the moment a real ingredient pin lands here
(a prebuilt dependency, a vendored blob with a hash), pointing `own-upstream-paths` at
`UPSTREAM_VERSION` so a new upstream still takes the `-mavericks.1` path.
