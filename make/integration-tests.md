## integration test

### abstract

the phony rule executes the integration tests against the running web applications.

the test code is not compiled but just running from the feature src directory.

### main targets

    featurePath/integration_test
    featurePath/test
    integration_test

### Manifest.coffee

    manifest.coffee:
        server:
            test:
                integration: [<mocha.test.file>, ...]

        integrationTests:
            casper: [<casper.test.file>, ...]

there are two types of rules.
the mocha rule runs the test in a mocha test-runner, usually these tests runs against the rest-api.
the casper rule runs inside a mocha-casper wrapper, usually testing the html output of the webapp.


