# Synchronize Updates to a Shared Object

Individual JContainers operations are atomic, but a sequence of operations is
not. In this example, concurrent calls may run in different pooled Lua contexts
within the same JContainers domain and update the same actor state. Both use
the state object itself as the synchronization key, so all related fields are
recalculated as one critical section.

The object is created and owned elsewhere. Papyrus only passes the same object
handle to each context.

## Papyrus

```papyrus
Import JContainers_API4

Bool Function ApplyDamage(Int actorState, Float damage, String source)
    Int transport = JArray_object()
    JArray_addObj(transport, actorState)
    JArray_addFlt(transport, damage)
    JArray_addStr(transport, source)

    Return JLua_evalLuaBool(
        "return LockedStateExample.applyDamage(args[1], args[2], args[3])",
        transport,
        minLife = True
    )
EndFunction
```

Separate Papyrus callers can call `ApplyDamage` with the same `actorState`.
Because no named context is requested, concurrent calls may use different
contexts from the Lua pool. The transport array is temporary, so
`minLife = True` allows it to be collected after the call. It does not change
the lifetime of `actorState`, which is owned elsewhere.

## Lua

The Papyrus expression above uses the mod-specific entry-module name
`LockedStateExample`, so this example places the Lua code at
`Data/SKSE/Plugins/JC4Data/lua/LockedStateExample/init.lua`. The evaluated
expression loads it automatically when it first references
`LockedStateExample`.

```lua
local M = {}

---@class ActorState
---@field health number
---@field damage_taken number
---@field is_dead boolean
---@field last_damage_source string

---@param state ActorState
---@param damage number
---@param source string
---@return boolean
function M.applyDamage(state, damage, source)
    local ok, err = JLockMgr.pcall(state, function()
        local applied_damage = math.min(damage, state.health)
        state.health = state.health - applied_damage
        state.damage_taken = state.damage_taken + applied_damage
        state.is_dead = state.health <= 0
        state.last_damage_source = source
    end)
    assert(ok, err)
    return true
end

return M
```

The lock is associated with the transported `state` object. Without it, two
calls could read the same health value and leave `health`, `damage_taken`, and
`is_dead` inconsistent with one another. Updates to other state objects do not
need a single global application lock. `JLockMgr.pcall` also releases the lock
if the protected function raises an error.
