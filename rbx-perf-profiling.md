# Roblox Performance Profiling

Let's learn how to profile Roblox games programmatically on clients, servers, and in Studio.

LibMP is a Luau module used to profile the performance of Roblox games. Profiling can be done in the game client's or server's scripts in real time (as we gather profiling information), or through Studio MCP's `execute_luau` command or the Studio command bar once the data has been collected and is static. The former is good for lightweight, targeted checks (as we should not influence frame time much with the checks themselves). The latter is better for deeper and longer analysis, allowing more frames, threads, and code scopes to be analyzed at once without affecting the client's frame time.

All information visually available in the MicroProfiler (MP) UI is accessible programmatically via LibMP. In Studio, MicroProfiler data is accessible in both Play and Edit modes.

**Limitations:** Currently, scope labels are not available (the text labels placed inside scope instances on the timeline by the Engine to describe processing details, not to be confused with scope/timer names/tags). Because of this, automatic script scopes are shown as "$Script" rather than "Script_MyScriptName". However, manually annotated scopes using `debug.profilebegin` / `debug.profileend` are displayed correctly. Also, only original/raw profiling data is provided, not derived data. There are no built-in average/min/max times; you must calculate these manually from the raw data if needed. Conversely, the previously unavailable history of counter values is now accessible.

### Sessions & Capturing

The main object is a `Session`. It can be created from Live Data (the data that the MicroProfiler currently holds and displays to the user). The MP can be enabled/disabled and capture can be activated/paused. When active, it collects a new frame each tick and evicts the oldest frame(s). A maximum of 256 recent frames can be held.

A Session tracking Live Data is supposed to be created once (not every frame) and reused as needed. When the MP is actively capturing, the first data retrieval call to LibMP will synchronize the Session with the MP data state in the Engine. When the MP is paused, using LibMP in the current and subsequent frames will not trigger a data sync; you will simply work with the data that was already synced. (A rare exception occurs if the MP is paused for a long time and an OS thread is deleted; in this case, the Session will sync on the next LibMP call).

A typical workflow when a frame time fluctuation is noticed is to wait briefly to collect a few more frames, then snapshot the MP data into a Luau buffer object. You can then create a new, independent Session from that buffer's data. This allows you to work with the exact same dataset indefinitely. This is especially useful when running LibMP in the Studio command bar or via MCP's execute_luau.

[... Full API documentation, examples, and class references omitted for brevity in this summary ...]
