path = require 'path'
fs = require './filesystem'
JADE = "$(NODE_BIN)/coffee $(TOOLS)/jade-require.coffee"

makeDependencies = (src, dir, extraDependencies) ->
    result = [src]
    result = result.concat extraDependencies if extraDependencies?
    result.push '|' if result.indexOf('|') is -1
    result.push dir
    return result

module.exports.addJadeHtmlRule = (ruleBook, src, dst, object, extraDependencies, extraArguments) ->
    extraArguments ?= ""
    dstDir = fs.addMkdirRuleOfFile ruleBook, dst
    ruleBook.addRule
        targets: dst
        dependencies: makeDependencies src, dstDir, extraDependencies
        actions: "#{JADE} $< --deny-parent --pretty --out $@ #{extraArguments} --obj '#{JSON.stringify object}'"
    return dst

module.exports.addJadeJavascriptRule = (ruleBook, src, dst, extraDependencies, extraArguments) ->
    extraArguments ?= ""
    targetDir = fs.addMkdirRuleOfFile ruleBook, dst
    ruleBook.addRule
        targets: dst
        dependencies: makeDependencies src, targetDir, extraDependencies
        actions: "#{JADE} --deny-parent --client --out $@ #{extraArguments} $<"
    return dst
