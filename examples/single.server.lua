local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Looty = require(ReplicatedStorage.Lib.Looty)

local reference = Looty.LootPool.new({
    name = "TestRefPool",
    rolls = 3,
    items = {
        {
            type = "Item",
            identifier = "gold",
            weight = -1,
        },
        {
            type = "Item",
            identifier = "silver",
            weight = -1,
        }
    },
    state = { luck = 0 },
})

local pool = Looty.LootPool.new({
    name = "TestPool",
    rolls = 1,
    items = {
        {
            type = "Empty",
            weight = 60,
        },
        {
            type = "LootReference",
            reference = reference,
            weight = 40,
        }
    },
    predicates = {},
    state = { luck = 0 },
})

print(tostring(pool))

for _, t in ipairs(pool:roll()) do
    print(t, #t)
end