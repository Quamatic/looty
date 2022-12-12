type Range = number | {
    min: number,
    max: number,
}

local function rollRange(range: Range, random: Random)
    return if typeof(range) == "number"
        then range :: number
        else random:NextInteger(range.min, range.max)
end

return rollRange