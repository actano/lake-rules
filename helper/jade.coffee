Rule = require './rule'

jadeRule = (src, dst, prerequisites, buildServerArgs...) ->
    new Rule(dst)
        .prerequisite src
        .prerequisite prerequisites
        .info '$@ (jade)'
        .buildServer buildServerArgs...
        .write()

module.exports.addJadeHtmlRule = (src, dst, object, prerequisites, jadeDeps) ->
    throw new Error('jadeDeps must be an array') unless Array.isArray jadeDeps

    jadeRule src, dst, prerequisites, 'jade.html', null, null, JSON.stringify(object).replace(/\n/g, ' '), jadeDeps...
    return dst

module.exports.addJadeJavascriptRule = (src, dst, prerequisites, jadeDeps) ->
    throw new Error('jadeDeps must be an array') unless Array.isArray jadeDeps

    jadeRule src, dst, prerequisites, 'jade.js', null, null, jadeDeps...
    return dst
