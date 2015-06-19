path = require 'path'

Rule = require './rule'
fs = require './filesystem'

addCoffeeRule = (src, dst) ->
    dst = fs.replaceExtension(dst, '.js')
    switch path.extname src
        when '.coffee'
            new Rule dst
                .prerequisite src
                .info '$@'
                .buildServer 'coffee'
                .write()

        when '.js'
            fs.addCopyRule src, dst
    return dst

module.exports = {addCoffeeRule}
