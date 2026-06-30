<#
  make_previews.ps1 — render the STL grid that preview.html switches between.
  9 tips (rings x pitch) + 18 bases (rings x pitch x coupling) = 27 files.
  Then serve this folder and open preview.html, e.g.:  python -m http.server
#>
param([int]$Fn=24, [string]$OpenSCAD='')
$here = $PSScriptRoot; $scad = Join-Path $here 'braillegen.scad'; $out = Join-Path $here 'preview_stl'
if(-not $OpenSCAD){ $OpenSCAD = $env:OPENSCAD }
if(-not $OpenSCAD){ $c = Get-Command openscad.com,openscad.exe -ErrorAction SilentlyContinue | Select-Object -First 1; if($c){$OpenSCAD=$c.Source} }
foreach($p in @("$env:ProgramFiles\OpenSCAD\openscad.com","$env:ProgramFiles\OpenSCAD\openscad.exe")){ if(-not $OpenSCAD -and (Test-Path $p)){$OpenSCAD=$p} }
if(-not $OpenSCAD){ throw "OpenSCAD not found. Pass -OpenSCAD <path to openscad.com>." }
New-Item -ItemType Directory -Force -Path $out | Out-Null

foreach($r in 1,2,3){ foreach($p in '2.0','2.5','3.0'){
  $pp = $p -replace '\.',''
  Write-Host "tip r$r p$p"
  & $OpenSCAD -o (Join-Path $out "tip_r${r}_p${pp}.stl") -D 'part="tip"' -D "n_rings=$r" -D "pitch=$p" -D "`$fn=$Fn" $scad 2>$null | Out-Null
  foreach($c in 'barb','heatset'){
    Write-Host "base r$r p$p $c"
    & $OpenSCAD -o (Join-Path $out "base_r${r}_p${pp}_${c}.stl") -D 'part="base"' -D "n_rings=$r" -D "pitch=$p" -D "coupling=\`"$c\`"" -D "`$fn=$Fn" $scad 2>$null | Out-Null
  }
}}
Write-Host ("done -> {0} ({1} files)" -f $out, (Get-ChildItem $out -Filter *.stl).Count)
