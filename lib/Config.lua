local configuration = {
    -- Logs failed predicates on loot pools, useful for visualization
    logFailedPredicates = false,
}

local Config = {}

function Config.get(name)
    return configuration[name]
end

function Config.set(values)
    for key, value in values do
        if configuration[key] == nil then
            error(string.format("Attempted to set invalid config key: %s", key), 2)
        end

        if typeof(value) ~= "boolean" then
            error(string.format("Attempted to set config key %q with non-boolean value: %q", key, typeof(value)), 2)
        end

        configuration[key] = value
    end
end

return Config