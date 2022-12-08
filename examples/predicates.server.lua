local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Looty = require(ReplicatedStorage.Lib.Looty)

local LootTable = Looty.LootTable
local LootPool = Looty.LootPool

-- Predicate usage within Looty

-- Create a loot pool that only has 1 roll, meaning only one possible item can roll.
-- Except, the pool will only run when a random roll between 1 and 2 is 1
-- Gold = 40%, Silver = 60%
local pool = LootPool.builder()
    :setRolls(1)
    -- Pool predicates get passed the state of the table, including the random number generator used.
    :when(function(state)
        return state.random:NextInteger(1, 2) == 1
    end)
    :addItem({ id = "gold", weight = 0.6 })
    :addItem({ id = "silver", weight = 0.4 })
    :build("predicate")

-- Create a loot table
local tbl = LootTable.builder()
    :withLootPool(pool)
    :build()

-- Roll and test results
local result = tbl:roll()

if #result == 0 then
    print("Predicates failed - no loot! :(")
else
    print("Yay, we won something! - " .. result[1])
end