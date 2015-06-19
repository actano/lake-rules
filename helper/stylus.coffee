Rule = require './rule'

module.exports.addStylusRule = (src, dst, prerequisites, stylusDeps) ->
    new Rule(dst)
        .prerequisite src
        .prerequisite prerequisites
        .buildServer 'stylus', null, null, stylusDeps...
        .write()
    return dst

