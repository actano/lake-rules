# Local Deps

Reads dependencies for a feature and translates them into local node_modules, e.g. converts `manifest.client.tests.browser.dependencies.<DEP>` to `node_modules/<DEP>/package.json`

## Targets

- `<featurePath>/local-deps` install dependencies for a feature
- `<featurePath>/local-deps/clean` clean dependencies for a feature
- `local-deps/clean` clean dependencies for all features
