command = (cmd, args...) ->
    args.push '$@' if args.length < 1
    args[0] = '$@' unless args[0]?
    args.push '$<' if args.length < 2
    args[1] = '$<' unless args[1]?
    return "$(call build_cmd,#{cmd},#{args.join '\\\\n'})"

prereq = (prerequisites = []) ->
    need = '$(BUILD_SERVER)'
    orderOnly = false
    for k in prerequisites
        return prerequisites if k is need
        orderOnly = true if k is '|'
    prerequisites.push '|' unless orderOnly
    prerequisites.push need
    prerequisites

module.exports = {command, prereq}
