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
        this is part "main component" targets like pages or widgets

    component test
        unit and integration tests (usally in mocha/ mocha-phantom or mocha-casper)
        and demo sites for standalone browser tests
###


path = require 'path'

_ = require 'underscore'

{replaceExtension, addMkdirRuleOfFile, addMkdirRule, addPhonyRule} = require '../rulebook_helper'

exports.title = 'component make targets'
exports.description = "build/ dist/ test components"
exports.addRules = (lake, featurePath, manifest, ruleBook) ->

    # make sure we are a component feature
    return if not manifest.client?

    componentBuildPhonyTarget = 'component-build'
    featureBuildPath = path.join lake.featureBuildDirectory, featurePath # build/lib/foobar
    projectRoot = path.resolve(path.join(lake.lakePath, '..'))

    componentBuildDependencies = []

    _compileCoffeeToJavaScript = (srcFile, srcPath, destPath) ->
        target = path.join(destPath, replaceExtension(srcFile, '.js'))
        componentBuildDependencies.push target
        targetDir = addMkdirRuleOfFile ruleBook, target
        ruleBook.addRule  "#{featurePath}/#{srcFile}", [], ->
            targets: target
            dependencies: [ path.join(srcPath, srcFile), '|', targetDir ]
            actions: "$(COFFEEC) -c $(COFFEE_FLAGS) -o #{targetDir} $^"


    _compileStylusToCSS = (srcFile, srcPath, destPath) ->
        target = path.join(destPath, replaceExtension(srcFile, '.css'))
        componentBuildDependencies.push target
        targetDir = addMkdirRuleOfFile ruleBook, target
        ruleBook.addRule  "#{featurePath}/#{srcFile}", [], ->
            targets: target
            dependencies: [ path.join(srcPath, srcFile), '|', targetDir ]
            actions: "$(STYLUSC) $(STYLUS_FLAGS) -o #{targetDir} $^"
        

    # has client scripts
    componentScriptFiles = []
    if manifest.client?.scripts?.length > 0
        for scriptSrcFile in manifest.client.scripts
            componentScriptFiles.push _compileCoffeeToJavaScript(scriptSrcFile, featurePath, featureBuildPath)


    # has client styles
    # TODO set stylus import dir and fail if @import has ..
    componentStyleFiles = []
    if manifest.client?.styles?.length > 0
        for styleSrcFile in manifest.client.styles
            componentStyleFiles.push \
                _compileStylusToCSS(styleSrcFile, featurePath, featureBuildPath)

    # create component.json from Manifest
    componentJsonTarget = path.join featureBuildPath, 'component.json'
    addMkdirRuleOfFile ruleBook, featureBuildPath
    ruleBook.addRule "#{featurePath}/component.json", [], ->
        # we still get input from translations and fontcustom here
        additionalScripts =  _(rule.targets for rule in ruleBook.getRulesByTag('add-to-component-scripts')).flatten()
        additionalStyles = _(rule.targets for rule in ruleBook.getRulesByTag('add-to-component-styles')).flatten()
        additionalFonts = _(rule.targets for rule in ruleBook.getRulesByTag('add-to-component-fonts')).flatten()

        args = ("--add-script #{x}" for x in additionalScripts)
        args = args.concat ("--add-style #{x}" for x in additionalStyles)
        args = args.concat ("--add-font #{x}" for x in additionalFonts)

        componentBuildDependencies.push componentJsonTarget

        targets: componentJsonTarget
        dependencies: [ path.join(featurePath, "Manifest.coffee"), '|', featureBuildPath ]
        actions: [
            "$(COMPONENT_GENERATOR) $< $@ #{args.join ' '}"
        ]

    # install component remote dependencies
    if manifest.client?.dependencies?
        globalRemoteComponentDirectory = path.join projectRoot, lake.remoteComponentPath
        addMkdirRule ruleBook, globalRemoteComponentDirectory
        remoteComponentDir = path.join featureBuildPath, 'components'
        componentInstalledTarget = path.join featureBuildPath, 'component-installed'
        componentBuildDependencies.push componentInstalledTarget
        if manifest.client.dependencies.production?.local?
            localComponentDependencies = manifest.client.dependencies.production.local.map (localDep) ->
                path.normalize(path.join(featurePath, localDep, componentBuildPhonyTarget))
        else
            localComponentDependencies = []

        ruleBook.addRule "#{featurePath}/component-installed", [], ->
            targets: componentInstalledTarget
            dependencies: localComponentDependencies.concat [ componentJsonTarget, '|', remoteComponentDir]
            actions: [
                "cd #{featureBuildPath} && $(COMPONENT_INSTALL) $(COMPONENT_INSTALL_FLAGS)"
                "touch #{componentInstalledTarget}"
            ]
        ruleBook.addRule remoteComponentDir, [], ->
            targets: remoteComponentDir
            dependencies: [ '|', globalRemoteComponentDirectory ]
            actions: [
                "test -d #{remoteComponentDir} || ln -s #{globalRemoteComponentDirectory} #{remoteComponentDir}"
            ]


    # generate component-build/<manifest.name>.(js|css)
    componentBuildDirectory = path.join featureBuildPath, "component-build" # build/lib/foobar/component-build
    jsFile = path.join(componentBuildDirectory, manifest.name) + ".js"
    cssFile = path.join(componentBuildDirectory, manifest.name) + ".css"
    ruleBook.addRule "component-build", [], ->
        targets: [jsFile, cssFile]
        dependencies: [componentBuildDependencies]
        actions: [
            "cd #{featureBuildPath} && $(COMPONENT_BUILD) $(COMPONENT_BUILD_FLAGS) --name #{manifest.name} -v -o #{componentBuildDirectory}"
        ]


    # phony rule to build the component
    ruleBook.addRule "#{featurePath}/#{componentBuildPhonyTarget}", [], ->
        targets: path.join featurePath, componentBuildPhonyTarget
        dependencies: [jsFile, cssFile]

    addPhonyRule ruleBook, path.join featurePath, componentBuildPhonyTarget