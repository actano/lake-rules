# Browser Tests

## Abstract

Runs standalone browser tests.

Test code is compiled into the build directory and wrapped in a HTML page. The
tests are run using Casper.

## Targets

- `featurePath/client_test` runs the browser test of the specified feature
- `featurePath/test` runs all tests of the specified feature
- `client_test` runs browser tests across all features

## Manifest

    manifest.coffee:
        client:
            tests:
                browser:
                    scripts: [<test.files>, ...]
                    html: <jade.file>
                    dependencies: [<path.to.other.features.defining.jade.include>, ...]
            templates:
                dependencies: [<path.to.other.features.defining.jade.include>, ...]

The jade file is compiled to HTML into the build directory at `test/test.html`.
The featurePath itself is implicitly added as jade-dependency path
The script files are compiled into the build directory and passed to the jade
compiler with their relative paths.

The test result is saved to `test_reports/browser-test.xml`.
