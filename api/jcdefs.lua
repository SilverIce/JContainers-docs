---@meta

---@alias JObjectInstance JArrayInstance|JMapInstance|JFormMapInstance

---@alias Value any

---@class Int32
---@overload fun(value: integer): integer
Int32 = {}

---@class Form
---@overload fun(value: integer): Form
Form = {}

---@generic T
---@class WeakRef<T>
---@field get fun(self: WeakRef<T>): T|nil Returns another strong Lua wrapper for the object.

---Creates a temporary marker for storing a JContainers object as a weak
---reference inside another JContainers collection. The marker itself retains
---the object for as long as the marker remains alive in Lua.
---
---After the marker is assigned to a collection, that collection stores a weak
---reference. Reading the value later returns an ordinary strong object wrapper,
---or `nil` if the object has expired; it does not return a `WeakRef` wrapper.
---@generic T
---@param value T
---@return WeakRef<T>
---@nodiscard
function WeakRef(value) end

--#region JValue

JValue = {}

---@param object JObjectInstance
---@param module_name string Will error on nil `module_name`
function JValue.setGCCallback ( object, module_name ) end

---Tests if the @object is JMap, JArray or JFormMap.
---Usage: `local is_map = JMap:isEqualToTypeOf(object)`
---@param object JObjectInstance
---@param jctype JMap|JFormMap|JArray
---@return boolean
function JValue.isEqualToTypeOf(jctype, object) end

---Returns one of the following: JMap/JArray/JFormMap tables.
---Usage: `JValue.typeOf(some_object)`
---@param object JObjectInstance
---@return JMap|JFormMap|JArray|nil
function JValue.typeOf(object) end

---@param path string
---@return JObjectInstance|nil
---@nodiscard
function JValue.readFromFile (path) end

---@param optr JObjectInstance
---@param path string
function JValue.writeToFile ( optr, path ) end

---@param json_proto string
---@return JObjectInstance|nil
---@nodiscard
function JValue.objectFromPrototype(json_proto) end

---@param optr JObjectInstance
function JValue.clear (optr) end

---@generic T
---@param optr T
---@return T
---@nodiscard
function JValue.shallowCopy (optr) end

---@generic T
---@param optr T
---@return T
---@nodiscard
function JValue.deepCopy (optr) end

---@param optr JObjectInstance
---@param path string
---@return Value|nil
function JValue.solvePath(optr, path) end

--#endregion

--#region JArray

JArray = {}

JArray.typeName = 'JArray'

---@alias JArrayInstance { [integer]: Value }

---@generic V
---@class JArrayInstanceT : { [integer]: V }

---@return JArrayInstance
---@nodiscard
function JArray.object() end

---@generic T
---@param array T
---@return T
---@nodiscard
function JArray.objectWithArray (array) end

---@param size integer
---@return JArrayInstance
---@nodiscard
function JArray.objectWithSize(size) end

---@generic T
---@param ... T...
---@return [T...]
function JArray.objectWithValues(...) end

---`NON-ATOMIC OP`. Returns the elements from the given list. This function is equivalent to
---```lua
---    return list[i], list[i+1], ···, list[j]
---```
---By default, `i` is `1` and `j` is `#list`.
---
---@generic T
---@param list [T...]
---@param i?   integer First unpack index
---@param j?   integer Final unpack index
---@return T...
---@nodiscard
function JArray.unpack(list, i, j) end

---@generic T
---@param optr T[]
---@param idx integer Negative indices count from the end; `-1` is the last item.
---@return T|nil
function JArray.pop(optr, idx) end

---Erase all values equivalent to given `value`. Search use strict value comparison, thus 1.0 ~= 1.
---@param optr JArrayInstance
---@param value Value|nil
---@return integer n_values_erased
function JArray.eraseValues(optr, value) end

---@param optr JArrayInstance
---@param value Value
---@param idx? integer
function JArray.insert(optr, value, idx) end

---@param optr JArrayInstance
---@param idx integer
function JArray.eraseIndex(optr, idx) end

