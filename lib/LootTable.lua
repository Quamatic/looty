local t = require(script.Parent.Parent.t)
local LootPool = require(script.Parent.LootPool)

local DEFAULT_LOOT_CONTEXT = {
    generator = Random.new(),
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
        _context = table.clone(DEFAULT_LOOT_CONTEXT)
    }, LootTableBuilder)
end

function LootTableBuilder:withContext(context)
    self._context = context
    return self
end

function LootTableBuilder:withLootPool(pool)
    table.insert(self._pools, pool)
    return self
end

function LootTableBuilder:build()
    return LootTable.new(self._pools, self._context)
end

--[[
    Creates a new loot table

    Loot tables are containers of individual loot pools
]]
function LootTable.new(pools, context)
    assert(t.array(isLootPool)(pools))
    assert(#pools >= 1, "You must provide at least one pool in a loot table")

    return setmetatable({
        _pools = pools,
        _context = context,
    }, LootTable)
end

function LootTable.builder()
    return LootTableBuilder.new()
end

function LootTable:roll()
    local results = {}

    for _, pool in ipairs(self._pools) do
        local poolRollResults = pool:roll(self._context)
        table.move(poolRollResults, 1, #poolRollResults, #results + 1, results)
    end

    return results
end

return LootTable