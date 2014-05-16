# Std library
path = require 'path'

# Local dep
{addMkdirRule} = require '../helper/filesystem'
{addPhonyRule} = require '../helper/phony'

# Rule dep
component = require './component'

COMPONENT_BUILD_DIR = 'component-build'
COMPONENT_BUILD     = '$(NODE_BIN)/component-build --dev'
COMPONENT_INSTALL   = '$(NODE_BIN)/component-install --dev'

exports.title = 'component-build make targets'
exports.description = "build a tj main component"
exports.readme =
      name: 'component-build'
      path: path.join __dirname, 'component-build.md'

exports.addRules = (config, manifest, ruleBook) ->
    # make sure we are a component feature
    return if not manifest.client?

    buildPath = path.join config.featureBuildDirectory, config.featurePath # build/lib/foobar
    remoteComponentPath = config.remoteComponentPath

    _src = (script) -> path.join config.featurePath, script
    _dest = (script) -> path.join buildPath, script
    _project = (script) -> path.join config.projectRoot, script

    componentJsonTarget = component.getTargets(buildPath, 'component')

    # now we prepare component install
    addMkdirRule ruleBook, remoteComponentPath
    remoteComponentDir = _dest 'components'
    componentInstalledTarget = _dest('component-installed')
    if manifest.client?.dependencies?
        ruleBook.addRule
            targets: componentInstalledTarget
            dependencies: [ componentJsonTarget,'|', remoteComponentDir]
            actions: [
                "cd #{buildPath} && #{COMPONENT_INSTALL}"
                "touch #{componentInstalledTarget}"
            ]
        ruleBook.addRule
            targets: remoteComponentDir
            dependencies: [ '|', remoteComponentPath ]
            actions: [
                "test -d #{remoteComponentDir} || ln -s #{remoteComponentPath} #{remoteComponentDir}"
            ]
    else
        ruleBook.addRule
            targets: componentInstalledTarget
            dependencies: componentJsonTarget

    # component build rule
    componentBuildTargets = getTargets(buildPath, 'component-build')
    ruleBook.addRule
        targets: componentBuildTargets.target
        dependencies: _dest('component-installed')
        actions: [
            "cd #{buildPath} && #{COMPONENT_BUILD} " +
            " --name #{manifest.name} -v -o #{COMPONENT_BUILD_DIR}"
            "touch #{componentBuildTargets.target}"
        ]

    # phony targets for component build
    localTarget = _src COMPONENT_BUILD_DIR
    ruleBook.addRule
        targets: localTarget
        dependencies: componentBuildTargets.target
    addPhonyRule ruleBook, localTarget


exports.getTargets = getTargets = (buildPath, tag) ->
  switch tag
    when 'component-build'
      target = path.join buildPath, COMPONENT_BUILD_DIR, 'component-is-build'
      target: target
      targetDst: path.dirname target
    else
      throw new Error("unknown tag '#{tag}'")



