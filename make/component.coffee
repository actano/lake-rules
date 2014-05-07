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

{replaceExtension, addMkdirRuleOfFile, addMkdirRule} = require '../helper/filesystem'
{addPhonyRule} = require '../helper/phony'
{addCoffeeRule} = require '../helper/coffeescript'

COMPONENT_BUILD_DIR = 'component-build'

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

    _compileJadeTemplatesToJavaScript = (srcFile) ->
        target = replaceExtension(_dest(srcFile), '.js')
        targetDir = path.dirname target
        ruleBook.addRule  target, [], ->
            targets: target
            dependencies: [ _src(srcFile), '|', targetDir ]
            actions: "$(JADEC) --client --out \"$@\" \"$<\""
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
            target = addCoffeeRule ruleBook, _src(scriptSrcFile), _dest(scriptSrcFile)
            componentJsonDependencies.push target
            addMkdirRuleOfFile ruleBook, target

    # has jade templates
    if manifest.client.templates?.length > 0
        for jadeTemplate in manifest.client.templates
            target = _compileJadeTemplatesToJavaScript(jadeTemplate)
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
    componentJsonTarget =_dest 'component.json'
    addMkdirRule ruleBook, buildPath

    translations = require './translations'
    translationScripts = translations.getTargets lake, manifest, 'scripts'

    fontcustom = require '../fontcustom'
    fontcustomFonts = fontcustom.getTargets lake, manifest, 'fonts'
    fontcustomStyles = fontcustom.getTargets lake, manifest, 'styles'

    args = []
    args = args.concat ("--add-script #{path.relative buildPath, x}" for x in translationScripts)
    args = args.concat ("--add-style #{path.relative buildPath, x}" for x in fontcustomStyles)
    args = args.concat ("--add-font #{path.relative buildPath, x}" for x in fontcustomFonts)

    componentJsonDependencies = componentJsonDependencies.concat(translationScripts).concat(fontcustomFonts).concat(fontcustomStyles).concat(['|', buildPath])

    ruleBook.addRule componentJsonTarget, [], ->
        targets: componentJsonTarget
        dependencies: componentJsonDependencies
        actions: "$(COMPONENT_GENERATOR) $< $@ #{args.join ' '}"

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
    componentBuildTargets = getTargets(buildPath, 'component-build')
    ruleBook.addRule componentBuildTargets.target, [], ->
        targets: componentBuildTargets.target
        dependencies: _dest('component-installed')
        actions: [
                "cd #{buildPath} && $(COMPONENT_BUILD) $(COMPONENT_BUILD_FLAGS) " +
                " --name #{manifest.name} -v -o #{COMPONENT_BUILD_DIR}"
                "touch #{componentBuildTargets.target}"
        ]

    # phony targets for component build
    localTarget = _src COMPONENT_BUILD_DIR
    ruleBook.addRule localTarget, [], ->
        targets: localTarget
        dependencies: componentBuildTargets.target
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



exports.getTargets = getTargets = (buildPath, tag) ->
    switch tag
        when 'component-build'
            target = path.join buildPath, COMPONENT_BUILD_DIR, 'component-is-build'
            target: target
            targetDst: path.dirname target
        else
            throw new Error("unknown tag '#{tag}'")



