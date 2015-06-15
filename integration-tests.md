# Integration Tests

## Abstract

Runs integration tests against the web app.

The test code is not compiled but instead run directly from the source
directory.

## Targets

- `featurePath/integration_test` runs integration tests for the given feature
- `featurePath/test` runs all tests for the given feature
- `integration_test` runs integration tests across all features

### Manifest

Two different types of tests can be specified in the manifest: Tests specified
in the section "server.test.integration" are run using Mocha. They usually test
the REST API.

Selenium tests, which usually do user tests with all features of a browser are listed
at "server.test.integration" as well.

    manifest.coffee:
        server:
            test:
                integration: [<mocha.test.file>, ...]
