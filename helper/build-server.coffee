command = (cmd, target = '$@', src = '$<') ->
    return "$(call build_cmd,#{cmd},#{target},#{src})"

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
