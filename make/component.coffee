###
    generates make rules for a tj component

    defines the following main make targets

    component build:
        generates a component.json from a Manifest.coffee
        install remote components
        build local component dependencies
        compile artefacts like stylus, coffee, jade
        call component-build

        output contract:
            builds all stuff in the BUILD_DIR/FEATURE_DIR for internal use
            contract for depending targets are files placed in
            BUILD_DIR/FEATURE_DIR/component-build

            there MUST be this two files
                component-build/<manifest.name>.js
                component-build/<manifest.name>.css
            optional there might be resources like fonts
                component-build/resource_dir

    component dist (aka install)
        is doing NOTHING cause a component itself has nothing to distrubute.
        this is part "main componet" targets like pages or widgets

    component test
        unit and integration tests (usally in mocha/ mocha-phantom or mocha-casper)
        and demo sites for standalone browser tests
###

exports.title = 'component make targets'
exports.description = "build/ dist/ test components"
exports.addRules = (lake, featurePath, manifest, ruleBook) ->
    buildPath = path.join lake.featureBuildDirectory, featurePath # build/lib/foobar

