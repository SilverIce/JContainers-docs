# Call a Native SKSE DLL from Lua

JContainers Lua modules can use LuaJIT FFI to call C exports from another DLL.
This example exposes two small CommonLibSSE functions and wraps them in a Lua
module. Assume that `ExampleNative.dll` is a valid SKSE plugin installed under
`Data/SKSE/Plugins`.

## C++ DLL Exports

`extern "C"` prevents C++ name mangling, while `__declspec(dllexport)` makes
the functions available to `ffi.load`. Passing a Form ID keeps game-specific
C++ object layouts out of the FFI boundary.

```cpp
#include <RE/Skyrim.h>

#include <cstdint>

extern "C"
{
    __declspec(dllexport) bool Example_IsInWater(
        std::uint32_t form_id) noexcept
    {
        const auto reference =
            RE::TESForm::LookupByID<RE::TESObjectREFR>(form_id);
        return reference && reference->IsInWater();
    }

    __declspec(dllexport) bool Example_IsActorInCombat(
        std::uint32_t form_id) noexcept
    {
        const auto actor = RE::TESForm::LookupByID<RE::Actor>(form_id);
        return actor && actor->IsInCombat();
    }
}
```

## Lua FFI Module

The code can be placed in a regular module such as
`Data/SKSE/Plugins/JC4Data/lua/MyMod/NativeExample.lua`, where `MyMod` is the
mod's namespace. Other modules can load it with
`require('MyMod.NativeExample')`. The JContainers Lua environment already
exposes the global `ffi` table, so no additional LuaJIT module import is
required.

```lua
ffi.cdef[[
    bool Example_IsInWater(uint32_t form_id);
    bool Example_IsActorInCombat(uint32_t form_id);
]]

local Native = assert(ffi.load('Data/SKSE/Plugins/ExampleNative.dll'))

local M = {}

---@param reference Form
---@return boolean
function M.isInWater(reference)
    return Native.Example_IsInWater(reference.form_id)
end

---@param actor Form
---@return boolean
function M.isActorInCombat(actor)
    return Native.Example_IsActorInCombat(actor.form_id)
end

return M
```

The declarations passed to `ffi.cdef` must exactly match the exported C ABI;
an incorrect parameter or return type can crash the game. The native function
runs synchronously on the thread currently evaluating Lua. Game operations
that require the main thread should instead be submitted through the
appropriate SKSE task mechanism.
