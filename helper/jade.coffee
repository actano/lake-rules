path = require 'path'
fs = require './filesystem'
JADE = "$(NODE_BIN)/coffee $(TOOLS)/jade-require.coffee"

module.exports.getJadeDependencies = (manifest) ->
    deps = manifest.client?.templates?.dependencies
    return [] unless deps
    [].concat(deps).filter (dep) ->
        dep?

module.exports.addJadeHtmlRule = (ruleBook, src, dst, object, extraDependencies, extraArguments) ->
    extraDependencies ?= []
    extraArguments ?= ""
    dstDir = fs.addMkdirRuleOfFile ruleBook, dst
    ruleBook.addRule dst, [], ->
        targets: dst
        dependencies: [src].concat(extraDependencies).concat(['|', dstDir])
        actions: "#{JADE} $< --pretty --out $@ #{extraArguments} --obj '#{JSON.stringify object}'"
    return dst

module.exports.addJadeJavascriptRule = (ruleBook, src, dst, extraDependencies, extraArguments) ->
    extraDependencies ?= []
    extraArguments ?= ""
    targetDir = fs.addMkdirRuleOfFile ruleBook, dst
    ruleBook.addRule  dst, [], ->
        targets: dst
        dependencies: [src].concat(extraDependencies).concat(['|', targetDir ])
        actions: "#{JADE} --client --out $@ #{extraArguments} $<"
    return dst
