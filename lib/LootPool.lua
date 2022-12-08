local t = require(script.Parent.Parent.t)

local validRolls = t.union(
    t.numberPositive,
    t.interface({
        min = t.numberPositive,
        max = t.numberPositive,
    })
)

local validItems = t.union(
    t.array(t.interface({
        id = t.any,
        weight = t.optional(t.numberPositive),
        modifiers = t.optional(t.callback),
    })),
    t.intersection(function(items)
        return #items > 0, "You must provide at least one item"
    end)
)

local LootPool = {}
LootPool.__index = LootPool

-- Pool builder
local LootPoolBuilder = {}
LootPoolBuilder.__index = LootPoolBuilder

--[[
    ```lua
    local pool = LootPool.builder()
        :setRolls(2)
        :addItem({ id = "coins", weight = 0.7, })
        :addItem({ id = "gems", weight = 0.3, })
        :build()

    local items = pool:roll()
    ```
]]
function LootPoolBuilder.new()
    return setmetatable({
        _items = {},
        _rolls = 1,
        _predicates = {},
    }, LootPoolBuilder)
end

function LootPoolBuilder:addItem(item)
    -- Default weight to 1
    if item.weight == nil then
        item.weight = 1
    end

    table.insert(self._items, item)
    return self
end

function LootPoolBuilder:setRolls(rolls)
    self._rolls = rolls
    return self
end

function LootPoolBuilder:when(predicate)
    table.insert(self._predicates, predicate)
    return self
end

function LootPoolBuilder:build(name)
    return LootPool.new(name, self._items, self._rolls, self._predicates, {})
end

--[[
    Creates a new LootPool

    A LootPool is the core container of individual pools, and designed to be consumed
]]
function LootPool.new(name, items, rolls, predicates, middleware)
    assert(validItems(items))
    assert(validRolls(rolls))
    assert(t.array(t.callback)(predicates))

    return setmetatable({
        _name = name,
        _items = table.freeze(items),
        _rolls = rolls,
        _modifiers = {},
        _predicates = predicates,
        _middleware = middleware,
    }, LootPool)
end

-- Checks if an object is a LootPool
function LootPool.isLootPool(object)
    return typeof(object) == "table" and getmetatable(object) == LootPool
end

--[[
    Creates a new LootPoolBuilder

    Useful for ease of construction of a loot pool
]]
function LootPool.builder()
    return LootPoolBuilder.new()
end

--[[
    Rolls the LootPool
]]
function LootPool:roll(state)
    -- Roll predicates
    for _, predicate in ipairs(self._predicates) do
        if not predicate(state) then
            print(string.format("[Looty Debug] - Predicate %s failed on pool %s", debug.info(predicate, "n"), self._name))
            -- Predicate failed, return empty result
            return {}
        end
    end

    local random = state.random

    -- Get the total rolls that will be done
    local rolls = if typeof(self._rolls) == "number"
        then self._rolls
        else random:NextInteger(self._rolls.min, self._rolls.max)

    -- Get total pool weight
    local weight = 0
    for _, item in self._items do
        weight += item.weight
    end

    local results = {}
    for _ = 1, rolls do
        local chosen = random:NextNumber(0, weight)
        local counter = 0

        for _, item in self._items do
            counter += item.weight

            if counter > chosen then
                if item.modifiers ~= nil then
                    -- Apply modifiers on this item
                    for _, modifier in ipairs(item.modifiers) do
                        modifier(item, state)
                    end
                end

                table.insert(results, item.id)
                break
            end
        end
    end

    if #results == 0 then
        error(string.format("[Looty] Rolled zero items in this pool %s - this should not happen.", self._name))
    end

    print(string.format("%s -> %d (%d)", self._name, rolls, #results))

    return results
end

function LootPool:__tostring()
    local items = table.create(#self._items)

    for _, item in ipairs(self._items) do
        table.insert(items, string.format("(item = %q, weight = %.2f)", item.id, item.weight))
    end

    return string.format("LootPool {\n\t%s\n}", table.concat(items, "\n\t"))
end

return LootPool