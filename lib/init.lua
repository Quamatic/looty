local LootPool = require(script.LootPool)
local LootTable = require(script.LootTable)
local None = require(script.None)
local Config = require(script.Config)

return {
    setConfig = Config.set,

    None = None,
    LootPool = LootPool,
    LootTable = LootTable,
}