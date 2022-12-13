local ItemType = require(script.Parent.ItemType)
local Config = require(script.Parent.Config)
local rollRange = require(script.Parent.rollRange)
local t = require(script.Parent.Parent.t)
local Types = require(script.Parent.Types)
local log = require(script.Parent.log)

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
    rolls = t.union(validateRange, t.callback),
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
    @interface PoolContext
    @within LootPool

    .generator Random | number?
    .luck number?
]=]

--[=[
    @interface PoolData
    @within LootPool

    .name string? -- Optional debugging name for the pool
    .rolls number | { min: number, max: number } | (context: PoolContext) -> number -- The amount of rolls provided. Can either be constant, ranged, or a custom generator.
    .items {PoolItem} -- The items in the pool
    .predicates {(context: PoolContext) -> boolean}? -- Optional predicates that can prevent the pool from rolling.
    .state {}? -- Optional state that is merged into the [PoolContext].
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
        _name = data.name or string.format("%s@%s", debug.info(2, "s"), debug.info(2, "l")),
        _rolls = data.rolls,
        _items = data.items,
        _state = data.state,
        _predicates = data.predicates or {},
        _generator = Random.new(),
        _totalPoolWeight = totalPoolWeight,
    }, LootPool)
end

--[=[
    Checks if an object is a LootPool

    @param object any -- The object to check.
    @return boolean -- `true` if the object is a `LootPool`.
]=]
function LootPool.is(object)
    return typeof(object) == "table" and getmetatable(object) == LootPool
end

--[=[
    Returns the total weight of all items combined in the pool

    :::info
    This does not return any modified weight from things like luck.
    :::

    @return number
]=]
function LootPool:getTotalWeight()
    return self._totalPoolWeight
end

--[=[
    Returns the name of the loot pool

    :::info
    If no name is provided during creation, then the pool name is defaulted to the format of `file-name@line`
    :::

    @return string
]=]
function LootPool:getName()
    return self._name
end

function LootPool:_log(message: string)
    log(string.format("[Pool %s] - %s", self._name, message))
end

function LootPool:_choose(context: PoolContext?)
    local chosen = self._generator:NextNumber(0, self._totalPoolWeight)
    local counter = 0

    local result = {}

    for _, item in ipairs(self._items) do
        counter += item.weight

        if counter > chosen or item.weight == Config.get("guaranteedRollWeight") then
            -- Check if item has predicates and do validation if it does
            local pass = true

            if item.predicates ~= nil then
                for _, predicate in ipairs(item.predicates) do
                    if not predicate(context) then
                        -- Log this predicate if needed
                        if Config.get("logFailedPredicates") then
                            self:_log(string.format(
                                "Failed predicate %s for item %s, passing.",
                                debug.info(predicate, "n"),
                                item.type
                            ))
                        end

                        pass = false
                        break
                    end
                end
            end

            if not pass then
                continue
            end

            if item.type == ItemType.Item then
                table.insert(result, {
                    item = item.identifier,
                })
            elseif item.Type == ItemType.ItemQuantity then
                local quantity = rollRange(item.quantity, self._generator)

                table.insert(result, {
                    item = item.identifier,
                    quantity = quantity,
                })
            elseif item.type == ItemType.ItemGroup then
                local copied = table.clone(item.group)
                table.move(copied, 1, #copied, #result + 1, result)

                return result
            elseif item.type == ItemType.LootReference then
                if item.reference == self then
                    error("[Looty] - You cannot have a direct reference to a loot pool", 2)
                end

                local results = item.reference:roll(context)
                table.move(results, 1, #results, #result + 1, result)

                return result
            end
        end
    end

    if #result == 0 then
        error("[Looty] - Rolled nothing, this should not happen.")
    end

    return result
end

function LootPool:_roll(context: PoolContext?)
    if #self._predicates > 0 then
        for _, predicate in ipairs(self._predicates) do
            if not predicate(context) then
                return {}
            end
        end
    end

    local rolls
    if typeof(self._rolls) == "function" then
        local amount = self._rolls(context)
        if typeof(amount) ~= "number" then
            error(string.format("[Looty] - Expected number when getting roll amount on pool", self._name), 2)
        end
        rolls = math.floor(amount)
    else
        rolls = rollRange(self._rolls, self._generator)
    end

    local results = {}

    for _ = 1, rolls do
        local result = self:_choose(context)
        if result ~= nil then
            table.move(result, 1, #result, #results + 1, results)
        end
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

--[=[
    Returns a detailed format of the loot pool.

    **Example:**

    ```lua
    local pool = LootPool.new({
        rolls = 1,
        items = {
            {
                type = ItemType.Item,
                identifier = "gold",
                weight = 4,
            },
            {
                type = ItemType.ItemQuantity,
                identifier = "silver",
                quantity = 20,
                weight = 1,
            }
        }
    })

    print(tostring(pool))

    --[[
        "LootPool(
            totalPoolWeight=100,
            items={
                {
                    type = "Item",
                    identifier = "gold",
                    weight = 4 (chance=80% | (4/5))
                },
                {
                    type = "ItemQuantity",
                    identifier = "silver",
                    quantity = 20,
                    weight = 1 (chance=20% | (1/5))
                }
            }
        )"
    ]]
    ```

    @return string
]=]
function LootPool:__tostring()
    local items = table.create(#self._items)
    local guaranteedRollWeight = Config.get("guaranteedRollWeight")

    for _, item in self._items do
        local format = {}

        table.insert(format, string.format("type = %q", item.type))

        if item.type == ItemType.Item or item.type == ItemType.ItemQuantity then
            table.insert(format, string.format("identifier = %q", item.identifier))
            table.insert(format, string.format("modifiers = %s", if item.modifiers ~= nil then tostring(#item.modifiers) else "0 (none provided)"))

            if item.type == ItemType.ItemQuantity then
                table.insert(format, string.format("quantity = %s", tostring(item.quantity)))
            end
        elseif item.type == ItemType.LootReference then
            if item.reference == self then
                table.insert(format, "reference = (SELF REFERENCE)")
            else
                table.insert(format, string.format("reference = %q", item.reference:getName()))
            end
        elseif item.type == ItemType.ItemGroup then
            table.insert(format, "group = %d", #item.group)
        end

        if item.weight == guaranteedRollWeight then
            table.insert(format, string.format("weight = %d (guaranteed roll)", guaranteedRollWeight))
        else
            table.insert(format, string.format("weight = %d (chance=%d%% | (%d/%d))", item.weight, item.weight / self._totalPoolWeight * 100, item.weight, self._totalPoolWeight))
        end

        table.insert(items, string.format("\t{\n\t\t\t%s\n\t\t}", table.concat(format, "\n\t\t\t")))
    end

    return string.format(
        "LootPool(\n\tname=%q\n\ttotalPoolWeight=%d,\n\titems=%s\n)",
        self._name,
        self._totalPoolWeight,
        string.format("{\n\t%s\n\t}", table.concat(items, ",\n\t"))
    )
end

export type LootPool = typeof(LootPool.new())

return LootPool