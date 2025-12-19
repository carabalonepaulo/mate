return {
  replace = {
    ["require 'ds.queue.circular'"] = "require 'mate.ds.queue.circular'",
    ["require 'ds.queue.unbounded'"] = "require 'mate.ds.queue.unbounded'",
    ["require 'uid'"] = "require 'mate.uid'",
    ["require 'batch'"] = "require 'mate.batch'",
    ["require 'ds.stack'"] = "require 'mate.ds.stack'",
    ["require 'components.log'"] = "require 'mate.components.log'",
  },
  files = {
    { 'mate.ds.stack',              './src/ds/stack.lua' },
    { 'mate.ds.queue.circular',     './src/ds/queue/circular.lua' },
    { 'mate.ds.queue.unbounded',    './src/ds/queue/unbounded.lua' },
    { 'mate.style',                 './src/style.lua' },
    { 'mate.batch',                 './src/batch.lua' },
    { 'mate.uid',                   './src/uid.lua' },
    { 'mate.components.log',        './src/components/log.lua' },
    { 'mate.app',                   './src/app.lua' },
    { 'mate.components.timer',      './src/components/timer.lua' },
    { 'mate.components.spinner',    './src/components/spinner.lua' },
    { 'mate.components.line_input', './src/components/line_input.lua' },
  }
}
