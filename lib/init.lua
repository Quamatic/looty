--[=[
    @class Looty

    Looty is an easy to use weight-based loot table library.
]=]

--[=[
    @within Looty
    @prop LootPool LootPool
]=]

--[=[
    @within Looty
    @prop ItemType ItemType
]=]

--[=[
    @within Looty
    @prop LootTable any
]=]

--[=[
    @within Looty
    @function setConfig
    @param values Configuration

    Sets new configuration values

    Example:
    ```lua
    Looty.setConfig({
        logFailedPredicates = true,
        guaranteedRollWeight = -5,
    })
    ```

    The default configs:
    ```lua
    {
        logFailedPredicates = false,
        typeChecking = false,
        guaranteedRollWeight = -1,
    }
    ```
]=]

--[=[
    @within Looty
    @function log
    @param message string
]=]

local LootPool = require(script.LootPool)
local LootTable = require(script.LootTable)
local Config = require(script.Config)
local ItemType = require(script.ItemType)
local log = require(script.log)

return table.freeze({
    setConfig = Config.set,
    log = log,

    ItemType = ItemType,
    LootPool = LootPool,
    LootTable = LootTable,
})