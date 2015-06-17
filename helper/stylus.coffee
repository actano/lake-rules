Rule = require './rule'

jadeRule = (addRule, src, dst, prerequisites, buildServerArgs...) ->
    new Rule(dst)
        .info dst
        .prerequisite src
        .prerequisite prerequisites
        .buildServer buildServerArgs...

module.exports.addStylusRule = (addRule, src, dst, prerequisites, stylusDeps) ->
    rule = new Rule(dst)
        .prerequisite src
        .prerequisite prerequisites
        .buildServer 'stylus', null, null, stylusDeps...
    addRule rule
    return dst

