local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Looty = require(ReplicatedStorage.Lib.Looty)

local LootTable = Looty.LootTable
local LootPool = Looty.LootPool

-- Empty roll usage of looty

-- Gold = 20%, Silver = 30%, Empty = 50%
-- So, this pool has a 50% chance to roll absolutely nothing!
local pool = LootPool.builder()
    :setRolls(1)
    -- Use `Looty.None` for determining an empty roll
    :addItem({ id = Looty.None, weight = 0.5 })
    :addItem({ id = "gold", weight = 0.2 })
    :addItem({ id = "silver", weight = 0.3 })
    :build()

-- Create a loot table
local tbl = LootTable.builder()
    :withLootPool(pool)
    :build()

-- Roll and test results
local result = tbl:roll()

if #result == 0 then
    print("Pool rolled completely empty, oh well.")
else
    print("Hey, we actually got something -", result[1])
end