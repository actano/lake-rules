###
    generates make rules for a tj component

    defines the following main make targets

    component build:
        compile artefacts like stylus, coffee, jade
        generates a component.json from a Manifest.coffee
        add rules for component build step
            install remote components
            build local component dependencies

        output contract:
            creates a component.json in BUILD_DIR/FEATURE_DIR
            creates a component-is-build target in BUILD_DIR/FEATURE_DIR/component-build/component-is-build
            with the component-is-build target a main component is created

    component install
        is doing NOTHING cause a component itself has nothing to distrubute.
        this is part "main component" targets like pages or widgets

    TODO cleanup translations, fontcustom
###

path = require 'path'

_ = require 'underscore'

{
    replaceExtension
    addMkdirRuleOfFile
    addMkdirRule
    addPhonyRule
} = require '../rulebook_helper'

exports.title = 'component.json make targets'
exports.description = "creates the  component.json and build the prerequisites"
exports.readme =
    name: 'component'
    path: path.join __dirname, 'component.md'
exports.addRules = (lake, featurePath, manifest, ruleBook) ->

    # make sure we are a component feature
    return if not manifest.client?

    buildPath = path.join lake.featureBuildDirectory, featurePath # build/lib/foobar
    globalRemoteComponentDirectory = path.join manifest.projectRoot, lake.remoteComponentPath

    _src = (script) -> path.join featurePath, script
    _dest = (script) -> path.join buildPath, script
    _featureDep = (localDep) -> path.normalize(path.join(featurePath, localDep))
    _componentJsonDep = (localDep) -> path.normalize(path.join(buildPath, localDep, 'component.json'))

    componentJsonDependencies = [_src 'Manifest.coffee']

    _compileCoffeeToJavaScript = (srcFile) ->
        target = replaceExtension(_dest(srcFile), '.js')
        targetDir = path.dirname target
        ruleBook.addRule  target, [], ->
            targets: target
            dependencies: [ _src(srcFile), '|', targetDir ]
            actions: "$(COFFEEC) -c $(COFFEE_FLAGS) -o #{targetDir} $^"
        return target

    _compileJadeTemplatesToJavaScript = (srcFile, options) ->
        target = replaceExtension(_dest(srcFile), '.js')
        targetDir = path.dirname target
        ruleBook.addRule  target, [], ->
            targets: target
            dependencies: [ _src(srcFile), '|', targetDir ]
            actions: "$(JADEREQUIRE) #{options} --out \"$@\" \"$<\""
        return target

    _compileJadeMixinsToJavaScript = (srcFile) ->
        target = replaceExtension(_dest(srcFile), '.js')
        targetDir = path.dirname target
        ruleBook.addRule  target, [], ->
            targets: target
            dependencies: [ _src(srcFile), '|', targetDir ]
            actions: "$(JADEMIXIN) < $< > $@"
        return target

    _compileStylusToCSS = (srcFile, srcDeps) ->
        target = replaceExtension(_dest(srcFile), '.css')
        targetDir = path.dirname target
        includes = srcDeps.map((dep) -> "--include #{_featureDep(dep)}").join(' ')
        localDeps = srcDeps.map((dep) -> _componentJsonDep(dep))
        ruleBook.addRule  target, [], ->
            targets: target
            dependencies: [ _src(srcFile) ].concat(localDeps).concat ['|', targetDir ]
            actions: "$(STYLUSC) $(STYLUS_FLAGS) #{includes} -o #{targetDir} $<"
        return target

    _copyImageFile = (srcFile) ->
        target = _dest(srcFile)
        targetDir = path.dirname target
        ruleBook.addRule  target, [], ->
            targets: target
            dependencies: [ _src(srcFile), '|', targetDir ]
            actions: "cp #{_src(srcFile)} #{target}"
        return target

    # has client scripts
    if manifest.client?.scripts?.length > 0
        for scriptSrcFile in manifest.client.scripts
            target = _compileCoffeeToJavaScript(scriptSrcFile)
            componentJsonDependencies.push target
            addMkdirRuleOfFile ruleBook, target


    # has jade templates
    if manifest.client.templates?.length > 0
        if manifest.client.mixins?.require
            options = "--obj '#{JSON.stringify(mixins: manifest.client.mixins.require)}'"
        else
            options = ""
        for jadeTemplate in manifest.client.templates
            target = _compileJadeTemplatesToJavaScript(jadeTemplate, options)
            componentJsonDependencies.push target
            addMkdirRuleOfFile ruleBook, target


    # has jade mixins
    if manifest.client.mixins?.export?.length > 0
        for jadeMixin in manifest.client.mixins.export
            target = _compileJadeMixinsToJavaScript(jadeMixin)
            componentJsonDependencies.push target
            addMkdirRuleOfFile ruleBook, target

    # has client styles
    if manifest.client?.styles?.length > 0 or manifest.client?.styles?.files?.length > 0
        stylusFiles = manifest.client.styles.files or manifest.client.styles
        stylusDeps = [].concat(manifest.client.styles.dependencies).filter (dep) ->
            dep?

        for styleSrcFile in stylusFiles
            target =  _compileStylusToCSS(styleSrcFile, stylusDeps)
            componentJsonDependencies.push target
            addMkdirRuleOfFile ruleBook, target

    # has client images
    if manifest.client?.images?.length > 0
        for imageFile in manifest.client.images
            target = _copyImageFile(imageFile)
            componentJsonDependencies.push target
            addMkdirRuleOfFile ruleBook, target


    if manifest.client.dependencies?.production?.local?
        componentJsonDependencies = componentJsonDependencies.concat \
            manifest.client.dependencies.production.local.map (localDep) ->
                _componentJsonDep localDep

    # create component.json from Manifest
    _getRuleBookTargetsByTag = (tag) ->
        _(rule.targets for rule in ruleBook.getRulesByTag(tag)).flatten()
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
    componentInstalledTarget = _dest('component-installed')
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
    componentBuild = componentBuildTarget(buildPath)
    ruleBook.addRule componentBuild.target, [], ->
        targets: componentBuild.target
        dependencies: _dest('component-installed')
        actions: [
                "cd #{buildPath} && $(COMPONENT_BUILD) $(COMPONENT_BUILD_FLAGS) " +
                " --name #{manifest.name} -v -o #{componentBuild.componentBuildDir}"
                "touch #{componentBuild.target}"
        ]

    # phony targets for component build
    localTarget = _src componentBuild.componentBuildDir
    ruleBook.addRule localTarget, [], ->
        targets: localTarget
        dependencies: componentBuild.target
    addPhonyRule ruleBook, localTarget

    # phony targets for component.json
    ruleBook.addRule '#{featurePath}/build: (for component-build)', [], ->
        targets: _src 'build'
        dependencies: [ componentJsonTarget ]
    addPhonyRule ruleBook, _src 'build'

    ruleBook.addRule 'build: (global build rule of #{featurePath})', [], ->
        targets: 'build'
        dependencies: _src 'build'
    addPhonyRule ruleBook, 'build'




exports.componentBuildTarget = componentBuildTarget = (buildPath) ->
    # build/lib/foobar/component-build/component-is-build
    componentBuildDir = 'component-build'
    target = path.join buildPath, componentBuildDir, 'component-is-build'

    target: target
    targetDst: path.dirname target
    componentBuildDir: componentBuildDir


