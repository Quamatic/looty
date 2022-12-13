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
            predicates = {
                function ()
                    return false
                end
            }
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
            type = "LootReference",
            reference = reference,
            weight = -1,
        }
    },
    predicates = {},
    state = { luck = 0 },
})

for _, t in ipairs(pool:roll()) do
    print(t.item)
end