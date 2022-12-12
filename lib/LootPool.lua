local ItemType = require(script.Parent.ItemType)
local Config = require(script.Parent.Config)
local rollRange = require(script.Parent.rollRange)
local t = require(script.Parent.Parent.t)
local Types = require(script.Parent.Types)

type PoolContext = Types.PoolContext

--[=[
    @class LootPool
]=]
local LootPool = {}
LootPool.__index = LootPool

-- Typecheckers
local validateAmount = t.intersection(t.integer, t.numberPositive)

local validateRange = t.union(
    validateAmount,
    t.strictInterface({
        min = validateAmount,
        max = validateAmount,
    })
)

local validateItems
validateItems = t.intersection(t.array(t.intersection(
    t.interface({
        weight = t.intersection(t.integer, function(weight)
            local guaranteedRollWeight = Config.get("guaranteedRollWeight")

            if weight < 0 and weight ~= guaranteedRollWeight then
                return false, string.format(
                    "Weight cannot be below negative unless it is %d for ensuring guaranteed selection",
                    guaranteedRollWeight
                )
            end

            return true
        end),
        luck = t.optional(t.numberPositive),
        predicates = t.optional(t.array(t.callback)),
    }),

    t.union(
        t.interface({
            type = t.literal("Empty"),
        }),

        t.interface({
            type = t.literal("Item"),
            identifier = t.string,
            modifiers = t.optional(t.array(t.callback)),
        }),

        t.interface({
            type = t.literal("ItemQuantity"),
            identifier = t.string,
            quantity = validateRange,
            modifiers = t.optional(t.array(t.callback)),
        }),

        t.interface({
            type = t.literal("LootReference"),
            reference = t.intersection(t.table, function(object)
                return LootPool.is(object)
            end)
        }),

        t.interface({
            type = t.literal("ItemGroup"),
            group = validateItems,
        })
    ))
), function(items)
    if #items == 0 then
        return false, "You must provide at least one item inside the pool"
    end
    return true
end)

local validatePoolData = t.interface({
    name = t.optional(t.string),
    rolls = validateRange,
    items = validateItems,
    predicates = t.optional(t.array(t.callback)),
    state = t.optional(t.table)
})
-- End typecheckers

--[=[
    @interface BasePoolItem
    @within LootPool

    :::tip
    Setting an item's weight to -1 will make it guaranteed to roll, if needed. You can also change the guaranteed roll weight inside of the config.
    :::

    .type ItemType
    .weight number
    .luck number?
    .predicates {(context: PoolContext) -> boolean}?
]=]

--[=[
    @interface Empty
    @within LootPool

    .type "Empty"
]=]

--[=[
    @interface Item
    @within LootPool

    .type "Item"
    .identifier string
    .modifiers {<T>(context: PoolContext) -> T}?
]=]

--[=[
    @interface ItemQuantity
    @within LootPool

    .type "ItemQuantity"
    .identifier string
    .quantity number | { min: number, max: number }
    .modifiers {<T>(context: PoolContext) -> T}?
]=]

--[=[
    @interface ItemGroup
    @within LootPool

    .type "ItemGroup"
    .group {PoolItem}
]=]

--[=[
    @interface LootReference
    @within LootPool

    .type "LootReference"
    .reference LootPool
]=]

--[=[
    @interface PoolData
    @within LootPool

    .name string?
    .rolls number | { min: number, max: number }
    .items {PoolItem}
    .predicates {(context: PoolContext) -> boolean}?
    .state any?
]=]

--[=[
    Constructs a new LootPool

    :::warning
    If you provide no items to roll, Looty will throw an error. You'll have nothing to roll!
    :::

    @param data PoolData -- The structure of your pool
    @return LootPool
]=]
function LootPool.new(data)
    assert(validatePoolData(data))

    local totalPoolWeight = 0
    for _, item in data.items do
        -- Don't count guaranteed items in the pool
        if item.weight == Config.get("guaranteedRollWeight") then
            continue
        end

        local itemLuck = item.luck or 1
        local luckFromState = data.state.luck or 1

        totalPoolWeight += math.floor(item.weight + itemLuck * luckFromState)
    end

    return setmetatable({
        _name = data.name,
        _rolls = data.rolls,
        _items = data.items,
        _state = data.state,
        _generator = Random.new(),
        _totalPoolWeight = totalPoolWeight,
    }, LootPool)
end

function LootPool:__iter()
    return next, self._items
end

--[=[
    Checks if an object is a LootPool

    @param object any -- The object to check.
    @return boolean -- `true` if the object is a `LootPool`.
]=]
function LootPool.is(object)
    return typeof(object) == "table" and getmetatable(object) == LootPool
end

function LootPool:setState(state)
    
end

function LootPool:setContext()
    
end

--[=[
    Returns the total weight of all items combined in the pool

    @return number
]=]
function LootPool:getTotalWeight()
    return self._totalPoolWeight
end

function LootPool:_choose()
    local chosen = self._generator:NextNumber(0, self._totalPoolWeight)
    local counter = 0

    for _, item in ipairs(self._items) do
        counter += item.weight

        if counter > chosen or item.weight == Config.get("guaranteedRollWeight") then
            -- Check if item has predicates and do validation if it does
            if item.predicates ~= nil then
                for _, predicate in ipairs(item.predicates) do
                    if not predicate(self._state) then
                        break
                    end
                end
            end

            if item.type == ItemType.Item then
                return {
                    {
                        item = item.identifier,
                    },
                }
            elseif item.Type == ItemType.ItemQuantity then
                local quantity = rollRange(item.quantity, self._generator)

                return {
                    {
                        item = item.identifier,
                        quantity = quantity,
                    },
                }
            elseif item.type == ItemType.ItemGroup then
                local result = table.create(#item.group)

                local copied = table.clone(item.group)
                table.move(copied, 1, #copied, 1, result)

                return result
            elseif item.type == ItemType.LootReference then
                if item.reference == self then
                    error("[Looty] - You cannot have a direct reference to a loot pool", 2)
                end

                local results = item.reference:roll({})

                local result = table.create(#results)
                table.move(results, 1, #results, 1, result)

                return result
            end
        end
    end

    error("[Looty] - Rolled nothing, this should not happen.")
end

function LootPool:_roll(context: PoolContext?)
    if self._predicates ~= nil then
        for _, predicate in ipairs(self._predicates) do
            if not predicate(context) then
                return {}
            end
        end
    end

    local rolls = rollRange(self._rolls, self._generator)
    local results = {}

    for _ = 1, rolls do
        local result = self:_choose()
        table.move(result, 1, #result, #results + 1, results)
    end

    return results
end

--[=[
    Does the rolling process of the loot pool

    :::caution
    If the pool has predicates provided, and any of them fail, then this will return an empty table. You can specify the behavior of predicates.
    :::

    @param context PoolContext? -- Optional context to specify how the pool should roll. If none is specified then the pool will fall back to the default context.
    @return {{ item: string, quantity: number? }} -- The results of the roll.
]=]
function LootPool:roll(context: PoolContext?)
    return self:_roll(context)
end

function LootPool:__tostring()
    return string.format(
        "LootPool(weight=%d, items=%s, state=%s)",
        self._totalPoolWeight,
        tostring(self._items),
        tostring(self._state)
    )
end

export type LootPool = typeof(LootPool.new())

return LootPool