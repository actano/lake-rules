assert = require 'assert'
Promise = require 'bluebird'

_flatten = (result, array) ->
    for x in array
        if Array.isArray x
            _flatten result, x
        else if x instanceof Rule
            _flatten result, x._targets
        else
            result.push x

flatten = (result, array) ->
    return if array is undefined
    return unless array?
    _flatten result, [ array ]

class Rule

    constructor: (target, info) ->
        @_canWrite = true
        @_silent = false
        @_phony = false
        @_targets = []
        @_prerequisites = []
        @_prerequisiteOf = []
        @_orderOnly = []
        @_info = []
        @_actions = []
        @target target if target?
        if info?
            @info "$@ (#{info})"

    toString: ->
        "#{@_targets.join ' '}:"

    condition: (cond) ->
        @_if = "if#{cond}"
        return this

    target: (target) ->
        assert @_canWrite
        flatten @_targets, target
        return this

    prerequisite: (prerequisite) ->
        assert @_canWrite
        flatten @_prerequisites, prerequisite
        return this

    prerequisiteOf: (targets) ->
        assert @_canWrite
        flatten @_prerequisiteOf, targets
        return this

    orderOnly: (prerequisite) ->
        assert @_canWrite
        flatten @_orderOnly, prerequisite
        return this

    info: (val) ->
        assert @_canWrite
        flatten @_info, "$(info #{val})"
        @silent()

    action: (action) ->
        assert @_canWrite
        flatten @_actions, action
        return this

    silent: ->
        assert @_canWrite
        @_silent = true
        return this

    phony: ->
        assert @_canWrite
        @_phony = true
        return this

    # Rule.writable is set by create_makefile.coffee
    write: (writable = Rule.writable) ->
        throw new Error "No targets given" unless @_targets.length

        assert @_canWrite
        @_canWrite = false

        # Start conditional block
        writable.write "#{@_if}\n" if @_if?

        # Targets/Prerequisites/orderOnly
        writable.write "#{@_targets.join ' '}:"
        for d in @_prerequisites
            writable.write ' '
            writable.write d
        if @_orderOnly.length
            writable.write ' |'
            for d in @_orderOnly
                writable.write ' '
                writable.write d

        writable.write '\n'

        # Actions
        actions = @_actions
        if actions.length > 0
            unless @_silent
                actions = ['$(info )', '$(info \u001b[3;4m$@\u001b[24m)'].concat actions
            else if @_info.length
                actions = @_info.concat actions
            writable.write '\t'
            writable.write actions.join '\n\t'
            writable.write '\n'

        # Phony declaration
        if @_phony
            writable.write '.PHONY: '
            writable.write @_targets.join ' '
            writable.write '\n'

        # reverse prerequisites
        for r in @_prerequisiteOf
            new Rule(r).prerequisite(@_targets).write writable

        # End conditional block
        writable.write "endif\n" if @_if?
        writable.write '\n'
        return this

for cond in ['def', 'ndef']
    do (cond) ->
        Rule::["if#{cond}"] = (s) -> @condition "#{cond} #{s}"

Rule.startInclude = Promise.coroutine (mkFilePath) ->
    path = require 'path'
    fs = require 'fs'
    mkdirp = Promise.promisify require 'mkdirp'
    lakeConfig = require '../lake/config'

    old = Rule.writable

    mkFilePath = path.join lakeConfig.config.lakeOutput, "#{mkFilePath}.mk"
    yield mkdirp path.dirname mkFilePath
    writable = Rule.writable = fs.createWriteStream mkFilePath
    end = Promise.promisify writable.end, writable
    ->
        Rule.writable = old
        old.write "include #{mkFilePath}\n"
        end()

module.exports = Rule
