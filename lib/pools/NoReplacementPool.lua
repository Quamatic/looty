local LootPool = require(script.Parent.Parent.LootPool)

local NoReplacementPool = setmetatable({}, LootPool)
NoReplacementPool.__index = NoReplacementPool

function NoReplacementPool.new(data)
    local self = LootPool.new(data)
    self._recorded = {}

    return setmetatable(self, NoReplacementPool)
end

function NoReplacementPool:getRecordedItems()
    return self._recorded
end

function NoReplacementPool:reset()
    table.clear(self._recorded)
end

function NoReplacementPool:roll() -- override
    local results = self:_roll()

    if #results > 0 then
        for _, result in ipairs(results) do
            if self._recorded[result] == nil then
                self._recorded[result] = true
            end

            for _, item in ipairs(self._items) do
                -- shorten weight range by 1 to allow other items to gain higher chance
                if item == result then
                    item.weight -= 1
                end
            end
        end
    end

    return results
end

return NoReplacementPool