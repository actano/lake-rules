# Std library
path = require 'path'

# Local dep
{addMkdirRule} = require './helper/filesystem'
{addPhonyRule} = require './helper/phony'

# Rule dep
{command, prereq} = require './helper/build-server'
component = require './component'

COMPONENT_BUILD_DIR = 'component-build'

exports.title = 'component-build make targets'
exports.description = "build a tj main component"
exports.readme =
      name: 'component-build'
      path: path.join __dirname, 'component-build.md'

exports.addRules = (config, manifest, addRule) ->
    # make sure we are a component feature
    return if not manifest.client?

    buildPath = path.join config.featureBuildDirectory, config.featurePath # build/lib/foobar
    remoteComponentPath = config.remoteComponentPath

    _src = (script) -> path.join config.featurePath, script
    _dest = (script) -> path.join buildPath, script

    componentJsonTarget = component.getTargets(buildPath, 'component')

    # now we prepare component install
    addMkdirRule addRule, remoteComponentPath
    remoteComponentDir = _dest 'components'
    componentInstalledTarget = _dest('component-installed')
    if manifest.client?.dependencies?
        addRule
            targets: componentInstalledTarget
            dependencies: prereq [ componentJsonTarget ]
            actions: [
                command 'component-install', null, '$(REMOTE_COMPONENTS)'
                '@touch $@'
            ]
        addRule
            targets: remoteComponentDir
            dependencies: [ '|', remoteComponentPath ]
            actions: [
                "@test -d #{remoteComponentDir} || ln -s #{remoteComponentPath} #{remoteComponentDir}"
            ]
            silent: true
    else
        addRule
            targets: componentInstalledTarget
            dependencies: componentJsonTarget

    # component build rule
    componentBuildTargets = getTargets(buildPath, 'component-build')
    noRequire = manifest.client.require is false
    addRule
        targets: componentBuildTargets.target
        dependencies: prereq [ _dest('component-installed'), componentJsonTarget ] #, '|', remoteComponentDir ]
        actions: [
            command 'component-build', null, null, '$(REMOTE_COMPONENTS)', manifest.name, if noRequire then true else null
            '@touch $@'
        ]

    # phony targets for component build
    localTarget = _src COMPONENT_BUILD_DIR
    addRule
        targets: localTarget
        dependencies: componentBuildTargets.target
    addPhonyRule addRule, localTarget


exports.getTargets = getTargets = (buildPath, tag) ->
  switch tag
    when 'component-build'
      target = path.join buildPath, COMPONENT_BUILD_DIR, 'component-is-build'
      target: target
      targetDst: path.dirname target
    else
      throw new Error("unknown tag '#{tag}'")



