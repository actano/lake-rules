# Coverage

## Abstract

Defines rules for generating code coverage reports.

To record coverage statistics the WebApp Javascript files have to be
instrumented by [Istanbul](https://github.com/gotwarlost/istanbul).

The instrumented Javascript files need to have the same directory structure as
the original webapp and therefore will be placed in a
separate directory.

Coverage statistics are generated by running the server unit and integration
tests against the instrumented webapp. These tests and their dependencies are
copied to the appropriate locations in the instrumented webapp directory tree.

Tests will be started per feature via the
[mocha_istanbul_test_runner.coffee](../../mocha_istanbul_test_runner.coffee)
helper script. This helper starts the instrumented webapp and runs the tests
inside the context of the instrumented webapp.

## Targets

- `featurePath/coverage` generates coverage files for the specified feature
- `coverage` generates coverage files across all features
- `build/coverage/clean` removes generated coverage files

## Manifest

### Instrumented files

Script files in "server.scripts.files" will be instrumented and are part of the
instrumented webapp.

    manifest.coffee
        server:
            scripts:
                files: [...]

### Test Cases

The test cases defined by "server.test.unit" and "server.test.integration" will
be run against the instrumented webapp.

    manifest.coffee
        server:
            test:
                unit: [...]
                integration: [...]

### Test Exports/Dependencies

Files defined in "server.test.exports" ontain code which is required by the test
cases. They will be copied to the instrumented directory tree.

    manifest.coffee
        server:
            test:
            exports: [...]

### Test Assets

Test assets are defined in "server.test.assets" and will be copied to the
instrumented directory tree. Assets can be arbitrary files which are needed to
run the tests.

    manifest.coffee
        server:
            test:
            assets: [...]

### Example

#### Old

    server:
        scripts:
            files: ['server.coffee', 'lib.coffee']

        tests: ['test/unit_test.coffee']

    integrationTests:
        mocha: ['test/integration_test.coffee']

#### New

    server:
        scripts:
            files: ['server.coffee', 'lib.coffee']

        test:
            unit: ['test/unit_test.coffee']
            integration: ['test/integration_test.coffee']
            exports: ['test/test_helper.coffee']
            assets: ['test/data/test_data.bin']

In this example there are two source files which build the REST-API of the
feature. The REST-API part of the feature will be tested with an unit and an
integration test. An export and an asset are declared which are used by the
tests of this feature and/or tests in other features in the project.
