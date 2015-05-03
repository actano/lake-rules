# Std library
path = require 'path'

# Local dep
{replaceExtension, addMkdirRuleOfFile, addMkdirRule} = require './helper/filesystem'
{addPhonyRule} = require './helper/phony'
fs = require './helper/filesystem'
{addJadeJavascriptRule} = require './helper/jade'

# Rule dep
translations = require './translations'

COMPONENT_GENERATOR = "$(NODE_BIN)/coffee #{path.join __dirname, 'create_component_json.coffee'}"

exports.title = 'component.json make targets'
exports.description = "creates the  component.json and compiles all component assets"
exports.readme =
    name: 'component'
    path: path.join __dirname, 'component.md'
exports.addRules = (config, manifest, addRule) ->

    # make sure we are a component feature
    return if not manifest.client?

#   TODO activate and clean up before or solve the issue in a different way
#    if not manifest.client.scripts?.length or not manifest.client.main?
#        throw new Error("manifest '#{manifest.name}' has a client section and therfore MUST HAVE a client.scripts and client.main entry")

    buildPath = path.join config.featureBuildDirectory, config.featurePath # build/lib/foobar
    _src = (script) -> path.join config.featurePath, script
    _dest = (script) -> path.join buildPath, script
    _featureDep = (localDep) -> path.normalize(_src(localDep))
    _featureBuildDep = (localDep) -> getTargets(path.normalize(path.join(buildPath, localDep)), 'component')
    _makeArray = (value) -> [].concat(value or [])

    componentJsonDependencies = [_src 'Manifest.coffee']

    _compileJadeTemplatesToJavaScript = (srcFile, srcDeps) ->
        includes = srcDeps.map((dep) -> "--include #{_featureDep(dep)}").join(' ')
        localDeps = jadeDeps.map (dep) -> _featureBuildDep(dep)
        localDeps.unshift(_src('Manifest.coffee'))
        addJadeJavascriptRule addRule, _src(srcFile), replaceExtension(_dest(srcFile), '.js'), localDeps, includes

    _compileStylusToCSS = (srcFile, srcDeps) ->
        target = replaceExtension(_dest(srcFile), '.css')
        targetDir = path.dirname target
        includes = srcDeps.map((dep) -> "--include #{_featureDep(dep)}").join(' ')
        localDeps = srcDeps.map((dep) -> _featureBuildDep(dep))
        localDeps.unshift(_src('Manifest.coffee'))
        addRule
            targets: target
            dependencies: [ _src(srcFile) ].concat(localDeps).concat ['|', targetDir ]
            actions: "$(NODE_BIN)/stylus #{includes} -o #{targetDir} --inline $<"
        return target

    _copyImageFile = (srcFile) ->
        target = _dest(srcFile)
        targetDir = path.dirname target
        addRule
            targets: target
            dependencies: [ _src(srcFile), '|', targetDir ]
            actions: "cp #{_src(srcFile)} #{target}"
        return target

    # has client scripts
    if manifest.client?.scripts?.length > 0
        for scriptSrcFile in manifest.client.scripts
            target = fs.addCopyRule addRule, _src(scriptSrcFile), _dest(scriptSrcFile)
            componentJsonDependencies.push target
            addMkdirRuleOfFile addRule, target

    # has client scripts for development
    if manifest.client?.dependencies?.development?.scripts?.length > 0
        for scriptSrcFile in manifest.client.dependencies.development.scripts
            target = fs.addCopyRule addRule, _src(scriptSrcFile), _dest(scriptSrcFile)
            componentJsonDependencies.push target
            addMkdirRuleOfFile addRule, target

    # has jade templates
    if manifest.client.templates?.length > 0 or manifest.client.templates?.files?.length > 0
        jadeFiles = manifest.client.templates.files or manifest.client.templates
        jadeDeps = _makeArray manifest.client?.templates?.dependencies
        for jadeTemplate in jadeFiles
            target = _compileJadeTemplatesToJavaScript(jadeTemplate, jadeDeps)
            componentJsonDependencies.push target
            addMkdirRuleOfFile addRule, target


    # has client styles
    if manifest.client?.styles?.length > 0 or manifest.client?.styles?.files?.length > 0
        stylusFiles = manifest.client.styles.files or manifest.client.styles
        stylusDeps = [].concat(manifest.client.styles.dependencies).filter (dep) ->
            dep?

        for styleSrcFile in stylusFiles
            target =  _compileStylusToCSS(styleSrcFile, stylusDeps)
            componentJsonDependencies.push target
            addMkdirRuleOfFile addRule, target

    # has client images
    if manifest.client?.images?.length > 0
        for imageFile in manifest.client.images
            target = _copyImageFile(imageFile)
            componentJsonDependencies.push target
            addMkdirRuleOfFile addRule, target


    if manifest.client.dependencies?.production?.local?
        componentJsonDependencies = componentJsonDependencies.concat \
            manifest.client.dependencies.production.local.map (localDep) ->
                _featureBuildDep localDep

    # create component.json from Manifest
    componentJsonTarget =_dest 'component.json'
    addMkdirRule addRule, buildPath

    translationScripts = translations.getTargets config, manifest, 'scripts'

    args = []
    args = args.concat ("--add-script #{path.relative buildPath, x}" for x in translationScripts)

    componentJsonDependencies = componentJsonDependencies
        .concat(translationScripts)
        .concat(['|', buildPath])

    addRule
        targets: componentJsonTarget
        dependencies: componentJsonDependencies
        actions: "#{COMPONENT_GENERATOR} $< $@ #{args.join ' '}"

    # phony targets for component.json
    addRule
        targets: _src 'build'
        dependencies: [ componentJsonTarget ]
    addPhonyRule addRule, _src 'build'

    addRule
        targets: config.featurePath
        dependencies: _src 'build'
    addPhonyRule addRule, config.featurePath

    addRule
        targets: 'build'
        dependencies: _src 'build'
    addPhonyRule addRule, 'build'

exports.getTargets = getTargets = (buildPath, tag) ->
    switch tag
        when 'component'
            _dest = (script) -> path.join buildPath, script
            return _dest 'component.json'
        else
            throw new Error("unknown tag '#{tag}'")
