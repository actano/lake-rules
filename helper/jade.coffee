path = require 'path'
fs = require './filesystem'

module.exports.addJadeHtmlRule = (ruleBook, src, dst, object, extraDependencies) ->
    extraDependencies ?= []
    dstDir = fs.addMkdirRuleOfFile ruleBook, dst
    ruleBook.addRule dst, '[]', ->
        targets: dst
        dependencies: [src].concat(extraDependencies).concat(['|', dstDir])
        actions: "$(NODE_BIN)/coffee $(TOOLS)/jade-require.coffee $< --pretty --out $@ --obj '#{JSON.stringify object}'"
    return dst

module.exports.addJadeJavascriptRule = (ruleBook, src, dst) ->
    targetDir = fs.addMkdirRuleOfFile ruleBook, dst
    ruleBook.addRule  dst, [], ->
        targets: dst
        dependencies: [ src, '|', targetDir ]
        actions: "$(NODE_BIN)/coffee $(TOOLS)/jade-require.coffee --client --out $@ $<"
    return dst
