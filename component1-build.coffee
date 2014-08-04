# Std library
path = require 'path'

# Local dep
{addMkdirRule} = require './helper/filesystem'
{addPhonyRule} = require './helper/phony'

# Rule dep
component = require './component'

COMPONENT_BUILD_DIR = 'component1-build'
COMPONENT_BUILD     = '$(TOOLS)/component1/component-wrapper.coffee'
COMPONENT1_NODE_MODULES = '$(TOOLS)/component1/node_modules'

exports.title = 'component1-build make targets'
exports.description = "build a tj main component (with component v1)"
exports.readme =
      name: 'component1-build'
      path: path.join __dirname, 'component1-build.md'

exports.addRules = (config, manifest, ruleBook) ->
    # make sure we are a component v1 feature
    return unless manifest.client?

    buildPath = path.join config.featureBuildDirectory, config.featurePath # build/lib/foobar
    remoteComponentPath = config.remoteComponentV1Path

    _src = (script) -> path.join config.featurePath, script
    _dest = (script) -> path.join buildPath, script
    _project = (script) -> path.join config.projectRoot, script

    componentJsonTarget = component.getTargets(buildPath, 'component')

    # now we prepare component install
    addMkdirRule ruleBook, remoteComponentPath

    # component build rule
    componentBuildTargets = getTargets(buildPath, 'component1-build')
    ruleBook.addRule
        targets: componentBuildTargets.target
        dependencies: [componentJsonTarget, '|', remoteComponentPath, COMPONENT1_NODE_MODULES]
        actions: [
            # CWD for component-wrapper MUST be one level above the lib directory.
            # If not, require './lib/feature' won't work.
            "cd #{config.featureBuildDirectory} && #{COMPONENT_BUILD} " +
            " --name #{manifest.name} --dev --out #{COMPONENT_BUILD_DIR} --remote_components #{remoteComponentPath}" +
            " --path lib"
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
    when 'component1-build'
      target = path.join buildPath, COMPONENT_BUILD_DIR, 'component-is-build'
      target: target
      targetDst: path.dirname target
    else
      throw new Error("unknown tag '#{tag}'")



