path = require 'path'
fs = require './filesystem'
module.exports.addJadeRule = (ruleBook, src, dst, object, extraDependencies) ->
    extraDependencies ?= []
    dstDir = fs.addMkdirRule ruleBook, path.dirname dst
    ruleBook.addRule dst, '[]', ->
        targets: dst
        dependencies: extraDependencies.concat [src, '|', dstDir]
        actions: "$(NODE_BIN)/coffee $(TOOLS)/jade-require.coffee $^ --pretty --out $(@D) --obj '#{JSON.stringify object}'"
    return dst
