{expect, Assertion, config} = require 'chai'
sinon = require 'sinon'
_ = require 'underscore'

config.truncateThreshold = 1000

# standard values for featurePath and config
FEATURE_PATH = 'lib/feature'
CONFIG =
    lakePath: '.lake'
    featureBuildDirectory: 'build/local_components'
    remoteComponentPath: 'build/remote_components'
    runtimePath: 'build/runtime'
    projectRoot: '/project/root'
    featurePath: FEATURE_PATH

module.exports.globals = CONFIG

_extendCopy = (base, extension) ->
    _.chain(base).clone().extend(extension).value()

module.exports.executeRule = (rule, config, manifest) ->
    spy = sinon.spy()

    rb =
        addRule: spy

    rule.addRules _extendCopy(CONFIG, config), manifest, rb

    targets = {}

    if spy.callCount <= 0
        return targets

    for i in [0..(spy.callCount - 1)]
        expect(spy.args[i]).to.have.length 1

        rule = spy.args[i][0]

        target = rule.targets

        # Normalize actions to be an array
        if rule.actions? and not (rule.actions instanceof Array)
            rule.actions = [rule.actions]

        if targets[target]?.actions?.length > 0 and rule.actions?.length > 0
            throw new Error("Rule #{target} already has actions")

        targets[target] ?= {}
        targets[target].actions = rule.actions ? []
        targets[target].targets = rule.targets
        targets[target].dependencies ?= []
        targets[target].dependencies = targets[target].dependencies.concat(rule.dependencies)

    return targets

Assertion.addMethod 'depend', (deps) ->
    new Assertion(@_obj).to.exist
    deps = [deps] unless deps instanceof Array

    for dep in deps
        new Assertion(@_obj.dependencies).to.contain dep

Assertion.addMethod 'containAction', (pattern) ->
    containsAction = false
    for action in @_obj.actions
        if ((pattern instanceof RegExp) and (pattern.test action)) or pattern is action
            containsAction = true
            break

    new Assertion(containsAction).to.equal true, "#{@_obj.actions} should contain #{pattern}"

Assertion.addMethod 'copy', (src) ->
    pattern = new RegExp "^cp.+(\\$\\^|\\$<|#{src}).+(\\$@|#{@_obj.targets})$"
    new Assertion(@_obj.dependencies).to.contain src
    new Assertion(@_obj).to.containAction pattern

Assertion.addMethod 'phonyTarget', (target) ->
    new Assertion(@_obj['.PHONY']).to.exist
    new Assertion(@_obj['.PHONY'].dependencies).to.contain target

Assertion.addMethod 'singleMakeAction', (pattern) ->
    new Assertion(@_obj.actions).to.be.have.length 1
    if pattern instanceof RegExp
        new Assertion(@_obj.actions[0]).to.match pattern
    else
        new Assertion(@_obj.actions[0]).to.equal pattern

Assertion.addMethod 'makeActions', (patterns) ->
    new Assertion(@_obj.actions).to.have.length patterns.length
    for pattern, i in patterns
        if pattern instanceof RegExp
            new Assertion(@_obj.actions[i]).to.match pattern
        else
            new Assertion(@_obj.actions[i]).to.equal pattern

beforeEach ->
    require('../helper/phony').clearPhonyCache()
    require('../helper/filesystem').clearDirectoryCache()

