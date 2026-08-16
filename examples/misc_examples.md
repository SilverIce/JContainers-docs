# Small Collection Operations

These independent examples cover collection operations that are useful but too
small to need a complete example module.

## Load Optional Data on Demand

`weak_require` behaves like a softly failing, weakly cached form of `require`.
It returns `nil` when the module cannot be loaded. When it succeeds, the cache
does not prevent the returned module from being collected. This does not unload
the module immediately: it remains available until Lua's garbage collector
eventually collects it.

```lua
---@param topic string
---@return string|nil
local function getHelpText(topic)
    local helpText = weak_require 'my_mod.data.help_text'
    if helpText == nil then
        return nil
    end

    return helpText[topic]
end
```

Keep using ordinary `require` for modules whose identity or module-local state
must remain stable for the lifetime of the Lua context. `weak_require` is mainly
useful for large or optional data modules that are expensive to keep loaded but
are needed only occasionally: generated lookup tables, localized text, optional
data sets, or resource catalogs. After the last strong Lua reference to such a
module disappears, the module becomes eligible for collection. It may remain
alive until a later garbage-collection cycle; if it is collected, a subsequent
call to `weak_require` loads it again.

## Store an Explicit 32-bit Integer

An ordinary Lua number is stored in JContainers as a floating-point value. Use
`Int32` when the stored value must instead have the signed 32-bit integer type.

```lua
local state = JMap.object()

state.retryCount = Int32(3)

-- Reading the value produces an ordinary Lua number again.
assert(state.retryCount == 3)

-- Integer-only operations can now operate on the stored value.
local previous = JAtomic.fetchAddInt(state, '.retryCount', 1)
assert(previous == 3)
assert(state.retryCount == 4)
```

`Int32(value)` is a storage-type marker rather than a separate number type for
normal Lua arithmetic. Values passed to it should be within the signed 32-bit
range.

## Construct a Map and Install It If Absent

`JMap.objectWithTable` constructs a JContainers map from a Lua table.
`JMap.getOrInsert` then atomically returns the value already stored at the key,
or installs and returns the supplied value when the key is absent.

```lua
---@class ActorState
---@field health number
---@field is_dead boolean

---@param states JMapInstance
---@param actor_id string
---@return ActorState
local function getActorState(states, actor_id)
    local initial = JMap.objectWithTable({
        health = 100.0,
        is_dead = false,
    }) ---@as ActorState

    return JMap.getOrInsert(states, actor_id, initial)
end
```

## Exchange Map Values Atomically

`JMap.exchange` writes only when the value actually changes. This makes its
Boolean result useful for collecting changes without a separate read.

```lua
---@param last_sent_scales JMapInstanceT<number>
---@param changed_scales JMapInstanceT<number>
---@param morph_name string
---@param scale number
local function recordChangedScale(last_sent_scales, changed_scales, morph_name, scale)
    local rounded_scale = math.floor(scale * 1000.0 + 0.5)

    if JMap.exchange(last_sent_scales, morph_name, rounded_scale) then
        changed_scales[morph_name] = scale
    end
end
```

Pass `true` as the fourth argument when the previous value is also needed. The
read and replacement happen as one operation.

```lua
local changed, previous_owner = JMap.exchange(state, 'owner', new_owner, true)
```

`JMap.exchangeIfEqual` is a compare-and-exchange operation. It prevents stale
work from replacing a value that has changed since it was read.

```lua
local observed_owner = state.owner
local replaced = JMap.exchangeIfEqual(state, 'owner', observed_owner, new_owner)
```

> **JFormMap note:** `JFormMap.getOrInsert`, `JFormMap.exchange`, and
> `JFormMap.exchangeIfEqual` have the same call shapes and atomic semantics as
> their `JMap` counterparts. Only the key type changes from a string to a
> `Form`.

## Read and Remove an Array Item Atomically

`JArray.pop` returns an item and removes it while holding the collection lock.
Concurrent consumers therefore cannot receive the same queue item.

```lua
---@class QueuedEvent
---@field name string

---@param events JArrayInstanceT<QueuedEvent>
---@return QueuedEvent|nil
local function takeFirstEvent(events)
    return JArray.pop(events, 1) -- Positive indices start at 1.
end

---@param events JArrayInstanceT<QueuedEvent>
---@return QueuedEvent|nil
local function takeLastEvent(events)
    return JArray.pop(events, -1) -- Negative indices count from the end; -1 is the last item.
end
```

Most `JArray` operations that accept an individual index use the same
convention: positive indices are one-based, while negative indices count from
the end. Some bulk operations, including `getValues` and `setValues`, require
positive indices.

## Pack and Unpack Positional Arguments

`JArray.objectWithValues` constructs an array directly from its arguments.
`JArray.unpack` performs the inverse operation, which is convenient when an
array transports a small positional record.

```lua
---@param caster Form
---@param spell Form
---@param rank integer
---@return JArrayInstance
local function makeSpellArguments(caster, spell, rank)
    return JArray.objectWithValues(caster, spell, Int32(rank))
end

---@param args [Form, Form, integer] caster, spell, rank
local function handleSpellArguments(args)
    local caster, spell, rank = JArray.unpack(args)
    -- Use caster, spell, and rank here.
end
```

Optional indices select a smaller range: `JArray.unpack(args, 2, 4)` returns
items two through four. Each item is read separately, so this operation is not
an atomic snapshot when another execution context can modify the same array.

## Read Several Array Values at Once

`JArray.getValues` returns an inclusive range while holding the collection
lock. This provides an atomic snapshot of that range and is useful for
positional records such as an interpolation entry.

```lua
local DELTA = 4
local ELAPSED = 5
local DURATION = 6

---@param interpolation JArrayInstance
---@return number delta, number elapsed, number duration
local function readTiming(interpolation)
    return JArray.getValues(interpolation, DELTA, DURATION)
end
```

Unlike reading the same indices separately or using `JArray.unpack`, another
execution context cannot modify the array partway through this read.
`JArray.getValues` supports at most 16 values and does not support strings.

## Iterate over a Stable Shallow Copy

A callback may add or remove entries from the collection being traversed.
Iterating over `JValue.shallowCopy` keeps that traversal stable while allowing
the original collection to change.

```lua
---@class Listener
---@field active boolean

---@param listeners JArrayInstanceT<Listener>
local function removeInactiveListeners(listeners)
    for _, listener in ipairs(JValue.shallowCopy(listeners)) do
        if not listener.active then
            JArray.eraseValues(listeners, listener)
        end
    end
end
```

Only the outer collection is copied. Nested JContainers objects remain shared
between the original and the copy.
