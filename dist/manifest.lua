return {
  replace = {
    ["require 'queue.circular'"] = "require 'mate.queue.circular'",
    ["require 'queue.unbounded'"] = "require 'mate.queue.unbounded'",
    ["require 'buffer'"] = "require 'mate.buffer'",
  },
  files = {
    { 'mate.queue.circular',     './src/queue/circular.lua' },
    { 'mate.queue.unbounded',    './src/queue/unbounded.lua' },
    { 'mate.style',              './src/style.lua' },
    { 'mate.batch',              './src/batch.lua' },
    { 'mate.buffer',             './src/buffer.lua' },
    { 'mate.app',                './src/app.lua' },
    { 'mate.components.spinner', './src/components/spinner.lua' },
    { 'mate.components.fps',     './src/components/fps.lua' },
    { 'mate.components.log',     './src/components/log.lua' },
  }
}
