param (
    [Parameter(Mandatory=$true)]
    [int]$num
)

luajit .\dist\bundler.lua -f:text -m:dist.manifest
Move-Item -Path './out.lua' -Destination './dist/out.lua' -Force
luajit -l examples.setup "./examples/$num.lua"