---Search use strict value comparison, thus 1.0 ~= 1
---@param optr JArrayInstance
---@param value Value|nil
---@param start_search_idx? integer negative index causes backward search
---@return integer|nil `nil` if index not found.
---@nodiscard
function JArray.findValue(optr, value, start_search_idx) end

---@param optr JArrayInstance
---@param idx integer only positive index
---@param list Value[]
function JArray.insertTable(optr, idx, list) end

---@param optr JArrayInstance
---@param idx integer only positive index
---@param ... any...
function JArray.insertValues(optr, idx, value1, ...) end

---`IMPORTANT: string values are NOT supported!`
---Reads the inclusive range atomically with respect to this collection.
---@param optr JArrayInstance
---@param idx_first integer
---@param idx_last integer
---@return ...
---@nodiscard
function JArray.getValues(optr, idx_first, idx_last) end

---Writes the inclusive range atomically with respect to this collection.
---@param optr JArrayInstance
---@param idx_first integer
---@param idx_last integer
---@param ... Value
function JArray.setValues(optr, idx_first, idx_last, ...) end

---@param optr JArrayInstance
---@param idx_first integer
---@param idx_last integer
---@return boolean succeed
function JArray.eraseIndexRange(optr, idx_first, idx_last) end

--#endregion

--#region JMap

---@alias JMapInstance { [string]: Value }

---@generic V
---@class JMapInstanceT<V>: { [string]: V }

JMap = {}

JMap.typeName = 'JMap'

---@return JMapInstance object
---@nodiscard
function JMap.object() end

---@generic V
---@param object JMapInstanceT<V>
---@param key string|nil
---@return string|nil, V|Value|nil
---@nodiscard
function JMap.next(optr, key) end

---@generic T
---@param tbl T
---@return T
---@nodiscard
function JMap.objectWithTable(tbl) end

---@param optr JMapInstance
---@return string[] keys
---@nodiscard
function JMap.allKeys(optr) end

---@param optr JMapInstance
---@return JArrayInstance values
---@nodiscard
function JMap.allValues(optr) end

---Assigns the `value` (if current value is nil) OR returns existing value:
--- ```
---  if obj.key == nil then obj.key = value end
---  return obj.key
--- ```
---@generic V
---@param optr JMapInstance
---@param key string nil key cause error (lua table consistency)
---@param value V
---@return V
function JMap.getOrInsert(optr, key, value) end

---Exchanges current value at `key` with `value`. Returns `true` if exchange did happen.
---@generic V
---@param optr JMapInstance
---@param key string nil key cause error (lua table consistency)
---@param value V|nil
---@param read_previous boolean? false by default.
---@return boolean, V|nil
function JMap.exchange(optr, key, value, read_previous) end

---Exchanges `obj[key]` with `new_value` if `obj[key] == comp_value`. Returns `true` if exchange did happen.
---@generic V1, V2
---@param optr JMapInstance
---@param key string nil key cause error (lua table consistency)
---@param comp_value V1
---@param new_value V2
---@return boolean `true` if exchange did happen
function JMap.exchangeIfEqual(optr, key, comp_value, new_value) end

--#endregion

--#region JFormMap

JFormMap = {}

JFormMap.typeName = 'JFormMap'

---@alias JFormMapInstance { [Form]: Value }

---@generic V
---@class JFormMapInstanceT<V>: { [Form]: V }

---@return JFormMapInstance object
---@nodiscard
function JFormMap.object() end

---@generic V
---@param object JFormMapInstanceT<V>
---@param key Form|nil
---@return Form|nil, V|Value|nil
---@nodiscard
function JFormMap.next(optr, key) end

---@param optr JFormMapInstance
---@return Form[] keys
---@nodiscard
function JFormMap.allKeys(optr) end

---@param optr JFormMapInstance
---@return JArrayInstance values
---@nodiscard
function JFormMap.allValues(optr) end

