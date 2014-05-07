## browser test

### abstract

running standalone browser tests.

the test code is compiled into the build directory and wrapped in a html page.

### main targets

    featurePath/client_test
    featurePath/test
    client_test

### Manifest.coffee

    manifest.coffee:
        client:
            tests:
                browser:
                    scripts: [<test.files>, ...]
                    html: <jade.file>

the jade file is compiled to html into the build directory at the location test/test.html.
the script files are compiled into the build directory and passed to the jade compiler with there relative pass.


