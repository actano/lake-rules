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

    _src = (script) -> path.join featurePath, script
    _dest = (script) -> path.join buildPath, script
    _featureDep = (localDep) -> path.normalize(path.join(featurePath, localDep))
    _componentJsonDep = (localDep) -> path.normalize(path.join(buildPath, localDep, 'component.json'))

    componentJsonDependencies = [_src 'Manifest.coffee']

    _compileCoffeeToJavaScript = (srcFile) ->
        target = replaceExtension(_dest(srcFile), '.js')
        componentJsonDependencies.push target
        targetDir = addMkdirRuleOfFile ruleBook, target
        ruleBook.addRule  target, [], ->
            targets: target
            dependencies: [ _src(srcFile), '|', targetDir ]
            actions: "$(COFFEEC) -c $(COFFEE_FLAGS) -o #{targetDir} $^"
        return target


    _compileStylusToCSS = (srcFile, srcDeps) ->
        target = replaceExtension(_dest(srcFile), '.css')
        componentJsonDependencies.push target
        targetDir = addMkdirRuleOfFile ruleBook, target
        includes = srcDeps.map((dep) -> "--include #{_featureDep(dep)}").join(' ')
        localDeps = srcDeps.map((dep) -> _componentJsonDep(dep))
        ruleBook.addRule  target, [], ->
            targets: target
            dependencies: [ _src(srcFile) ].concat(localDeps).concat ['|', targetDir ]
            actions: "$(STYLUSC) $(STYLUS_FLAGS) #{includes} -o #{targetDir} $<"
        return target

    _copyImageFile = (srcFile) ->
        target = _dest(srcFile)
        componentJsonDependencies.push target
        targetDir = addMkdirRuleOfFile ruleBook, target
        ruleBook.addRule  target, [], ->
            targets: target
            dependencies: [ _src(srcFile), '|', targetDir ]
            actions: "cp #{_src(srcFile)} #{target}"
        return target

    # MUST be called inside of a rulebook function
    # TODO remove getRulesBy* calls
    _getRuleBookTargetsByTag = (tag) ->
        _(rule.targets for rule in ruleBook.getRulesByTag(tag)).flatten()


    # has client scripts
    componentScriptFiles = []
    if manifest.client?.scripts?.length > 0
        for scriptSrcFile in manifest.client.scripts
            componentScriptFiles.push _compileCoffeeToJavaScript(scriptSrcFile)


    # has client styles
    componentStyleFiles = []
    if manifest.client?.styles?.length > 0 or manifest.client?.styles?.files?.length > 0
        stylusFiles = manifest.client.styles.files or manifest.client.styles
        stylusDeps = [].concat(manifest.client.styles.dependencies).filter (dep) ->
            dep?

        for styleSrcFile in stylusFiles
            componentStyleFiles.push \
                _compileStylusToCSS(styleSrcFile, stylusDeps)

    # has client images
    componentImageFiles = []
    if manifest.client?.images?.length > 0
        for imageFile in manifest.client.images
            componentImageFiles.push imageFile
            _copyImageFile(imageFile)

    if manifest.client.dependencies?.production?.local?
        componentJsonDependencies = componentJsonDependencies.concat \
            manifest.client.dependencies.production.local.map (localDep) ->
                _componentJsonDep localDep

    # create component.json from Manifest
    componentJsonTarget =_dest 'component.json'
    addMkdirRule ruleBook, buildPath
    ruleBook.addRule componentJsonTarget, [], ->
        # TODO kick getRulesBy*
        # we still get input from translations and fontcustom here
        additionalScripts =  _getRuleBookTargetsByTag('add-to-component-scripts')
        additionalStyles = _getRuleBookTargetsByTag('add-to-component-styles')
        additionalFonts = _getRuleBookTargetsByTag('add-to-component-fonts')
        args = ("--add-script #{path.relative buildPath, x}" for x in additionalScripts)
        args = args.concat ("--add-style #{path.relative buildPath, x}" for x in additionalStyles)
        args = args.concat ("--add-font #{path.relative buildPath, x}" for x in additionalFonts)
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
    remoteComponentDir = _dest 'components'
    componentInstalledTarget = _componentIntsallTarget(buildPath)
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
        targets: _src 'build'
        dependencies: [ componentJsonTarget ]
    addPhonyRule ruleBook, _src 'build'

    ruleBook.addRule 'build: (global build rule of #{featurePath})', [], ->
        targets: 'build'
        dependencies: _src 'build'
    addPhonyRule ruleBook, 'build'

_componentIntsallTarget = (buildPath) ->
    path.join buildPath, 'component-installed'

# depends on build/feature/component-installed target
exports.componentBuildRules =  componentBuildRules = \
        (ruleBook, manifestName, buildPath, relativeComponentBuildPath) ->
    # generate what ever component-build do
    componentTouchTarget = componentBuildTarget(buildPath, relativeComponentBuildPath)

    ruleBook.addRule componentTouchTarget, [], ->
        targets: componentTouchTarget
        dependencies: _componentIntsallTarget(buildPath)
        actions: [
            "cd #{buildPath} && $(COMPONENT_BUILD) $(COMPONENT_BUILD_FLAGS) " +
                " --name #{manifestName} -v -o #{relativeComponentBuildPath}"
            "touch #{componentTouchTarget}"
        ]

    return componentTouchTarget

exports.componentBuildTarget = componentBuildTarget = \
        (buildPath, relativeComponentBuildPath) ->
    # build/lib/foobar/component-build/component-is-build
    path.join buildPath, relativeComponentBuildPath, 'component-is-build'


