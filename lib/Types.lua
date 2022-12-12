--[=[
    @interface PoolContext
    @within LootPool

    .generator Random | number?
    .luck number?
]=]

export type PoolContext = {
    generator: Random | number?,
    luck: number?,
}

return nil