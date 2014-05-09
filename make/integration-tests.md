# Integration Tests

## Abstract

Runs integration tests against the web app.

The test code is not compiled but instead run directly from the source
directory.

## Targets

- `featurePath/integration_test` runs integration tests for the given feature
- `featurePath/test` runs all tests for the given feature
- `integration_test` runs integration tests across all features

### Manifest.coffee

Two different types of tests can be specified in the manifest: Tests specified
in the section "server.test.integration" are run using Mocha. They usually test
the REST API.

Tests specified in the section "integrationTests.casper" are run inside a
Mocha-Casper wrapper and usually test the HTML output of the web app.

    manifest.coffee:
        server:
            test:
                integration: [<mocha.test.file>, ...]

        integrationTests:
            casper: [<casper.test.file>, ...]
