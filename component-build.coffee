# Std library
path = require 'path'

# Local dep
{addMkdirRule} = require './helper/filesystem'
Rule = require './helper/rule'

# Rule dep
component = require './component'

COMPONENT_BUILD_DIR = 'component-build'

exports.title = 'component-build make targets'
exports.description = "build a tj main component"
exports.readme =
      name: 'component-build'
      path: path.join __dirname, 'component-build.md'

installComponentDependencies = (config, manifest) ->
    return unless manifest.client?.dependencies?

    # mkdir to remoteComponentPath (cache)
    remoteComponentPath = config.remoteComponentPath
    addMkdirRule remoteComponentPath

    # Actually install dependencies (touch-file target for dependency check)
    # This needs to live next-to component.json
    componentInstallTarget = getComponentInstallTarget config, manifest

    new Rule componentInstallTarget
        .info "$@"
        .prerequisite component.getComponentTarget path.dirname componentInstallTarget
        .orderOnly remoteComponentPath
        .buildServer 'component-install', null, remoteComponentPath
        .action '@touch $@'
        .write()
    return componentInstallTarget

buildComponent = (config, manifest, buildPath) ->
    throw new Error "manifest #{manifest.featurePath} contains no client side" unless manifest.client?
    originalBuildPath = path.join config.featureBuildDirectory, manifest.featurePath

    componentJsonTarget = component.getComponentTarget originalBuildPath

    # component build rule
    if buildPath?
        componentBuildTarget = path.join buildPath, "#{path.basename manifest.featurePath}.js"
    else
        componentBuildTarget = getComponentBuildTarget originalBuildPath
    noRequire = manifest.client.require is false
    new Rule componentBuildTarget
        .prerequisite getComponentInstallTarget config, manifest
        .prerequisite componentJsonTarget
        .buildServer 'component-build', null, null, config.remoteComponentPath, manifest.name, if noRequire then true else null
        .write()

    return componentBuildTarget

exports.addRules = (config, manifest) ->
    # make sure we are a component feature
    return if not manifest.client?

    installComponentDependencies config, manifest
    target = buildComponent config, manifest

    # phony targets for component build
    new Rule path.join manifest.featurePath, COMPONENT_BUILD_DIR
        .prerequisite target
        .phony()
        .write()

getComponentInstallTarget = (config, manifest) ->
    buildPath = path.join config.featureBuildDirectory, manifest.featurePath
    path.join buildPath, 'remote-components.d'

getComponentBuildTarget = (buildPath) ->
    path.join buildPath, COMPONENT_BUILD_DIR, "#{path.basename buildPath}.js"

exports.getComponentBuildTargets = (buildPath) ->
    target = getComponentBuildTarget buildPath
    target: target
    targetDst: path.dirname target

exports.buildComponent = buildComponent
