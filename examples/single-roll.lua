local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Looty = require(ReplicatedStorage.Lib.Looty)

local LootTable = Looty.LootTable
local LootPool = Looty.LootPool

-- Single pool usage of Looty

-- Create a loot pool that only has 1 roll, meaning only one possible item can roll.
-- Gold = 40%, Silver = 60%
local pool = LootPool.builder()
    :setRolls(1)
    :addItem({ id = "gold", weight = 0.6 })
    :addItem({ id = "silver", weight = 0.4 })
    :build("possible-empty")

-- Create a loot table
local tbl = LootTable.builder()
    -- Tables can have their own state, but there is a default one if not provided.
    :withState({
        -- For the sake of an example, we're using our own random.
        random = Random.new(os.time()),
        -- You can also add a luck modifier to increase odds of items in the pool.
        luck = 1,
    })
    -- Reminder: there must always be at least one pool to roll, otherwise Looty will throw an error.
    -- Can't get your loot otherwise.
    :withLootPool(pool)
    :build()

-- Roll and test results
local result = tbl:roll()

-- This will either print "gold" or "silver"
print(result[1])