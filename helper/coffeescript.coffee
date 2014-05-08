path = require 'path'

fs = require './filesystem'

COFFEEC = '$(NODE_BIN)/coffee'

module.exports.coffeeAction = coffeeAction = "#{COFFEEC} --compile --stdio < $< > $@"

module.exports.addCoffeeRule = (ruleBook, src, dst) ->
    dst = fs.replaceExtension(dst, '.js')
    switch path.extname src
        when '.coffee'
            dstPath = fs.addMkdirRuleOfFile ruleBook, dst
            ruleBook.addRule dst, [], ->
                targets: dst
                dependencies: [src, '|', dstPath]
                actions: coffeeAction
        when '.js'
            fs.addCopyRule ruleBook, src, dst
    return dst
