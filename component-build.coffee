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

exports.addRules = (config, manifest) ->
    # make sure we are a component feature
    return if not manifest.client?

    buildPath = path.join config.featureBuildDirectory, config.featurePath # build/lib/foobar
    remoteComponentPath = config.remoteComponentPath

    _src = (script) -> path.join config.featurePath, script
    _dest = (script) -> path.join buildPath, script

    componentJsonTarget = component.getTargets(buildPath, 'component')

    # now we prepare component install
    addMkdirRule remoteComponentPath
    remoteComponentDir = _dest 'components'
    componentInstalledTarget = _dest('component-installed')
    componentInstallRule = new Rule componentInstalledTarget
        .prerequisite componentJsonTarget

    if manifest.client?.dependencies?
        componentInstallRule
            .buildServer 'component-install', null, '$(REMOTE_COMPONENTS)'
            .action '@touch $@'

        new Rule remoteComponentDir
            .orderOnly remoteComponentPath
            .action "@test -d #{remoteComponentDir} || ln -s #{remoteComponentPath} #{remoteComponentDir}"
            .silent()
            .write()

    componentInstallRule.write()

    # component build rule
    componentBuildTargets = getTargets(buildPath, 'component-build')
    noRequire = manifest.client.require is false
    new Rule componentBuildTargets.target
        .prerequisite _dest('component-installed')
        .prerequisite componentJsonTarget
        .buildServer 'component-build', null, null, '$(REMOTE_COMPONENTS)', manifest.name, if noRequire then true else null
        .action '@touch $@'
        .write()

    # phony targets for component build
    localTarget = _src COMPONENT_BUILD_DIR
    new Rule localTarget
        .prerequisite componentBuildTargets.target
        .phony()
        .write()


exports.getTargets = getTargets = (buildPath, tag) ->
  switch tag
    when 'component-build'
      target = path.join buildPath, COMPONENT_BUILD_DIR, 'component-is-build'
      target: target
      targetDst: path.dirname target
    else
      throw new Error("unknown tag '#{tag}'")



