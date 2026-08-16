# Reload Lua While the Game Is Running

`JUtil.hotReload()` schedules all Lua execution contexts for recreation. The
call that requests the reload is allowed to finish. After a context leaves its
current execution, its next entry creates a fresh Lua state and loads the
modules again.

This makes it possible to edit loose Lua files and try the changes without
restarting Skyrim. Call `hotReload` only after the current operation has
finished its useful work:

```lua
local M = {}

function M.reloadLua()
    print('Lua contexts will be recreated on their next entry')
    JUtil.hotReload()
end

return M
```

If this file is `my_mod/development/init.lua`, an entry from Papyrus can invoke
it as `development.reloadLua()`. Edit the module after that call completes; the
next Lua entry will observe the new loose-file contents.

The invalidation is runtime-wide rather than local to the calling module or a
named context. Idle pooled contexts are discarded immediately. A context that
is currently executing is discarded when that execution returns, while a named
context is recreated lazily when it is entered again. Consequently, no code
should rely on context-local Lua state surviving the reload.

`JUtil.hotReload` is a supported developer-facing API, but it is intended only
as a development aid. Do not make production behavior depend on reloading Lua
source. This example requires the module being edited to be loaded from a loose
Lua file.

## A Loop That Cannot Return

Prefer `hotReload` whenever the current Lua execution can return to JContainers.
It gives the next entry an entirely new Lua state rather than partially
reloading one that has already run application code.

A permanent development or simulation loop cannot use that lifecycle: it never
leaves its current context, so that context cannot be discarded. In this narrow
case, `JC_Internals.flush_modules()` clears the `require` and `weak_require`
caches inside the current context:

```lua
local function developmentLoop()
    while simulationIsRunning() do
        local command = nextSimulationCommand()

        if command == 'reload' then
            JC_Internals.flush_modules()
        else
            require('my_mod.simulation.commands').execute(command)
        end
    end
end
```

Existing references to previously loaded module tables remain valid, so this
is not equivalent to recreating the Lua state. Code that needs to observe a
reloaded module must call `require` again after the flush. For that reason,
`flush_modules` is also development-only and should be reserved for loops where
`hotReload` cannot be used.
