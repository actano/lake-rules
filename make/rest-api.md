# REST-API lake rules

## Manifest

### REST-API source files
    server:
        scripts:
            files: [...]

Source files which contain the REST-API code of the feature.

### Tests

#### Unit Tests
    server:
        test:
            unit: [...]

Unit tests which will directly run against the compiled server JS files.

#### Integration Tests
    server:
        test:
            integration: [...]

Integration tests for the REST-API which will run against the webapp.

#### Test Exports/Dependencies
    server:
        test:
            exports: [...]

Files defined by this key contain code which is required by the test cases. They will be copied to the build output.

#### Test Assets
    server:
        test:
            assets: [...]

Test Assets which will be copied to the build output.