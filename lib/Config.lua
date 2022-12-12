--[=[
    @class Config

    The configuration settings for Looty
]=]

--[=[
    @interface Configuration
    @within Config

    :::warning
    Setting `guaranteedRollWeight` to anything below zero will result in Looty throwing an error.
    :::

    .logFailedPredicates boolean -- Logs predicates that fail on loot pools, as well as individual items.
    .typeChecking boolean -- `true` if you want type checking to be enabled. This is on by default.
    .guaranteedRollWeight number -- The number that specifies what weight should be considered as a guaranteed item. The default is -1.
]=]

local defaultConfiguration = {
    logFailedPredicates = false,
    typeChecking = true,
    guaranteedRollWeight = -1,
}

local configuration = {}
for key, value in pairs(defaultConfiguration) do
    configuration[key] = value
end

local Config = {}

--[=[
    @within Config
    @function get
    @param name string -- The name of the config
    @return boolean | number

    Returns the current value of a specified configuration
]=]

function Config.get(name)
    return configuration[name]
end

--[=[
    @within Config
    @function set
    @param values {[string]: boolean} -- The configurations you want to change

    Changes the current configuration values to the newly specified ones.
]=]
function Config.set(values)
    for key, value in values do
        if defaultConfiguration[key] == nil then
            error(string.format("Attempted to set invalid config key: %s", key), 2)
        end

        if typeof(value) ~= typeof(defaultConfiguration[key]) then
            error(string.format("Attempted to set config key %q with invalid type: %q. Expected type %q", key, typeof(value), typeof(defaultConfiguration[key])), 2)
        end

        configuration[key] = value
    end
end

return Config