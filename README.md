# mate

**mate** is a terminal UI (TUI) framework for Lua inspired by the Elm
Architecture and heavily influenced by
[Bubble Tea](https://github.com/charmbracelet/bubbletea) in the Go ecosystem.

If you know Bubble Tea, the mental model is the same: **immutable-ish state**,
**message-driven updates**, and **pure views** rendered to a terminal buffer.
The difference is that mate is designed for Lua, embraces Lua’s strengths, and
avoids unnecessary abstractions.

mate is intentionally small. What you see in the examples is essentially the
entire framework.

---

## Core Concepts

mate applications are built around three functions:

- **init** → returns the initial model (state)
- **update** → receives the current model and a message, returns a new model and
  a command
- **view** → renders the model into a terminal buffer

Everything in mate — including components — follows this same structure.

---

## Architecture Overview

- **Model**: Anything.
- **Messages**: `{ id = 'message_unique_id', data = ... }`.
- **Update Loop**: A single event loop that routes messages through `update`.
- **Commands**: Side effects are expressed as messages, optionally batched.
- **View**: Writes directly to a terminal buffer abstraction.

mate does not try to hide the terminal from you. It gives you tools and stays
out of the way.

---

## Installation

mate has exactly **one dependency**:

- **term** — a terminal abstraction library written by the same author,
  implemented as a wrapper around `crossterm`.

### Using the bundled build

mate ships with a fully bundled build at:

```
/dist/out.lua
```

To use mate:

1. Place `out.lua` somewhere accessible in your Lua project
2. Place the `term` library in your `package.cpath`
3. `require` the bundle, to allow `mate` file to be required
4. `require` mate and start using it

No package manager is required.

Minimal setup used on examples (mate expects term to be availble as
`require 'term'`):

```lua
package.cpath = package.cpath .. ';' .. './bin/?.dll'
require 'dist.out'
```

---

## Minimal Application Example

```lua
local App = require 'mate.app'

App {
  init = function()
    return 0
  end,

  update = function(model, msg)
    if msg.id == 'key' then
      if msg.data.code == 'q' or (msg.data.code == 'c' and msg.data.ctrl) then
        return model, { id = 'quit' }
      elseif msg.data.code == 'enter' and msg.data.kind == 'press' then
        model = model + 1
      end
    end
    return model, nil
  end,


  view = function(model, buf)
    buf.write('Count: ' .. model)
  end
}
```

This is the entire application lifecycle.

---

## Components

Components in mate are **not special**. A component is simply a table with:

- `init`
- `update`
- `view`

Each component owns its own state and is identified by a **unique ID** so
messages can be routed safely.

### Key properties of components

- No inheritance
- No framework-managed lifecycle
- No implicit coupling

If it fits in a Lua table, it fits in mate.

---

## Example: Text Component

A simple component that stores and renders text:

```lua
Text = {
  init = function()
    return {
      uid = uid(),
      text = ''
    }
  end,

  update = function(model, msg)
    if msg.id == 'text:set' and msg.data.uid == model.uid then
      model.text = msg.data.text
    end
    return model, nil
  end,

  view = function(model, buf)
    buf.write(model.text)
  end
}
```

The parent application decides **when** and **how** messages are sent. The
component only reacts to messages addressed to its `uid`.

---

## Commands and Batching

Side effects are represented as messages.

To emit multiple commands from an update, use `Batch`:

```lua
local batch = Batch()
batch.push(cmd1)
batch.push(cmd2)
return model, batch
```

This keeps the update function predictable and testable.

---

## Example: Spinner Component

The spinner demonstrates timed updates, internal state, and message recursion:

- It schedules its own `tick` messages
- It updates based on elapsed time
- It renders a single frame per view call

This pattern replaces threads, timers, and callbacks with explicit state
transitions.

---

## Input Handling

mate does not impose an input model.

Keyboard events arrive as messages (e.g. `msg.id == 'key'`). You decide:

- Which keys matter
- How they map to state transitions
- Whether they trigger commands

This keeps input handling transparent and debuggable.

---

## Rendering

Rendering is done through a **terminal buffer** provided by `term`.

You can:

- Write text
- Move the cursor
- Apply styles
- Reset styles explicitly

---

## Design Goals

mate is built with the following constraints:

- Minimal API surface
- No hidden control flow
- No implicit global state
- No forced abstractions

If you need structure, you build it yourself. If you don’t, mate won’t force it
on you.

---

## When to Use mate

mate is a good fit if you want:

- Full control over terminal rendering
- A predictable event loop
- Explicit state transitions
- A Bubble Tea–style architecture in Lua

If you want batteries included, mate is probably not what you are looking for.

---

## Summary

mate is a small, explicit, message-driven TUI framework for Lua.

If you understand the examples, you understand the library.
