path = require 'path'

fs = require './filesystem'

COFFEEC = '$(NODE_BIN)/coffee'

module.exports.coffeeAction = coffeeAction =
  "#{COFFEEC} --compile --output $(@D) $<"

coffeeActionWithMaps =
  "#{COFFEEC} --compile --map --output $(@D) $<"

module.exports.addCoffeeRule = (addRule, src, dst) ->
  _addCoffeeRule(addRule, src, dst, coffeeAction)

module.exports.addCoffeeRuleWithMaps = (addRule, src, dst) ->
  _addCoffeeRule(addRule, src, dst, coffeeActionWithMaps)

_addCoffeeRule = (addRule, src, dst, _coffeeAction) ->
    dst = fs.replaceExtension(dst, '.js')
    switch path.extname src
        when '.coffee'
            dstPath = fs.addMkdirRuleOfFile addRule, dst
            addRule
                targets: dst
                dependencies: [src, '|', dstPath]
                actions: _coffeeAction
        when '.js'
            fs.addCopyRule addRule, src, dst
    return dst
