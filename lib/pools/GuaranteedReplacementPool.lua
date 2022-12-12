local LootPool = require(script.Parent.Parent.LootPool)
local Config = require(script.Parent.Parent.Config)

local GuaranteedReplacementPool = setmetatable({}, LootPool)
GuaranteedReplacementPool.__index = GuaranteedReplacementPool

local function defaultSampler(item, _state)
    return 100 / item.rolls / 100
end

function GuaranteedReplacementPool.new(data, sampler)
    local self = LootPool.new(data)

    self._sample = sampler or defaultSampler
    self._rolls = 0

    return setmetatable(self, GuaranteedReplacementPool)
end

function GuaranteedReplacementPool:reset()
    self._rolls = 0
    table.clear(self._modified)
end

function GuaranteedReplacementPool:roll() -- override
    local results = self:_roll()
    self._rolls += 1

    for _, result in results do
        for _, item in ipairs(self._items) do
            -- don't count guaranteed items
            if item.weight == Config.get("guaranteedRollWeight") then
                continue
            end

            if item.rolls == nil and item == result then
                item.weight *= self._sample(item)
            end
        end
    end

    return results
end

return GuaranteedReplacementPool