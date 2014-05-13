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


class RuleChecker
    constructor: (@name) ->

    check: (target) ->
        @checkRule target

        ###
        if rules.length is 1
            @checkRule rules[0]
        else
            # at least one rule has to match
            errorCount = 0

            for rule in rules
                try
                    @checkRule rule
                catch err
                    errorCount++

            if errorCount is rules.length
                console.log 'no rule matches %s', @name
            expect(errorCount).to.be.below rules.length
        ###

    checkRule: (rule) ->
        expect(false).to.be.true

class RuleDependencyChecker extends RuleChecker
    constructor: (@deps) ->
        @deps = [@deps] unless @deps instanceof Array
        super "dependencies #{@deps}"

    checkRule: (rule) ->
        for dep in @deps
            expect(rule.dependencies).to.contain dep

class CopyRuleChecker extends RuleChecker
    constructor: (@src) ->
        @src = @src.join ' ' if @src instanceof Array
        super "copying '#{@src}' to expected destination"

    checkRule: (rule) ->
        if rule.targets instanceof Array
            targets = rule.targets.join '|'
        else
            targets = rule.targets

        pattern = new RegExp "^cp.+(\\$\\^|\\$<|" + @src + ").+(\\$@|" + targets + ")$"
        expect(rule.dependencies).to.contain @src
        expect(rule.actions).to.match pattern

class AlwaysTrueChecker extends RuleChecker
    constructor: ->
        super 'truth'

    checkRule: ->

module.exports.RuleChecker = RuleChecker
module.exports.RuleDependencyChecker = RuleDependencyChecker
module.exports.CopyRuleChecker = CopyRuleChecker
module.exports.AlwaysTrueChecker = AlwaysTrueChecker

Assertion.addMethod 'depend', (dep) ->
    new Assertion(@_obj).to.exist
    new Assertion(@_obj.dependencies).to.contain dep

Assertion.addMethod 'copy', (src) ->
    pattern = new RegExp "^cp.+(\\$\\^|\\$<|" + src + ").+(\\$@|" + @_obj.targets + ")$"
    new Assertion(@_obj.dependencies).to.contain src
    new Assertion(@_obj.actions).to.match pattern

Assertion.addMethod 'phony', (targets) ->
    new Assertion(targets['.PHONY']).to.exist
    new Assertion(targets['.PHONY'].dependencies).to.contain @_obj.targets
