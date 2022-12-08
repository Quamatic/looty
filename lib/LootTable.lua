local t = require(script.Parent.Parent.t)
local LootPool = require(script.Parent.LootPool)

local DEFAULT_LOOT_STATE = {
    random = Random.new(),
    luck = 1,
}

local isLootPool = t.intersection(function(object)
    return LootPool.isLootPool(object), "Object must be a valid LootPool"
end)

local LootTable = {}
LootTable.__index = LootTable

-- Table builder
local LootTableBuilder = {}
LootTableBuilder.__index = LootTableBuilder

function LootTableBuilder.new()
    return setmetatable({
        _pools = {},
        _state = table.clone(DEFAULT_LOOT_STATE)
    }, LootTableBuilder)
end

function LootTableBuilder:withState(state)
    self._state = state
    return self
end

function LootTableBuilder:withLootPool(pool)
    table.insert(self._pools, pool)
    return self
end

function LootTableBuilder:withLootPools(...)
    local pools = { ... }
    table.move(pools, 1, #pools, #self._pools + 1, self._pools)
    return self
end

function LootTableBuilder:build()
    return LootTable.new(self._pools, self._state)
end

--[[
    Creates a new loot table

    Loot tables are containers of individual loot pools
]]
function LootTable.new(pools, state)
    assert(t.array(isLootPool)(pools))
    assert(#pools >= 1, "You must provide at least one pool in a loot table")

    return setmetatable({
        _pools = pools,
        _state = state,
    }, LootTable)
end

function LootTable.builder()
    return LootTableBuilder.new()
end

function LootTable:getState()
    return self._state
end

function LootTable:roll()
    local results = {}

    for _, pool in ipairs(self._pools) do
        local poolRollResults = pool:roll(self._state)
        table.move(poolRollResults, 1, #poolRollResults, #results + 1, results)
    end

    return results
end

return LootTable