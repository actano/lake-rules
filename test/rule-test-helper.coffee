{expect, Assertion} = require 'chai'
sinon = require 'sinon'
_ = require 'underscore'

# standard values for lake, manifest and feature path
LAKE =
    lakePath: '.lake'
    featureBuildDirectory: 'build/local_components'
    remoteComponentPath: 'build/remote_components'
    runtimePath: 'build/runtime'

FEATURE_PATH = 'lib/feature'

MANIFEST =
    projectRoot: '/project/root'
    featurePath: FEATURE_PATH

module.exports.globals =
    lake: LAKE
    featurePath: FEATURE_PATH
    manifest: MANIFEST

_extendMap = (map, key, value) ->
    if key instanceof Array
        for k in key
            _extendMap map, k, value
    else
        map[key] = [] unless map[key]?
        map[key].push value

_extendCopy = (base, extension) ->
    _.chain(base).clone().extend(extension).value()

module.exports.executeRule = (rule, lake, manifest) ->
    spy = sinon.spy()

    rb =
        addRule: spy

    rule.addRules _extendCopy(LAKE, lake), FEATURE_PATH, _extendCopy(MANIFEST, manifest), rb

    targets = {}
    ruleIds = {}

    for i in [0..(spy.callCount - 1)]
        expect(spy.args[i]).to.have.length 3

        ruleId = spy.args[i][0]
        ruleTags = spy.args[i][1]
        makeRule = spy.args[i][2]

        expect(ruleTags).to.be.empty
        expect(ruleIds[ruleId]).to.not.exist
        expect(makeRule).to.be.a 'function'

        ruleIds[ruleId] = {}
        rule = makeRule()

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

Assertion.addMethod 'copy', (src) ->
    pattern = new RegExp "^cp.+(\\$\\^|\\$<|" + src + ").+(\\$@|" + @_obj.targets + ")$"
    new Assertion(@_obj.dependencies).to.contain src
    new Assertion(@_obj.actions).to.match pattern

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

