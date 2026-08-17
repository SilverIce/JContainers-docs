# JContainers Lua Documentation — API Version 4

## API Reference

The complete Lua API reference is included with every JContainers release that
implements API version 4:

```text
Data/SKSE/Plugins/JC4Data/lua/jc/jcdefs.lua
```

`jcdefs.lua` is the canonical declaration of the globals, types, and functions
provided by JContainers. It also declares the LuaJIT globals needed by its type
annotations, but it does not attempt to redeclare the complete Lua and LuaJIT
environment. The copy shipped with the installed release is authoritative
because it necessarily matches that runtime version.

For convenient browsing and downloading, this repository also includes the
current [`jcdefs.lua`](api/jcdefs.lua). It is updated with the documentation but
does not supersede the version included in an installed release.

The declarations and examples use EmmyLua annotations, which have no runtime
cost. VS Code users can install the EmmyLua extension and make the release's
`JC4Data/lua` directory available to their workspace for completion, type
information, and signature help.

## Lua Environment

User modules and `JLua_evalLua*` expressions run with a curated global
environment. The following Lua and LuaJIT facilities are available alongside
the JContainers globals declared by `jcdefs.lua`:

- library tables: `math`, `io`, `string`, `table`, `bit`, `os`, `debug`,
  `coroutine`, `ffi`, and `jit`;
- base functions: `pairs`, `ipairs`, `next`, `select`, `error`, `assert`,
  `tonumber`, `tostring`, `type`, `print`, `pcall`, `xpcall`, `collectgarbage`,
  `loadfile`, `load`, `setfenv`, `getfenv`, `setmetatable`, and `getmetatable`;
- the JContainers module loaders `require` and `weak_require`.

`jit_zone` is also exposed when the corresponding LuaJIT module is available.
`require` is the JContainers loader for modules below `JC4Data/lua`, not direct
access to Lua's package loader. This is a curated environment rather than the
complete default Lua global table; globals not listed here, such as `package`,
should not be assumed to be available to user modules.

## Module Layout

Keep a mod's modules under its own top-level namespace directory. Within a
namespace such as `MyMod/`, a module may be stored either as a single file such
as `MyMod/Feature.lua` or as a directory entry module at
`MyMod/Feature/init.lua`. `require('MyMod.Feature')` supports both layouts.

An expression evaluated through `JLua_evalLua*` may refer to
`MyMod.function()` directly when the namespace entry point is `MyMod/init.lua`.
This is a convenient entry-point syntax, not a requirement that every module
inside the namespace be named `init.lua`. The examples use both layouts
according to what they demonstrate.

## Example Index

- [Fire a Papyrus Event and Continue with a Lua Callback](examples/papyrus_event_callback.md)
  shows a complete Lua-to-Papyrus-to-Lua round trip through a context selected
  by a `luaCtx` key.
- [Synchronize Updates to a Shared Object](examples/object_locking.md) shows
  pooled Lua execution contexts using a transported JContainers object as
  their lock key.
- [Call a Native SKSE DLL from Lua](examples/native_dll_ffi.md) shows a minimal
  C ABI implemented with CommonLibSSE and called through LuaJIT FFI.
- [Small Collection Operations](examples/misc_examples.md) collects short
  examples of explicit `Int32` storage, map construction, atomic map updates,
  array packing, atomic removal, bulk reads, and stable iteration.
- [Stop an Update When Its Target Expires](examples/weak_references.md) shows
  how queued work can refer to gameplay state without extending its lifetime,
  including the distinction between the temporary `WeakRef` marker, stored weak
  value, and strong wrapper returned by a successful read.
- [Reload Lua While the Game Is Running](examples/hot_reload.md) shows how a
  loose-file development build can invalidate its Lua contexts so changed
  modules are loaded on the next entry from Papyrus.
