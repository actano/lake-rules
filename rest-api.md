# REST API

## Abstract

Generates rules regarding the REST API part of a feature.

The REST API must be referenced by the web app in order to be installed.

## Targets

Targets are grouped by topic, namely building, installing and testing.

- `featurePath/build` builds the REST API of a feature
- `build` builds all features
- `install` installs REST APIs into the runtime directory
- `featurePath/unit_test` runs unit tests for the given feature
- `featurePath/test` runs all tests for the given feature
- `unit_test` runs unit tests across all features

## Manifest

### Scripts

Scripts are specified in the section "server.scripts.files". They can either be
CoffeeScript or Javascript files. CoffeeScript files are compiled to Javascript
whereas Javascript files are copied directly to the build directory.

    manifest.coffee
        server:
            scripts:
                files: [...]

Assets needed by scripts (e.g. JSON files) are specified in the section
"server.scripts.assets". They are directly copied to the runtime directory.

    manifest.coffee
        server:
            assets: [...]

### Tests

#### Unit Tests

Unit tests which will directly run against the compiled server JS files.

    server:
        test:
            unit: [...]


#### Integration Tests

Integration tests for the REST-API which will run against the webapp.

    server:
        test:
            integration: [...]


#### Test Exports/Dependencies

Files defined by this key contain code which is required by the test cases. They
will be copied to the build output.

    server:
        test:
            exports: [...]


#### Test Assets

Test Assets which will be copied to the build output. Assets can be arbitrary
files which are needed to run the tests.

    server:
        test:
            assets: [...]

#### Example

##### Old

    server:
        scripts:
            files: ['server.coffee', 'lib.coffee']

        tests: ['test/unit_test.coffee']

    integrationTests:
        mocha: ['test/integration_test.coffee']

##### New

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
