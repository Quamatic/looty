local createEnum = require(script.Parent.createEnum)

--[=[
    An enum value that represents the type of item in a pool

    @interface ItemType
    @tag enum
    @within LootPool
    .Empty "Empty" -- An empty item. Using this means that if rolled, nothing will happen.
    .Item "Item" -- The way to specify an item inside a pool.
    .ItemQuantity "ItemQuantity" -- Specified an item inside a loot pool, but has an optional quantity field.
    .ItemGroup "ItemGroup" -- Allows you to group up many items that will be provided in a single roll
    .LootReference "LootReference" -- Allows you to reference other loot tables as an item.

    :::warning
    If an item in a loot pool is a `LootReference` and you attempt to provide a self-reference of the loot pool,
    Looty will throw an error. This is because it's generally bad practice to do that and it can cause infinite recursion.
    :::
]=]
local ItemType = createEnum({
    "Empty",
    "Item",
    "ItemQuantity",
    "ItemGroup",
    "LootReference",
})

return ItemType