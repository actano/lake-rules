# Std library
path = require 'path'

# Local dep
{replaceExtension, addMkdirRuleOfFile, addMkdirRule} = require './helper/filesystem'
fs = require './helper/filesystem'
{addJadeJavascriptRule} = require './helper/jade'
{addStylusRule} = require './helper/stylus'
Rule = require './helper/rule'

# Rule dep
translations = require './translations'

exports.title = 'component.json make targets'
exports.description = "creates the  component.json and compiles all component assets"
exports.readme =
    name: 'component'
    path: path.join __dirname, 'component.md'
exports.addRules = (config, manifest) ->

    # make sure we are a component feature
    return if not manifest.client?

#   TODO activate and clean up before or solve the issue in a different way
#    if not manifest.client.scripts?.length or not manifest.client.main?
#        throw new Error("manifest '#{manifest.name}' has a client section and therfore MUST HAVE a client.scripts and client.main entry")

    buildPath = path.join config.featureBuildDirectory, manifest.featurePath # build/lib/foobar
    _src = (script) -> path.join manifest.featurePath, script
    _dest = (script) -> path.join buildPath, script
    _featureDep = (localDep) -> path.normalize(_src(localDep))
    _featureBuildDep = (localDep) -> getComponentTarget path.normalize path.join buildPath, localDep
    _makeArray = (value) -> [].concat(value or [])

    srcManifest = manifest.resolveManifest()
    componentJsonDependencies = [srcManifest]

    _compileJadeTemplatesToJavaScript = (srcFile, srcDeps) ->
        target = replaceExtension(_dest(srcFile), '.js')
        localDeps = jadeDeps.map (dep) -> _featureBuildDep(dep)
        localDeps.unshift srcManifest
        addJadeJavascriptRule _src(srcFile), target, localDeps, srcDeps.map _featureDep

    _compileStylusToCSS = (srcFile, srcDeps) ->
        target = replaceExtension(_dest(srcFile), '.css')
        localDeps = srcDeps.map((dep) -> _featureBuildDep(dep))
        localDeps.unshift srcManifest
        addStylusRule _src(srcFile), target, localDeps, srcDeps.map _featureDep

    _copyImageFile = (srcFile) ->
        return fs.addCopyRule _src(srcFile), _dest(srcFile)

    # has client scripts
    if manifest.client?.scripts?.length > 0
        for scriptSrcFile in manifest.client.scripts
            target = fs.addCopyRule _src(scriptSrcFile), _dest(scriptSrcFile)
            componentJsonDependencies.push target

    # has client scripts for development
    if manifest.client?.dependencies?.development?.scripts?.length > 0
        for scriptSrcFile in manifest.client.dependencies.development.scripts
            target = fs.addCopyRule _src(scriptSrcFile), _dest(scriptSrcFile)
            componentJsonDependencies.push target

    # has jade templates
    if manifest.client.templates?.length > 0 or manifest.client.templates?.files?.length > 0
        jadeFiles = manifest.client.templates.files or manifest.client.templates
        jadeDeps = _makeArray manifest.client?.templates?.dependencies
        for jadeTemplate in jadeFiles
            target = _compileJadeTemplatesToJavaScript(jadeTemplate, jadeDeps)
            componentJsonDependencies.push target


    # has client styles
    if manifest.client?.styles?.length > 0 or manifest.client?.styles?.files?.length > 0
        stylusFiles = manifest.client.styles.files or manifest.client.styles
        stylusDeps = [].concat(manifest.client.styles.dependencies).filter (dep) ->
            dep?

        for styleSrcFile in stylusFiles
            target =  _compileStylusToCSS(styleSrcFile, stylusDeps)
            componentJsonDependencies.push target

    # has client images
    if manifest.client?.images?.length > 0
        for imageFile in manifest.client.images
            target = _copyImageFile(imageFile)
            componentJsonDependencies.push target


    if manifest.client.dependencies?.production?.local?
        componentJsonDependencies = componentJsonDependencies.concat \
            manifest.client.dependencies.production.local.map (localDep) ->
                _featureBuildDep localDep

    # create component.json from Manifest
    componentJsonTarget =_dest 'component.json'
    addMkdirRule buildPath

    translationScripts = translations.getTargets config, manifest, 'scripts'

    new Rule componentJsonTarget
        .prerequisite componentJsonDependencies
        .prerequisite translationScripts
        .orderOnly buildPath
        .buildServer 'component.json', null, null, (path.relative(buildPath, x) for x in translationScripts)...
        .write()

    # phony targets for component.json

    new Rule _src 'build'
        .prerequisiteOf 'build'
        .prerequisite componentJsonTarget
        .phony()
        .write()

    new Rule manifest.featurePath
        .prerequisite _src 'build'
        .phony()
        .write()

exports.getComponentTarget = getComponentTarget = (buildPath) ->
    _dest = (script) -> path.join buildPath, script
    return _dest 'component.json'

