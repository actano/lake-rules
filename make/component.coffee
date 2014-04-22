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

    TODO disallow ../ in stylus @imports by defining a stylus depn in manifest and adding this dir to stylus bin
    cleanup translations, jade, fontcustom
    should we move this stuff inside here?
    ruleId component-build is required from rule browser test coffee, remove!
###


path = require 'path'

_ = require 'underscore'

{replaceExtension, addMkdirRuleOfFile, addMkdirRule, addPhonyRule} = require '../rulebook_helper'

exports.title = 'component make targets'
exports.description = "build/ dist/ test components"
exports.addRules = (lake, featurePath, manifest, ruleBook) ->

    # make sure we are a component feature
    return if not manifest.client?

    COMPONENTBUILD_OUTDIR = 'component-build'
    COMPONENTINSTALL_TARGETFILE = 'component-installed'
    COMPONENTINSTALL_DIR = 'components'
    featureBuildPath = path.join lake.featureBuildDirectory, featurePath # build/lib/foobar
    projectRoot = path.resolve(path.join(lake.lakePath, '..'))

    componentBuildDependencies = []

    _getComponentBuildDepTarget = (depPath) ->
        path.normalize(path.join(depPath, COMPONENTBUILD_OUTDIR))

    _compileCoffeeToJavaScript = (srcFile, srcPath, destPath) ->
        target = path.join(destPath, replaceExtension(srcFile, '.js'))
        componentBuildDependencies.push target
        targetDir = addMkdirRuleOfFile ruleBook, target
        ruleBook.addRule  target, [], ->
            targets: target
            dependencies: [ path.join(srcPath, srcFile), '|', targetDir ]
            actions: "$(COFFEEC) -c $(COFFEE_FLAGS) -o #{targetDir} $^"


    _compileStylusToCSS = (srcFile, srcPath, destPath) ->
        target = path.join(destPath, replaceExtension(srcFile, '.css'))
        componentBuildDependencies.push target
        targetDir = addMkdirRuleOfFile ruleBook, target
        ruleBook.addRule  target, [], ->
            targets: target
            dependencies: [ path.join(srcPath, srcFile), '|', targetDir ]
            actions: "$(STYLUSC) $(STYLUS_FLAGS) -o #{targetDir} $^"

    _copyImageFile = (srcFile, srcPath, destPath) ->
        target = path.join(destPath, srcFile)
        componentBuildDependencies.push target
        targetDir = addMkdirRuleOfFile ruleBook, target
        ruleBook.addRule  target, [], ->
            targets: target
            dependencies: [ path.join(srcPath, srcFile), '|', targetDir ]
            actions: "cp #{path.join(srcPath, srcFile)} #{target}"

    # MUST be called inside of a rulebook function
    _getRuleBookTargetsByTag = (tag) ->
        _(rule.targets for rule in ruleBook.getRulesByTag(tag)).flatten()


    # has client scripts
    componentScriptFiles = []
    if manifest.client?.scripts?.length > 0
        for scriptSrcFile in manifest.client.scripts
            componentScriptFiles.push _compileCoffeeToJavaScript(scriptSrcFile, featurePath, featureBuildPath)


    # has client styles
    componentStyleFiles = []
    if manifest.client?.styles?.length > 0
        for styleSrcFile in manifest.client.styles
            componentStyleFiles.push \
                _compileStylusToCSS(styleSrcFile, featurePath, featureBuildPath)

    # has client images
    componentImageFiles = []
    if manifest.client?.images?.length > 0
        for imageFile in manifest.client.images
            componentImageFiles.push imageFile
            _copyImageFile(imageFile, featurePath, featureBuildPath)

    # create component.json from Manifest
    componentJsonTarget = path.join featureBuildPath, 'component.json'
    componentBuildDependencies.push componentJsonTarget
    addMkdirRule ruleBook, featureBuildPath
    ruleBook.addRule componentJsonTarget, [], ->
        # we still get input from translations and fontcustom here
        additionalScripts =  _getRuleBookTargetsByTag('add-to-component-scripts')
        additionalStyles = _getRuleBookTargetsByTag('add-to-component-styles')
        additionalFonts = _getRuleBookTargetsByTag('add-to-component-fonts')
        args = ("--add-script #{x}" for x in additionalScripts)
        args = args.concat ("--add-style #{x}" for x in additionalStyles)
        args = args.concat ("--add-font #{x}" for x in additionalFonts)

        targets: componentJsonTarget
        dependencies: [ path.join(featurePath, "Manifest.coffee"), '|', featureBuildPath ]
        actions: [
            "$(COMPONENT_GENERATOR) $< $@ #{args.join ' '}"
        ]

    if manifest.client.dependencies?.production?.local?
        componentBuildDependencies = componentBuildDependencies.concat \
            manifest.client.dependencies.production.local.map (localDep) ->
                _getComponentBuildDepTarget(path.join(lake.featureBuildDirectory, featurePath, localDep))

    # install component remote dependencies
    if manifest.client?.dependencies?
        globalRemoteComponentDirectory = path.join projectRoot, lake.remoteComponentPath
        addMkdirRule ruleBook, globalRemoteComponentDirectory
        remoteComponentDir = path.join featureBuildPath, COMPONENTINSTALL_DIR
        componentInstalledTarget = path.join featureBuildPath, COMPONENTINSTALL_TARGETFILE
        componentBuildDependencies.push componentInstalledTarget

        ruleBook.addRule componentInstalledTarget, [], ->
            targets: componentInstalledTarget
            dependencies: componentBuildDependencies.concat [ '|', remoteComponentDir]
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
    componentBuildDirectory = _getComponentBuildDepTarget(featureBuildPath) # build/lib/foobar/component-build
    _getComponentBuildTarget = ->
        componentBuildTarget = []
        if _getRuleBookTargetsByTag('add-to-component-scripts').length > 0 or componentScriptFiles.length > 0
            componentBuildTarget.push path.join(componentBuildDirectory, manifest.name) + ".js"
        if _getRuleBookTargetsByTag('add-to-component-styles').length > 0 or componentStyleFiles.length > 0
            componentBuildTarget.push path.join(componentBuildDirectory, manifest.name) + ".css"
        return componentBuildTarget

    ruleBook.addRule COMPONENTBUILD_OUTDIR, [], ->
        componentBuildDependencies = componentBuildDependencies.concat \
            _getRuleBookTargetsByTag('component-build-prerequisite')
        targets: _getComponentBuildTarget()
        dependencies: componentBuildDependencies
        actions: [
            "cd #{featureBuildPath} && $(COMPONENT_BUILD) $(COMPONENT_BUILD_FLAGS) " + \
                " --name #{manifest.name} -v -o #{COMPONENTBUILD_OUTDIR}"
            "mkdir -p #{componentBuildDirectory}"
        ]


    # rule to build the component
    ruleBook.addRule componentBuildDirectory, [], ->
        targets: componentBuildDirectory
        dependencies: _getComponentBuildTarget()
        actions: [
            "touch #{componentBuildDirectory}"
        ]

    phonyComponentBuildDepTarget = _getComponentBuildDepTarget(featurePath)
    ruleBook.addRule phonyComponentBuildDepTarget, [], ->
        targets: phonyComponentBuildDepTarget
        dependencies: componentBuildDirectory

    addPhonyRule ruleBook, phonyComponentBuildDepTarget

    # Alias to map feature to feature/component-build
    ruleBook.addRule "#{featurePath}: (#{featurePath}/component-build alias)", [], ->
        targets: featurePath
        dependencies: componentBuildDirectory

    ruleBook.addRule 'build: (#{featurePath}/component-build global)', [], ->
        targets: 'build'
        dependencies: componentBuildDirectory
