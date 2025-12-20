param (
    [Parameter(Mandatory=$false)]
    [string]$dest
)

luajit .\dist\bundler.lua -f:text -m:dist.manifest
Move-Item -Path './out.lua' -Destination './dist/out.lua' -Force

if ($PSBoundParameters.ContainsKey('dest')) {
    Copy-Item -Path './dist/out.lua' -Destination $dest -Force
}