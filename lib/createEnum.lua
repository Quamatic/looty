local function createEnum(values)
    local enum = {}

    for _, member in ipairs(values) do
        enum[member] = member
    end

    return setmetatable(enum, {
        __index = function(_, key)
            error(string.format("%s is not a valid member!", key), 2)
        end,

        __newindex = function()
            error("You cannot create new members inside of an enum!", 2)
        end
    })
end

return createEnum