local t = require(script.Parent.Parent.t)
local None = require(script.Parent.None)
local Config = require(script.Parent.Config)
local log = require(script.Parent.log)

-- This value makes it so items with this weight are guaranteed to roll
local GUARANTEED_ROLL_WEIGHT = -1

-- Implementation
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

--[[
    Adds a predicate to the loot pool, which is required to be successful for the pool to roll.
]]
function LootPoolBuilder:withPredicate(predicate)
    table.insert(self._predicates, predicate)
    return self
end

function LootPoolBuilder:build(name)
    return LootPool.new(name, self._items, self._rolls, self._predicates, {})
end

-- Typecheckers
local validRolls = t.union(
    t.numberPositive,
    t.interface({
        min = t.numberPositive,
        max = t.numberPositive,
    })
)

local validItems = t.union(
    t.array(t.interface({
        -- Either a string or a loot pool
        name = t.union(t.string, t.isLootPool),
        weight = t.optional(t.union(
            t.numberPositive,
            t.number(GUARANTEED_ROLL_WEIGHT)
        )), -- Either positive or -1
        quantity = t.optional(t.number),
        predicates = t.optional(t.callback),
        modifiers = t.optional(t.callback),
    })),
    t.intersection(function(items)
        return #items > 0, "You must provide at least one item"
    end)
)

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
        _items = items,
        _rolls = rolls,
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
            -- Log if needed
            if Config.get("logFailedPredicates") then
                log(string.format("Predicate %s failed on pool %s", debug.info(predicate, "n"), self._name))
            end
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

            if counter > chosen or item.weight == GUARANTEED_ROLL_WEIGHT then
                -- If this item is None, then it is just an empty roll. So don't do any processing after this.
                if item.name == None then
                    break
                end

                item = table.freeze(table.clone(item))

                if item.modifiers ~= nil then
                    -- Apply modifiers on this item
                    -- Modifiers are expected to return the item source back as immutable
                    for _, modifier in ipairs(item.modifiers) do
                        local modified = modifier(item, state)
                        table.freeze(modified)

                        item = modified
                    end
                end

                table.insert(results, item.name)
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

-- Creates a detailed format of the loot pool
function LootPool:__tostring()
    local items = table.create(#self._items)

    local weight = 0
    for _, item in self._items do
        weight += item.weight
    end

    for _, item in ipairs(self._items) do
        local chance = item.weight / weight * 100
        table.insert(items, string.format("(item = %q, weight = %.2f (chance: %.3f%%))", item.id, item.weight, chance))
    end

    return string.format("LootPool {\n\t%s\n}", table.concat(items, "\n\t"))
end

return LootPool