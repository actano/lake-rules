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

        if targets[target]?.actions?.length > 0 and rule.actions?.length > 0
            throw new Error("Rule #{target} already has actions")

        targets[target] ?= {}
        targets[target].actions = rule.actions ? []
        targets[target].targets = rule.targets
        targets[target].dependencies ?= []
        targets[target].dependencies = targets[target].dependencies.concat(rule.dependencies)
    #console.log(targets)

    return targets

module.exports.checkTargets = (targets, options) ->
    if options?.expected?
        for target, checkers of options.expected
            expect(targets).to.have.property target

            checkers = [checkers] unless checker instanceof Array

            for checker in checkers
                checker.check targets[target]

    if options?.unexpected?
        if options.unexpected instanceof Array
            unexpected = options.unexpected
        else
            unexpected = [options.unexpected]

        for target in unexpected
            expect(targets).to.not.have.property target

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
    new Assertion(@_obj.actions).to.be.a 'string'
    new Assertion(@_obj.actions).to.match pattern

Assertion.addMethod 'makeActions', (patterns) ->
    new Assertion(@_obj.actions).to.be.an 'array'
    new Assertion(@_obj.actions).to.have.length patterns.length
    for pattern, i in patterns
        new Assertion(@_obj.actions[i]).to.match pattern
