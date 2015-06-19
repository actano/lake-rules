{expect, Assertion, config} = require 'chai'
sinon = require 'sinon'
_ = require 'underscore'
Rule = require '../helper/rule'
{command} = require '../helper/build-server'

config.truncateThreshold = 1000

# standard values for featurePath and config
FEATURE_PATH = 'lib/feature'
CONFIG =
    featureBuildDirectory: 'build/local_components'
    remoteComponentPath: 'build/remote_components'
    runtimePath: 'build/runtime'
    projectRoot: '/project/root'
    featurePath: FEATURE_PATH

module.exports.globals = CONFIG

_extendCopy = (base, extension) ->
    _.chain(base).clone().extend(extension).value()

module.exports.executeRule = (rule, config, manifest) ->
    targets = {}
    oldWrite = Rule::write
    Rule::write = ->
        # TODO respect multi-target rules
        target = @_targets.join ' '
        old = targets[target]
        if old?
            old.prerequisite @_prerequisites
            old.orderOnly @_orderOnly
            if old._actions.length > 0 and @_actions.length
                throw new Error("Rule #{target} already has actions")
            old.action @_actions
            old.silent() if @_silent
        else
            targets[target] = @

        if @_phony
            new Rule '.PHONY'
                .prerequisite @_targets
                .write()

        for r in @_prerequisiteOf
            new Rule(r).prerequisite(@_targets).write()

    rule.addRules _extendCopy(CONFIG, config), manifest

    Rule::write = oldWrite

    return targets

Assertion.addMethod 'depend', (deps) ->
    new Assertion(@_obj).to.exist
    deps = [deps] unless deps instanceof Array

    dependencies = new Assertion(@_obj._prerequisites.concat @_obj._orderOnly)
    for dep in deps
        if dep instanceof RegExp
            dependencies.to.match dep
        else
            dependencies.to.contain dep

Assertion.addMethod 'useBuildServer', (action...) ->
    @to.containAction command action...

Assertion.addMethod 'containAction', (pattern) ->
    containsAction = false
    for action in @_obj._actions
        if ((pattern instanceof RegExp) and (pattern.test action)) or pattern is action
            containsAction = true
            break

    new Assertion(containsAction).to.equal true, "#{@_obj._actions} should contain #{pattern}"

Assertion.addMethod 'copy', (src) ->
    new Assertion(@_obj).to.depend src
    pattern = new RegExp "^(@)?cp.+(\\$\\^|\\$<|#{src}).+(\\$@|#{@_obj._targets})$"
    new Assertion(@_obj).to.containAction pattern

Assertion.addMethod 'phonyTarget', (target) ->
    new Assertion(@_obj['.PHONY']).to.exist
    new Assertion(@_obj['.PHONY']._prerequisites).to.contain target

Assertion.addMethod 'singleMakeAction', (pattern) ->
    new Assertion(@_obj._actions).to.be.have.length 1
    if pattern instanceof RegExp
        new Assertion(@_obj._actions[0]).to.match pattern
    else
        new Assertion(@_obj._actions[0]).to.equal pattern

Assertion.addMethod 'makeActions', (patterns) ->
    new Assertion(@_obj._actions).to.have.length patterns.length
    for pattern, i in patterns
        if pattern instanceof RegExp
            new Assertion(@_obj._actions[i]).to.match pattern
        else
            new Assertion(@_obj._actions[i]).to.equal pattern

beforeEach ->
    require('../helper/filesystem').clearDirectoryCache()

