_flatten = (result, array) ->
    for x in array
        if Array.isArray x
            _flatten result, x
        else
            result.push x

flatten = (result, array) ->
    return if array is undefined
    return unless array?

    _flatten result, [ array ]

class Rule

    constructor: (target) ->
        @_silent = false
        @_targets = []
        @_prerequisites = []
        @_orderOnly = []
        @_info = []
        @_actions = []
        @target target if target?

    target: (target) ->
        flatten @_targets, target
        return this

    prerequisite: (prerequisite) ->
        flatten @_prerequisites, prerequisite
        return this

    orderOnly: (prerequisite) ->
        flatten @_orderOnly, prerequisite
        return this

    info: (val) ->
        flatten @_info, "$(info #{val})"
        @silent()

    action: (action) ->
        flatten @_actions, action
        return this

    silent: ->
        @_silent = true
        return this

    write: (writable) ->
        throw new Error "No targets given" unless @_targets.length

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

        actions = @_actions
        if actions.length > 0
            unless @_silent
                actions = ['$(info )', '$(info \u001b[3;4m$@\u001b[24m)'].concat actions
            else if @_info.length
                actions = @_info.concat actions
            writable.write '\t'
            writable.write actions.join '\n\t'
            writable.write '\n'

        writable.write '\n'

Rule.upgrade = (rule) ->
    result = new Rule(rule.targets).action rule.actions

    if rule.dependencies?
        kind = 'prerequisite'
        deps = []
        flatten deps, [rule.dependencies]
        for k in deps
            if k is '|'
                kind = 'orderOnly'
                continue
            result[kind] k

    result.silent if rule.silent
    result

module.exports = Rule
