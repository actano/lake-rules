phonyCache = {}

module.exports.clearPhonyCache = ->
    for key of phonyCache
        delete phonyCache[key]

module.exports.addPhonyRule = (addRule, target) ->
    name = "PHONY #{target}"
    if not phonyCache[name]
        phonyCache[name] = true
        addRule
            targets: '.PHONY'
            dependencies: target
