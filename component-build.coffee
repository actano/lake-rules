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

    buildPath = path.join config.featureBuildDirectory, manifest.featurePath

    # mkdir to remoteComponentPath (cache)
    remoteComponentPath = config.remoteComponentPath
    addMkdirRule remoteComponentPath

    # Actually install dependencies (touch-file target for dependency check)
    # This needs to live next-to component.json
    componentInstalledTarget = path.join buildPath, 'remote-components.d'
    new Rule componentInstalledTarget
        .info "#{buildPath} (component-install)"
        .prerequisite component.getComponentTarget buildPath
        .orderOnly remoteComponentPath
        .buildServer 'component-install', null, remoteComponentPath
        .action '@touch $@'
        .write()
    return componentInstalledTarget

buildComponent = (config, manifest) ->
    buildPath = path.join config.featureBuildDirectory, manifest.featurePath
    componentJsonTarget = component.getComponentTarget buildPath

    componentInstalledTarget = installComponentDependencies config, manifest

    # component build rule
    componentBuildTarget = getComponentBuildTarget buildPath
    noRequire = manifest.client.require is false
    new Rule componentBuildTarget
        .prerequisite componentInstalledTarget
        .prerequisite componentJsonTarget
        .buildServer 'component-build', null, null, config.remoteComponentPath, manifest.name, if noRequire then true else null
        .write()

    return componentBuildTarget

exports.addRules = (config, manifest) ->
    # make sure we are a component feature
    return if not manifest.client?

    target = buildComponent config, manifest

    # phony targets for component build
    new Rule path.join manifest.featurePath, COMPONENT_BUILD_DIR
        .prerequisite target
        .phony()
        .write()

getComponentBuildTarget = (buildPath) ->
    path.join buildPath, COMPONENT_BUILD_DIR, "#{path.basename buildPath}.js"

exports.getComponentBuildTargets = (buildPath) ->
    target = getComponentBuildTarget buildPath
    target: target
    targetDst: path.dirname target
