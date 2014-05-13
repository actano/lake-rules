phonyCache = {}

module.exports.clearPhonyCache = ->
    for key of phonyCache
        delete phonyCache[key]

module.exports.addPhonyRule = (ruleBook, target) ->
    name = "PHONY #{target}"
    if not phonyCache[name]
        phonyCache[name] = true
        ruleBook.addRule name, [], ->
            targets: '.PHONY'
            dependencies: target
