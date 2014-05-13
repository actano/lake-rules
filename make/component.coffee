# Std library
path = require 'path'

# Local dep
{replaceExtension, addMkdirRuleOfFile, addMkdirRule} = require '../helper/filesystem'
{addPhonyRule} = require '../helper/phony'
{addCoffeeRule} = require '../helper/coffeescript'
{addJadeJavascriptRule, getJadeDependencies} = require '../helper/jade'

# Rule dep
translations = require './translations'
fontcustom = require '../fontcustom'

COMPONENT_GENERATOR = '$(NODE_BIN)/coffee $(TOOLS)/rules/make/create_component_json.coffee'

exports.title = 'component.json make targets'
exports.description = "creates the  component.json and compiles all component assets"
exports.readme =
    name: 'component'
    path: path.join __dirname, 'component.md'
exports.addRules = (lake, featurePath, manifest, ruleBook) ->

    # make sure we are a component feature
    return if not manifest.client?

    buildPath = path.join lake.featureBuildDirectory, featurePath # build/lib/foobar

    _src = (script) -> path.join featurePath, script
    _dest = (script) -> path.join buildPath, script
    _featureDep = (localDep) -> path.normalize(_src(localDep))
    _featureBuildDep = (localDep) -> path.normalize(path.join(buildPath, localDep, 'component.json'))

    componentJsonDependencies = [_src 'Manifest.coffee']

    _compileJadeTemplatesToJavaScript = (srcFile, srcDeps) ->
        includes = srcDeps.map((dep) -> "--include #{_featureDep(dep)}").join(' ')
        localDeps = jadeDeps.map (dep) -> _featureBuildDep(dep)
        localDeps.unshift(_src('Manifest.coffee'))
        addJadeJavascriptRule ruleBook, _src(srcFile), replaceExtension(_dest(srcFile), '.js'), localDeps, includes

    _compileStylusToCSS = (srcFile, srcDeps) ->
        target = replaceExtension(_dest(srcFile), '.css')
        targetDir = path.dirname target
        includes = srcDeps.map((dep) -> "--include #{_featureDep(dep)}").join(' ')
        localDeps = srcDeps.map((dep) -> _featureBuildDep(dep))
        localDeps.unshift(_src('Manifest.coffee'))
        ruleBook.addRule  target, [], ->
            targets: target
            dependencies: [ _src(srcFile) ].concat(localDeps).concat ['|', targetDir ]
            # TODO remove --include #{lake.featureBuildDirectory} after fontcustom clean up
            actions: "$(NODE_BIN)/stylus -u nib --include #{lake.featureBuildDirectory} #{includes} -o #{targetDir} $<"
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
    if manifest.client.templates?.length > 0 or manifest.client.templates?.files?.length > 0
        jadeFiles = manifest.client.templates.files or manifest.client.templates
        jadeDeps = getJadeDependencies manifest
        for jadeTemplate in jadeFiles
            target = _compileJadeTemplatesToJavaScript(jadeTemplate, jadeDeps)
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
                _featureBuildDep localDep

    # create component.json from Manifest
    componentJsonTarget =_dest 'component.json'
    addMkdirRule ruleBook, buildPath

    translationScripts = translations.getTargets lake, manifest, 'scripts'
    fontcustomFonts = fontcustom.getTargets lake, manifest, 'fonts'
    fontcustomStyles = fontcustom.getTargets lake, manifest, 'styles'

    args = []
    args = args.concat ("--add-script #{path.relative buildPath, x}" for x in translationScripts)
    args = args.concat ("--add-style #{path.relative buildPath, x}" for x in fontcustomStyles)
    args = args.concat ("--add-font #{path.relative buildPath, x}" for x in fontcustomFonts)

    componentJsonDependencies = componentJsonDependencies
        .concat(translationScripts)
        .concat(fontcustomFonts)
        .concat(fontcustomStyles)
        .concat(['|', buildPath])

    ruleBook.addRule componentJsonTarget, [], ->
        targets: componentJsonTarget
        dependencies: componentJsonDependencies
        actions: "#{COMPONENT_GENERATOR} $< $@ #{args.join ' '}"

    # phony targets for component.json
    ruleBook.addRule '#{featurePath}/build: (build rule for component.json)', [], ->
        targets: _src 'build'
        dependencies: [ componentJsonTarget ]
    addPhonyRule ruleBook, _src 'build'

    ruleBook.addRule 'build: (global build rule of #{featurePath})', [], ->
        targets: 'build'
        dependencies: _src 'build'
    addPhonyRule ruleBook, 'build'

exports.getTargets = getTargets = (buildPath, tag) ->
    switch tag
        when 'component'
            _dest = (script) -> path.join buildPath, script
            return _dest 'component.json'
        else
            throw new Error("unknown tag '#{tag}'")
