path = require 'path'
fs = require './filesystem'
JADE = "$(COFFEE) #{path.join __dirname, 'jade-require.coffee'}"

makeDependencies = (src, dir, extraDependencies) ->
    result = [src]
    result = result.concat extraDependencies if extraDependencies?
    result.push '|' if result.indexOf('|') is -1
    result.push dir
    return result

module.exports.addJadeHtmlRule = (addRule, src, dst, object, extraDependencies, extraArguments) ->
    extraArguments ?= ""
    dstDir = fs.addMkdirRuleOfFile addRule, dst
    addRule
        targets: dst
        dependencies: makeDependencies src, dstDir, extraDependencies
        actions: "#{JADE} $< --deny-parent --pretty --out $@ #{extraArguments} --obj '#{JSON.stringify object}'"
    return dst

module.exports.addJadeJavascriptRule = (addRule, src, dst, extraDependencies, extraArguments) ->
    extraArguments ?= ""
    targetDir = fs.addMkdirRuleOfFile addRule, dst
    addRule
        targets: dst
        dependencies: makeDependencies src, targetDir, extraDependencies
        actions: "#{JADE} --deny-parent --client --out $@ #{extraArguments} $<"
    return dst
