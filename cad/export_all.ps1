<#
  export_all.ps1 — render every braillegen.scad part to STL + a print-readiness report.

  Usage (from this folder):
    .\export_all.ps1
    .\export_all.ps1 -Rings 1 -Coupling heatset -Membrane flat -OutDir .\out
    .\export_all.ps1 -Extra @('-D','tube_id=1.2','-D','tube_od=2.4')

  Any -D override accepted by braillegen.scad can be passed via -Extra.
  Finds OpenSCAD from -OpenSCAD, the OPENSCAD env var, PATH, or the usual install dirs.
#>
param(
  [int]    $Rings    = 2,
  [ValidateSet('barb','heatset')] [string] $Coupling = 'barb',
  [ValidateSet('flat','curved')]  [string] $Membrane = 'curved',
  [string] $OutDir   = "$PSScriptRoot\out",
  [int]    $Fn       = 36,
  [string] $OpenSCAD = '',
  [string[]] $Extra  = @()
)

function Find-OpenSCAD {
  param([string]$Hint)
  $cands = @()
  if ($Hint) { $cands += $Hint }
  if ($env:OPENSCAD) { $cands += $env:OPENSCAD }
  $cmd = Get-Command openscad.com, openscad.exe -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($cmd) { $cands += $cmd.Source }
  $cands += @(
    "$env:ProgramFiles\OpenSCAD\openscad.com",
    "$env:ProgramFiles\OpenSCAD\openscad.exe",
    "${env:ProgramFiles(x86)}\OpenSCAD\openscad.com"
  )
  foreach ($c in $cands) { if ($c -and (Test-Path $c)) { return (Resolve-Path $c).Path } }
  throw "OpenSCAD not found. Install it (https://openscad.org) or pass -OpenSCAD <path to openscad.com>."
}

$exe  = Find-OpenSCAD -Hint $OpenSCAD
$scad = Join-Path $PSScriptRoot 'braillegen.scad'
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

# NOTE: Windows PowerShell 5.1 drops un-escaped quotes when calling a native exe,
# so string-valued -D arguments must carry escaped quotes (\"...\") to reach OpenSCAD
# as string literals rather than bare (undefined) identifiers.
$common = @(
  '-D', "n_rings=$Rings",
  '-D', "coupling=\`"$Coupling\`"",
  '-D', "membrane=\`"$Membrane\`"",
  '-D', "`$fn=$Fn"
) + $Extra

Write-Host "OpenSCAD : $exe"
Write-Host "Config   : rings=$Rings coupling=$Coupling membrane=$Membrane fn=$Fn"
Write-Host "Out      : $OutDir`n"

foreach ($p in @('tip','base','pin_tool','mould_floor','mould_wall')) {
  $stl  = Join-Path $OutDir "$p.stl"
  $pArg = "part=\`"$p\`""
  Write-Host "-> $p.stl ..." -NoNewline
  $callArgs = @('-o', $stl, '-D', $pArg) + $common + @($scad)
  $sw = [Diagnostics.Stopwatch]::StartNew()
  & $exe @callArgs 2>$null | Out-Null
  $sw.Stop()
  if (Test-Path $stl) { Write-Host (" ok  ({0:n0}s, {1:n0} KB)" -f $sw.Elapsed.TotalSeconds, ((Get-Item $stl).Length/1KB)) }
  else { Write-Host " FAILED" -ForegroundColor Red }
}

# print-readiness report: capture the ECHO block from one lightweight render
$report = Join-Path $OutDir 'report.txt'
$rstl   = Join-Path $OutDir '_r.stl'
$rargs  = @('-o', $rstl) + $common + @('-D', 'part=\"tip\"', '-D', '$fn=8', $scad)
$raw    = & $exe @rargs 2>&1 | Out-String
Remove-Item $rstl -ErrorAction SilentlyContinue
$lines  = ($raw -split "`r?`n") | Where-Object { $_ -match 'ECHO:' } |
          ForEach-Object { ($_ -replace '.*ECHO:\s*"?','') -replace '"\s*$','' }
$header = "braillegen print-readiness report  ($(Get-Date -Format s))",
          "config: rings=$Rings  coupling=$Coupling  membrane=$Membrane", ""
($header + $lines) | Set-Content -Encoding utf8 $report

Write-Host "`n--- report.txt ---"
Get-Content $report | Write-Host
Write-Host "`nDone. STLs + report in $OutDir"
