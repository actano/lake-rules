Rule = require './rule'

jadeRule = (addRule, src, dst, prerequisites, buildServerArgs...) ->
    new Rule(dst)
        .prerequisite src
        .prerequisite prerequisites
        .info '$@ (jade)'
        .buildServer buildServerArgs...

module.exports.addJadeHtmlRule = (addRule, src, dst, object, prerequisites, jadeDeps) ->
    throw new Error('jadeDeps must be an array') unless Array.isArray jadeDeps

    addRule jadeRule addRule, src, dst, prerequisites, 'jade.html', null, null, JSON.stringify(object).replace(/\n/g, ' '), jadeDeps...
    return dst

module.exports.addJadeJavascriptRule = (addRule, src, dst, prerequisites, jadeDeps) ->
    throw new Error('jadeDeps must be an array') unless Array.isArray jadeDeps

    addRule jadeRule addRule, src, dst, prerequisites, 'jade.js', null, null, jadeDeps...
    return dst
