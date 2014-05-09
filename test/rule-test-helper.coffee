{expect} = require 'chai'
sinon = require 'sinon'
_ = require 'underscore'

# standard values for lake, manifest and feature path
LAKE = {}

MANIFEST =
    projectRoot: '/project/root'

FEATURE_PATH = 'lib/feature'

_extendMap = (map, key, value) ->
    if key instanceof Array
        for k in key
            _extendMap map, k, value
    else
        map[key] = [] unless map[key]?
        map[key].push value

_extendCopy = (base, extension) ->
    _.chain(base).clone().extend(extension).value()

_executeRule = (rule, lake, manifest) ->
    spy = sinon.spy()

    rb =
        addRule: spy

    rule.addRules _extendCopy(LAKE, lake), FEATURE_PATH, _extendCopy(MANIFEST, manifest), rb

    targets = {}

    for i in [0..(spy.callCount - 1)]
        expect(spy.args[i]).to.have.length 3
        expect(spy.args[i][2]).to.be.a 'function'

        makeRule = spy.args[i][2]()

        _extendMap targets, makeRule.targets, makeRule

    return targets

module.exports.checkRule = (rule, lake, manifest, options) ->
    targets = _executeRule rule, lake, manifest

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

    check: (rules) ->
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