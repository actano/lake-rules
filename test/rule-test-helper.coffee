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
    rule.addRules _extendCopy(CONFIG, config), manifest, (rule) ->
        expect(arguments).to.have.length 1
        rule = Rule.upgrade rule unless rule instanceof Rule


        # TODO respect multi-target rules
        target = rule._targets.join ' '
        old = targets[target]
        if old?
            old.prerequisite rule._prerequisites
            old.orderOnly rule._orderOnly
            if old._actions.length > 0 and rule._actions.length
                throw new Error("Rule #{target} already has actions")
            old.action rule._actions
            old.silent() if rule._silent
        else
            targets[target] = rule

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

Assertion.addMethod 'useBuildServer', (action) ->
    @to.containAction command action

Assertion.addMethod 'containAction', (pattern) ->
    containsAction = false
    for action in @_obj._actions
        if ((pattern instanceof RegExp) and (pattern.test action)) or pattern is action
            containsAction = true
            break

    new Assertion(containsAction).to.equal true, "#{@_obj._actions} should contain #{pattern}"

Assertion.addMethod 'copy', (src) ->
    new Assertion(@_obj).to.depend src
    pattern = new RegExp "^cp.+(\\$\\^|\\$<|#{src}).+(\\$@|#{@_obj.targets})$"
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
    require('../helper/phony').clearPhonyCache()
    require('../helper/filesystem').clearDirectoryCache()

