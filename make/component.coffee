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

exports.title = 'component.json make targets'
exports.description = "creates the  component.json and build the prerequisites"
exports.addRules = (lake, featurePath, manifest, ruleBook) ->

    # make sure we are a component feature
    return if not manifest.client?

    buildPath = path.join lake.featureBuildDirectory, featurePath # build/lib/foobar
    projectRoot = path.resolve(path.join(lake.lakePath, '..'))
    globalRemoteComponentDirectory = path.join projectRoot, lake.remoteComponentPath

    componentJsonDependencies = [path.join(featurePath, 'Manifest.coffee')]

    _compileCoffeeToJavaScript = (srcFile, srcPath, destPath) ->
        target = path.join(destPath, replaceExtension(srcFile, '.js'))
        componentJsonDependencies.push target
        targetDir = addMkdirRuleOfFile ruleBook, target
        ruleBook.addRule  target, [], ->
            targets: target
            dependencies: [ path.join(srcPath, srcFile), '|', targetDir ]
            actions: "$(COFFEEC) -c $(COFFEE_FLAGS) -o #{targetDir} $^"


    _compileStylusToCSS = (srcFile, srcPath, destPath) ->
        target = path.join(destPath, replaceExtension(srcFile, '.css'))
        componentJsonDependencies.push target
        targetDir = addMkdirRuleOfFile ruleBook, target
        ruleBook.addRule  target, [], ->
            targets: target
            dependencies: [ path.join(srcPath, srcFile), '|', targetDir ]
            actions: "$(STYLUSC) $(STYLUS_FLAGS) -o #{targetDir} $^"

    _copyImageFile = (srcFile, srcPath, destPath) ->
        target = path.join(destPath, srcFile)
        componentJsonDependencies.push target
        targetDir = addMkdirRuleOfFile ruleBook, target
        ruleBook.addRule  target, [], ->
            targets: target
            dependencies: [ path.join(srcPath, srcFile), '|', targetDir ]
            actions: "cp #{path.join(srcPath, srcFile)} #{target}"

    # MUST be called inside of a rulebook function
    # TODO remove getRulesBy* calls
    _getRuleBookTargetsByTag = (tag) ->
        _(rule.targets for rule in ruleBook.getRulesByTag(tag)).flatten()


    # has client scripts
    componentScriptFiles = []
    if manifest.client?.scripts?.length > 0
        for scriptSrcFile in manifest.client.scripts
            componentScriptFiles.push _compileCoffeeToJavaScript(scriptSrcFile, featurePath, buildPath)


    # has client styles
    componentStyleFiles = []
    if manifest.client?.styles?.length > 0
        for styleSrcFile in manifest.client.styles
            componentStyleFiles.push \
                _compileStylusToCSS(styleSrcFile, featurePath, buildPath)

    # has client images
    componentImageFiles = []
    if manifest.client?.images?.length > 0
        for imageFile in manifest.client.images
            componentImageFiles.push imageFile
            _copyImageFile(imageFile, featurePath, buildPath)

    if manifest.client.dependencies?.production?.local?
        componentJsonDependencies = componentJsonDependencies.concat \
            manifest.client.dependencies.production.local.map (localDep) ->
                path.normalize(path.join(lake.featureBuildDirectory, featurePath, localDep, 'component.json'))

    # create component.json from Manifest
    componentJsonTarget = path.join buildPath, 'component.json'
    addMkdirRule ruleBook, buildPath
    ruleBook.addRule componentJsonTarget, [], ->
        # TODO kick getRulesBy*
        # we still get input from translations and fontcustom here
        additionalScripts =  _getRuleBookTargetsByTag('add-to-component-scripts')
        additionalStyles = _getRuleBookTargetsByTag('add-to-component-styles')
        additionalFonts = _getRuleBookTargetsByTag('add-to-component-fonts')
        args = ("--add-script #{x}" for x in additionalScripts)
        args = args.concat ("--add-style #{x}" for x in additionalStyles)
        args = args.concat ("--add-font #{x}" for x in additionalFonts)
        _componentJsonDependencies = componentJsonDependencies.concat \
            _getRuleBookTargetsByTag('component-build-prerequisite').concat \
                [ '|', buildPath ]
        targets: componentJsonTarget
        dependencies: _componentJsonDependencies
        actions: [
            "$(COMPONENT_GENERATOR) $< $@ #{args.join ' '}"
        ]

    # now we prepare component install
    addMkdirRule ruleBook, globalRemoteComponentDirectory
    remoteComponentDir = path.join buildPath, 'components'
    componentInstalledTarget = path.join buildPath, 'component-installed'
    if manifest.client?.dependencies?
        ruleBook.addRule componentInstalledTarget, [], ->
            targets: componentInstalledTarget
            dependencies: [ componentJsonTarget,'|', remoteComponentDir]
            actions: [
                "cd #{buildPath} && $(COMPONENT_INSTALL) $(COMPONENT_INSTALL_FLAGS)"
                "touch #{componentInstalledTarget}"
            ]
        ruleBook.addRule remoteComponentDir, [], ->
            targets: remoteComponentDir
            dependencies: [ '|', globalRemoteComponentDirectory ]
            actions: [
                "test -d #{remoteComponentDir} || ln -s #{globalRemoteComponentDirectory} #{remoteComponentDir}"
            ]
    else
        ruleBook.addRule componentInstalledTarget, [], ->
            targets: componentInstalledTarget
            dependencies: componentJsonTarget

    # component build rule
    componentBuildRules(ruleBook, manifest.name, buildPath, 'component-build')

    ruleBook.addRule '#{featurePath}/build: (for component-build)', [], ->
        targets: path.join featurePath, 'build'
        dependencies: [ componentJsonTarget ]
    addPhonyRule ruleBook, path.join featurePath, 'build'

    ruleBook.addRule 'build: (global build rule of #{featurePath})', [], ->
        targets: 'build'
        dependencies: path.join featurePath, 'build'
    addPhonyRule ruleBook, 'build'


# depends on build/feature/component-installed target
exports.componentBuildRules =  componentBuildRules = \
        (ruleBook, manifestName, buildPath, relativeComponentBuildPath) ->
    # generate what ever component-build do
    componentBuildDirectory = path.join buildPath, relativeComponentBuildPath # build/lib/foobar/component-build

    ruleBook.addRule componentBuildDirectory, [], ->
        targets: componentBuildDirectory
        dependencies: path.join buildPath, 'component-installed'
        actions: [
            "cd #{buildPath} && $(COMPONENT_BUILD) $(COMPONENT_BUILD_FLAGS) " +
                " --name #{manifestName} -v -o #{relativeComponentBuildPath}"
            "touch #{relativeComponentBuildPath}"
        ]

    return componentBuildDirectory




