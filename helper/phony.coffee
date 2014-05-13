module.exports.addPhonyRule = (ruleBook, target) ->
    name = "PHONY #{target}"
    ruleBook.phonyCache ?= {}

    if not ruleBook.phonyCache[name]?
        ruleBook.phonyCache[name] = {}
        ruleBook.addRule name, [], ->
            targets: '.PHONY'
            dependencies: target