---Assigns the `value` (if current value is nil) OR returns existing value:
--- ```
---  if obj.key == nil then obj.key = value end
---  return obj.key
--- ```
---@generic V
---@param optr JFormMapInstance
---@param key Form nil key cause error (lua table consistency)
---@param value V
---@return V
function JFormMap.getOrInsert(optr, key, value) end

---Exchanges current value at `key` with `value`. Returns `true` if exchange did happen.
---@generic V
---@param optr JFormMapInstance
---@param key Form nil key cause error (lua table consistency)
---@param value V|nil
---@param read_previous boolean? false by default.
---@return boolean, V|nil
function JFormMap.exchange(optr, key, value, read_previous) end

---Exchanges `obj[key]` with `new_value` if `obj[key] == comp_value`. Returns `true` if exchange did happen.
---@generic V1, V2
---@param optr JFormMapInstance
---@param key Form nil key cause error (lua table consistency)
---@param comp_value V1
---@param new_value V2
---@return boolean `true` if exchange did happen
function JFormMap.exchangeIfEqual(optr, key, comp_value, new_value) end

--#endregion

--#region Misc

JModEvent = {}

---@param event_data [string, any...] JArray instance with event name at 1st index.
---@return boolean
function JModEvent.sendEvent (event_data) end
---@param event_name string
---@param event_data any[]|nil JArray instance. Nil means "no args"
---@return boolean
function JModEvent.sendEventWithName(event_name, event_data) end
---@param receiver Form
---@param function_name string
---@param params any[]|nil JArray instance. Nil means "no args"
---@return boolean
function JModEvent.invokeFunction(receiver, function_name, params) end

---@type JMapInstance
JDB = {}

JUtil = {}
---@param text string
function JUtil.printConsole(text) end
---@return integer
function JUtil.aliveObjectCount() end
---For debug/test purposes only!
---@param seconds number
function JUtil.fastForwardTime(seconds) end
---Schedules all Lua contexts for recreation. The current call may finish;
---each context is recreated after it leaves the current execution and is
---entered again.
---Development only. Reload applies to all Lua contexts, not only the caller.
function JUtil.hotReload() end

JString = {}
---@param form Form|nil
---@return string|nil form_string `__formData|ModName.esp|0xAB12`
---@nodiscard
function JString.encodeForm(form) end
---@param form_string string E.g. `__formData|ModName.esp|0xAB12`
---@return Form|nil
---@nodiscard
function JString.decodeStringToForm(form_string) end
---@param plugin_name string
---@param form_id_low integer
---@return Form|nil
---@nodiscard
function JString.decodeForm(plugin_name, form_id_low) end
--#endregion

--#region JAtomic

JAtomic = {}

---Exchanges the object at the `path` with the `other` object. Returns previous object.
---@param object JObjectInstance
---@param path string
---@param other JValue
---@param create_missing_keys? boolean
---@return JObjectInstance
function JAtomic.exchangeObj(object, path, other, create_missing_keys) end

---Exchanges the integer at the `path` with the `other` integer value. Returns previous value.
---@param object JObjectInstance
---@param path string path to the integer
---@param value integer new value
---@param createMissingKeys? boolean false by default
---@param onErrorReturn? integer zero by default
---@return integer previous value
function JAtomic.exchangeInt(object, path, value, createMissingKeys, onErrorReturn) end

---Increments the object's float value at `path` by the `value`. Returns previous value.
---If the value at the `path` is None, then the `initialValue` being read and passed into math function instead of None.
---If `createMissingKeys` is True, the function attemps to create missing @path elements.
---@param object JObjectInstance
---@param path string
---@param value integer
---@param initialValue? integer zero by default
---@param createMissingKeys? boolean false by default
---@param onErrorReturn? integer zero by default
---@return integer
function JAtomic.fetchAddInt(object, path, value, initialValue, createMissingKeys, onErrorReturn) end

