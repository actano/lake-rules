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

installComponentDependencies = (config, manifest, buildPath) ->
    return unless manifest.client?.dependencies?

    # mkdir to remoteComponentPath (cache)
    remoteComponentPath = config.remoteComponentPath
    addMkdirRule remoteComponentPath

    # link from local components directory to cache
    remoteComponentDir = path.join buildPath, 'components'
    new Rule remoteComponentDir
        .orderOnly remoteComponentPath
        .action "@test -d #{remoteComponentDir} || ln -s #{remoteComponentPath} #{remoteComponentDir}"
        .silent()
        .write()

    # Actually install dependencies (touch-file target for dependency check)
    componentInstalledTarget = "#{remoteComponentDir}.d"
    new Rule componentInstalledTarget
        .info "#{buildPath} (component-install)"
        .prerequisite component.getTargets(buildPath, 'component')
        .orderOnly remoteComponentDir
        .buildServer 'component-install', null, remoteComponentPath
        .action '@touch $@'
        .write()
    return componentInstalledTarget

buildComponent = (config, manifest, buildPath) ->
    componentJsonTarget = component.getTargets(buildPath, 'component')

    componentInstalledTarget = installComponentDependencies config, manifest, buildPath

    # component build rule
    componentBuildTargets = getTargets(buildPath, 'component-build')
    noRequire = manifest.client.require is false
    new Rule componentBuildTargets.target
        .prerequisite componentInstalledTarget
        .prerequisite componentJsonTarget
        .buildServer 'component-build', null, null, config.remoteComponentPath, manifest.name, if noRequire then true else null
        .write()

    return componentBuildTargets.target

exports.addRules = (config, manifest) ->
    # make sure we are a component feature
    return if not manifest.client?

    target = buildComponent config, manifest, path.join config.featureBuildDirectory, manifest.featurePath

    # phony targets for component build
    new Rule path.join manifest.featurePath, COMPONENT_BUILD_DIR
        .prerequisite target
        .phony()
        .write()

exports.getTargets = getTargets = (buildPath, tag) ->
  switch tag
    when 'component-build'
      target = path.join buildPath, COMPONENT_BUILD_DIR, "#{path.basename buildPath}.js"
      target: target
      targetDst: path.dirname target
    else
      throw new Error("unknown tag '#{tag}'")
