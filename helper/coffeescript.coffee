path = require 'path'

fs = require './filesystem'

coffeeAction = "$(call build_cmd,coffee,$@,$<)"

addCoffeeRule = (addRule, src, dst) ->
    dst = fs.replaceExtension(dst, '.js')
    switch path.extname src
        when '.coffee'
            dstPath = fs.addMkdirRuleOfFile addRule, dst
            addRule
                targets: dst
                dependencies: [src, '|', dstPath, "$(BUILD_SERVER)"]
                actions: ['$(info $@)', coffeeAction]
                silent: true
        when '.js'
            fs.addCopyRule addRule, src, dst
    return dst

module.exports = {coffeeAction, addCoffeeRule}