---Increments the object's float value at `path` by the `value`. Returns previous value.
---If the value at the `path` is None, then the `initialValue` being read and passed into math function instead of None.
---If `createMissingKeys` is True, the function attemps to create missing @path elements.
---@param object JObjectInstance
---@param path string
---@param value number
---@param initialValue? number zero by default
---@param createMissingKeys? boolean false by default
---@param onErrorReturn? number zero by default
---@return number
function JAtomic.fetchAddFlt(object, path, value, initialValue, createMissingKeys, onErrorReturn) end

--#endregion


---Loads a module through a weak cache. If no other Lua value retains the
---returned module, it may be collected and loaded again by a later call.
---Unlike `require`, a load failure returns `nil` instead of raising an error.
---@param module_path string
---@return any|nil
---@nodiscard
function weak_require(module_path) end

ffi = require 'ffi'
jit = require 'jit'
jit_zone = require 'jit.zone'


---Internal and unstable API. Members may change or disappear without notice
---and are not covered by compatibility guarantees.
JC_Internals = {
    -- Passed into most of `api_for_lua.h` functions as first arg.
    ---@type ffi.cdata*
    LuaContext = nil,
    ---Converts `void*` handle into `JObjectInstance`
    ---@return JObjectInstance
    wrapJCHandle = function (handle) end,
    ---Converts Lua variable into JCValue
    ---@return any
    asJCValue = function (value) end,
    ---Releases `void*` handle. Be careful!
    releaseHandle = function (lua_context, handle) end,
    ---Prints diagnostic information for a JContainers object.
    ---@param object JObjectInstance
    diagnose = function (object) end,
    ---@param module table
    ---@return string|nil
    get_module_path = function(module) end,

    ---Clears the `require` and `weak_require` caches in the current Lua context.
    ---Development only. Prefer `JUtil.hotReload` when the current execution can
    ---return; use this for a long-running loop that cannot leave its Lua context.
    flush_modules = function () end,
}

-- JLockMgr. Provides a way to lock objects.
-- Usage:
--   local ok, result = JLockMgr.pcall(object, f, arg1, arg2, ...)
JLockMgr = {
    ---See the original Lua `pcall`. Wraps the function with lock acquire/release.
    ---@generic T, R, R1
    ---@param obj JObjectInstance
    ---@param f fun(...: T...): R1, R...
    ---@param ... T...
    ---@return boolean, R1|string, R...
    pcall = function (obj, f, ...) end,

    ---See the original Lua `xpcall`. Wraps the function with lock acquire/release.
    ---@generic T, R
    ---@param obj JObjectInstance
    ---@param f fun(...:T...): R...
    ---@param msgh fun(err:string)
    ---@param ... T...
    ---@return boolean, R...
    xpcall = function (obj, f, msgh, ...) end,
}

---Covers missing LuaJIT table functions.
table_util = {}

---@param ... any...
---@return table
---@nodiscard
function table_util.pack(...) end

---@param t table
---@param i integer first index
---@param j integer length
---@return any ...
---@nodiscard
function table_util.unpack_helper (t, i, j) end

---@generic T
---@param t [T...]
---@param i? integer first index
---@param j? integer length
---@return T ...
---@nodiscard
function table_util.unpack(t, i, j) end

--#region Callbacks

JCallback = {}

---The v1 callback. Captures only listed and only primitive values.
---@generic CapturedArgs..., RuntimeArgs...
---@param f fun(...: CapturedArgs..., ...: RuntimeArgs...)
---@param ... CapturedArgs... args to capture
---@return fun(...: RuntimeArgs...) callback flat-packed serialized callback.
---@nodiscard
function JCallback.createV1(f, ...) end

---The v2 callback can capture primitive upvalues and even links to user-modules.
---@generic F: function
---@param f F
---@return F callback flat-packed serialized callback.
---@nodiscard
function JCallback.createV2(f) end

---Callback evaluator. Exposed for testing purposes only. Production callbacks
---are normally evaluated from Papyrus through `JLua_evalLuaCallback` or
---`JLua_evalLuaCallbackAsync`.
---@param callback any
---@param any
function JCallback.evaluate(callback) end

--#endregion
