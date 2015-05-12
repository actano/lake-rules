{command, prereq} = require './build-server'

path = require 'path'

fs = require './filesystem'

coffeeAction = command 'coffee'

addCoffeeRule = (addRule, src, dst) ->
    dst = fs.replaceExtension(dst, '.js')
    switch path.extname src
        when '.coffee'
            addRule
                targets: dst
                dependencies: prereq [src]
                actions: ['$(info $@)', coffeeAction]
                silent: true
        when '.js'
            fs.addCopyRule addRule, src, dst
    return dst

module.exports = {coffeeAction, addCoffeeRule}
