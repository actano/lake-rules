# Browser Tests

## Abstract

Runs browser tests in karma.

## Targets

- `featurePath/test/testfile` runs specified testfile (without coffee extension)
- `featurePath/client_test` runs the browser test of the specified feature
- `featurePath/test` runs all tests of the specified feature
- `client_test` runs browser tests across all features

## Manifest

    manifest.coffee:
        client:
            tests:
                browser:
                    scripts: [<test.files>, ...]
