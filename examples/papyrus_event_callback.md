# Fire a Papyrus Event and Continue with a Lua Callback

Lua owns the workflow in this example. Code running in a named Lua execution
context decides to show a message, invokes an event on a Papyrus event-handler
script attached to a specific Quest, and continues in Lua after the Papyrus
operation finishes.
The round trip demonstrates direct Lua-to-Papyrus invocation, Form lookup, a
`JArray` argument transport, a serializable callback, and the selected
message-box button returned by Papyrus. Choosing the first button continues the
workflow by asking Papyrus to cast a Spell.

The example uses `SkyMessage.ShowArray` from the SkyrimScripting MessageBox SKSE
plugin so Lua can supply both the message and a dynamic list of buttons. The
surrounding mod is assumed to submit `update()` to the
`JC4EventCallbackExample` Lua execution context from a Papyrus-driven update
loop; creation of that context and its update loop are outside this example.

## Lua

This example uses the directory entry module
`Data/SKSE/Plugins/JC4Data/lua/EventCallbackExample/init.lua`. That layout lets
evaluated Lua code invoke `EventCallbackExample.showMessageBox()` without an
explicit `require`.

```lua
local M = {}

local PAPYRUS_EVENT_HANDLER_QUEST = JString.decodeForm('MyMod.esp', 0x800)
local PLAYER = JString.decodeForm('Skyrim.esm', 0x14)
local EXAMPLE_SPELL = JString.decodeForm('MyMod.esp', 0x801)

function M.reportMessageBoxSelection(_) end

function M.showMessageBox()
    local buttons = JArray.objectWithValues(
        'Cast spell',
        'Cancel'
    )

    local label = 'Message-box result'
    local callback = JCallback.createV2(
        ---@param choice_index integer One-based index; zero means no selection.
        ---@param returned_buttons JArrayInstanceT<string>
        function(choice_index, returned_buttons)
            local selected = returned_buttons[choice_index] or 'No selection'
            JUtil.printConsole(('%s: %s'):format(label, selected))
            M.reportMessageBoxSelection(selected)

            if choice_index == 1 then
                local cast_args = JArray.objectWithValues(PLAYER, EXAMPLE_SPELL)
                JModEvent.invokeFunction(PAPYRUS_EVENT_HANDLER_QUEST, 'CastSpell', cast_args)
            end
        end
    )

    local event_args = JArray.objectWithValues(
        'Cast the example spell?',
        buttons,
        callback
    )

    JModEvent.invokeFunction(PAPYRUS_EVENT_HANDLER_QUEST, 'ShowMessageBox', event_args)
end

-- Conceptually, the surrounding Lua-owned runtime may look like this:
--
-- function M.update(dt)
--     simulationTimers.execute(dt)
--     effectTimers.execute(dt)
--
--     -- A due UI timer may call M.showMessageBox().
--     uiTimers.execute(dt)
-- end
--
-- Somewhere in Papyrus:
--
-- Event OnUpdate()
--     JLua_evalLuaAsync("EventCallbackExample.update(1.0)", 0, "JC4EventCallbackExample")
--     RegisterForSingleUpdate(1.0)
-- EndEvent

return M
```

`JC4EventCallbackExample` is the named Lua execution context in this example. All
work submitted to that context is processed in order and uses the same Lua
state. This workflow therefore does not need `JLockMgr`; object locking is
useful when shared state can be reached from different execution contexts.

When the module is loaded, `JString.decodeForm` resolves the Quest, Player, and
Spell once from their plugin names and plugin-local Form IDs. `0x14` is the
standard Player reference in `Skyrim.esm`. Subsequent calls to
`showMessageBox()` reuse the resolved Forms because the module loader caches the
entry point within the Lua execution context. Replace the `MyMod.esp` arguments
with the identities of the Quest carrying the script below and a Spell from the
example plugin.

`JModEvent.invokeFunction` targets `PAPYRUS_EVENT_HANDLER_QUEST` directly, so
this example does not use `JModEvent_regForm`. Registration is needed for named
events broadcast to subscribers, not for a call directed at a known receiver.

## Papyrus

Create a Quest named `JC4PapyrusEventHandlerQuest` and attach the script below.
The script acts as a small Papyrus adapter; it can expose UI and game operations
to Lua without starting or owning the Lua workflow itself.

```papyrus
Scriptname JC4PapyrusEventHandler extends Quest

Event ShowMessageBox(String message, Int buttons, Int callback)
    Int buttonIndex = SkyMessage.ShowArray(
        message,
        JArray_asStringArray(buttons),
        getIndex = True
    ) as Int

    ; Lua uses one-based indexing. SkyMessage returns -1 when no result is
    ; available, which becomes 0 and therefore does not select a button.
    JArray_addInt(callback, buttonIndex + 1)
    JArray_addObj(callback, buttons)
    JLua_evalLuaCallbackAsync(
        callback,
        "JC4EventCallbackExample",
        minLife = True
    )
EndEvent

Event CastSpell(Form casterForm, Form spellForm)
    Actor casterActor = casterForm as Actor
    Spell spellToCast = spellForm as Spell

    If casterActor != None && spellToCast != None
        spellToCast.Cast(casterActor, casterActor)
    EndIf
EndEvent
```

Choosing `Cast spell` makes the Lua callback invoke `CastSpell` on the same
Quest. Papyrus resolves the supplied Forms to an Actor and a Spell before
performing the cast.

## Callback Versions

V1 captures only the arguments listed explicitly after the function. The
callback function must not have local upvalues, and it receives the captured
arguments followed by the runtime arguments appended by Papyrus.

```lua
local callbackV1 = JCallback.createV1(
    function(label, choice_index, returned_buttons)
        local selected = returned_buttons[choice_index] or 'No selection'
        JUtil.printConsole(('%s: %s'):format(label, selected))
    end,
    'Message-box result'
)
```

V2 captures supported local upvalues instead. They do not appear in the
function parameters, so the callback receives only the runtime arguments.

```lua
local label = 'Message-box result'
local callbackV2 = JCallback.createV2(
    function(choice_index, returned_buttons)
        local selected = returned_buttons[choice_index] or 'No selection'
        JUtil.printConsole(('%s: %s'):format(label, selected))
    end
)
```

Both forms are serializable. The main example uses V2 because the receiver,
Player, Spell, label, and module table already exist as local values. The empty
`M.reportMessageBoxSelection` placeholder demonstrates that V2 can capture a
user-module reference and restore it when the callback is evaluated.

`JLua_evalLuaCallbackAsync` evaluates the callback in the same named context
used by the initial call. The explicit `minLife = True` lets the callback
transport be collected after evaluation when nothing else owns it.
