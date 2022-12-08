local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Looty = require(ReplicatedStorage.Lib.Looty)

local LootTable = Looty.LootTable
local LootPool = Looty.LootPool

-- Multi pool usage of Looty

-- First pool, will only have one roll
-- Items: Silver - 70%, Gold - 30%
local pool1 = LootPool.builder()
    :setRolls(1)
    :addItem({ id = "silver", weight = 0.7, })
    :addItem({ id = "gold", weight = 0.3, })
    :build("pool1")

-- Second pool, will be able to roll twice.
-- Items: Copper - 50%, Bronze - 50%
local pool2 = LootPool.builder()
    :setRolls(2)
    :addItem({ id = "copper", weight = 0.5, })
    :addItem({ id = "bronze", weight = 0.5, })
    :build("pool2")

-- Third and final pool, will be able to roll between 1 and 3 times
-- Items: Amethyst - 20%, Cobalt - 80%
local pool3 = LootPool.builder()
    :setRolls({
        min = 1,
        max = 3,
    })
    :addItem({ id = "amethyst", weight = 0.2 })
    :addItem({ id = "cobalt", weight = 0.8 })
    :build("pool3")

-- Create loot table with default context
local tbl = LootTable.builder()
    :withLootPools(pool1, pool2, pool3) -- Using this to prevent repetition of withLootPool
    :build()

-- Print results
local results = tbl:roll()
print(string.format("Total rolls - %d, Items = (%s)", #results, table.concat(results, ", ")))