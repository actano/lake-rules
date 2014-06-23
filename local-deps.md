# Local Deps

Reads dependencies for a feature and translates them into local node_modules, e.g. converts `manifest.client.dependencies.production.local.<DEP>` to `node_modules/<DEP>/package.json`

## Targets

- `featurePath/local_deps` install dependencies for a feature
- `local_deps` install dependencies for all features
