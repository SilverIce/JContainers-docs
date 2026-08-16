# Stop an Update When Its Target Expires

An update scheduler owns its pending entries, but it does not necessarily own
the gameplay objects those entries operate on. A weak target lets obsolete work
disappear naturally after the target's real owner releases it.

In this example, the update list strongly owns each `UpdateEntry`. Another
gameplay subsystem owns each `ActorState`, while the update entry only refers
to that state weakly. Both are JContainers map objects; the annotations describe
their application-level fields.

```lua
local M = {}

---@class ActorState
---@field health number

---@class UpdateEntry
---@field target ActorState|nil Stored weakly; resolved to a strong wrapper on read.
---@field elapsed number

---@type JArrayInstanceT<UpdateEntry>
local updates = JArray.object()

---@param target ActorState Owned by another gameplay subsystem.
function M.schedule(target)
    local entry = JMap.objectWithTable({
        elapsed = 0.0,
    }) ---@as UpdateEntry

    -- WeakRef(target) is a temporary strong write marker. The entry stores a
    -- weak reference after assignment.
    ---@diagnostic disable-next-line: assign-type-mismatch
    entry.target = WeakRef(target)

    JArray.insert(updates, entry)
end

---@param dt number
function M.run(dt)
    for index = #updates, 1, -1 do
        local entry = updates[index]
        local target = entry.target

        if target == nil then
            JArray.eraseIndex(updates, index)
        else
            entry.elapsed = entry.elapsed + dt
            -- Continue updating target here.
        end
    end
end

return M
```

The temporary wrapper returned by `WeakRef(target)` retains `target` until that
wrapper is collected. Its purpose is to tell JContainers to store the assigned
field as a weak reference.

Reading `entry.target` locks the stored weak reference. It returns an ordinary
strong `ActorState` wrapper while the target exists, or `nil` after the target
expires. The value stored in `entry` remains weak after a successful read.

EmmyLua cannot express a field whose write type is `WeakRef<ActorState>` but
whose read type is `ActorState|nil`, so the assignment suppresses that one
expected type mismatch. The `get()` method belongs to the temporary `WeakRef`
marker and is not needed when reading from a JContainers collection.
