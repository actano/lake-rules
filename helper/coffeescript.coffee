path = require 'path'

fs = require './filesystem'

COFFEEC = '$(NODE_BIN)/coffee'

module.exports.coffeeAction = coffeeAction =
  "#{COFFEEC} --compile --output $(@D) $<"

coffeeActionWithMaps =
  "#{COFFEEC} --compile --map --output $(@D) $<"

module.exports.addCoffeeRule = (ruleBook, src, dst) ->
  _addCoffeeRule(ruleBook, src, dst, coffeeAction)

module.exports.addCoffeeRuleWithMaps = (ruleBook, src, dst) ->
  _addCoffeeRule(ruleBook, src, dst, coffeeActionWithMaps)

_addCoffeeRule = (ruleBook, src, dst, _coffeeAction) ->
    dst = fs.replaceExtension(dst, '.js')
    switch path.extname src
        when '.coffee'
            dstPath = fs.addMkdirRuleOfFile ruleBook, dst
            ruleBook.addRule dst, [], ->
                targets: dst
                dependencies: [src, '|', dstPath]
                actions: _coffeeAction
        when '.js'
            fs.addCopyRule ruleBook, src, dst
    return dst
