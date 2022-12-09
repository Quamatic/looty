local LootPool = require(script.LootPool)
local LootTable = require(script.LootTable)
local None = require(script.None)
local Config = require(script.Config)
local ItemType = require(script.ItemType)
local PoolType = require(script.PoolType)

return {
    setConfig = Config.set,

    PoolType = PoolType,
    ItemType = ItemType,
    None = None,
    LootPool = LootPool,
    LootTable = LootTable,
}