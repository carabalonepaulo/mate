return {
  replace = {
    ["require 'queue.circular'"] = "require 'mate.queue.circular'",
    ["require 'queue.unbounded'"] = "require 'mate.queue.unbounded'",
    ["require 'uid'"] = "require 'mate.uid'",
    ["require 'components.log'"] = "require 'mate.components.log'",
  },
  files = {
    { 'mate.queue.circular',        './src/queue/circular.lua' },
    { 'mate.queue.unbounded',       './src/queue/unbounded.lua' },
    { 'mate.style',                 './src/style.lua' },
    { 'mate.batch',                 './src/batch.lua' },
    { 'mate.uid',                   './src/uid.lua' },
    { 'mate.components.log',        './src/components/log.lua' },
    { 'mate.app',                   './src/app.lua' },
    { 'mate.components.spinner',    './src/components/spinner.lua' },
    { 'mate.components.line_input', './src/components/line_input.lua' },
  }
}
