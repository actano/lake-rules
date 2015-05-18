path = require 'path'

Rule = require './rule'
fs = require './filesystem'

addCoffeeRule = (addRule, src, dst) ->
    dst = fs.replaceExtension(dst, '.js')
    switch path.extname src
        when '.coffee'
            rule = new Rule dst
                .prerequisite src
                .info '$@'
                .buildServer 'coffee'
            addRule rule

        when '.js'
            fs.addCopyRule addRule, src, dst
    return dst

module.exports = {addCoffeeRule}
