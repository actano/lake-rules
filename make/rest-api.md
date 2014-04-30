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

Test Assets which will be copied to the build output. Assets can be arbitrary files which are needed to run the tests.

#### Example
Old:

    server:
        scripts:
            files: ['server.coffee', 'lib.coffee']

        tests: ['test/unit_test.coffee']

    integrationTests:
        mocha: ['test/integration_test.coffee']
New:

    server:
        scripts:
            files: ['server.coffee', 'lib.coffee']

        test:
            unit: ['test/unit_test.coffee']
            integration: ['test/integration_test.coffee']
            exports: ['test/test_helper.coffee']
            assets: ['test/data/test_data.bin']

In this example there are two source files which build the REST-API of the feature. The REST-API part of the feature
 will be tested with an unit and an integration test. An export and an asset are declared which are used by the tests of
 this feature and/or tests in other features in the project.
