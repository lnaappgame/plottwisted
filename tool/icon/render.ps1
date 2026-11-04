# Rend les sources SVG de l'icône en PNG 1024x1024 (Chrome headless, police Bebas Neue
# chargée depuis Google Fonts), puis : `dart run flutter_launcher_icons`
#   powershell -File tool/icon/render.ps1
$ErrorActionPreference = 'Stop'
$here = $PSScriptRoot
$assets = Join-Path $here '..\..\assets\icon' | Resolve-Path
$chrome = 'C:\Program Files (x86)\Google\Chrome\Application\chrome.exe'
$tmp = Join-Path $env:TEMP 'plottwisted-icon'
New-Item -ItemType Directory -Force $tmp | Out-Null
$font = '<link href="https://fonts.googleapis.com/css2?family=Bebas+Neue&display=swap" rel="stylesheet">'

# Nom de la source, transparence du fond.
$sources = @(
  @{ name = 'icon'; transparent = $false },
  @{ name = 'icon_foreground'; transparent = $true },
  @{ name = 'icon_monochrome'; transparent = $true }
)
foreach ($s in $sources) {
  $svg = [IO.File]::ReadAllText((Join-Path $here "$($s.name).svg"))
  $html = "<!doctype html><html><head><meta charset=`"utf-8`">$font<style>html,body{margin:0;background:transparent}svg{display:block}</style></head><body>$svg</body></html>"
  $page = Join-Path $tmp "$($s.name).html"
  [IO.File]::WriteAllText($page, $html, (New-Object Text.UTF8Encoding $false))
  $png = Join-Path $assets "$($s.name).png"
  $args = @('--headless=new', '--disable-gpu', '--hide-scrollbars', '--no-first-run', "--user-data-dir=$tmp\profile",
    '--force-device-scale-factor=1', '--window-size=1024,1024', '--virtual-time-budget=10000', "--screenshot=$png")
  if ($s.transparent) { $args += '--default-background-color=00000000' }
  $args += "file:///$($page -replace '\\','/')"
  Start-Process -FilePath $chrome -ArgumentList $args -Wait -WindowStyle Hidden
  "$($s.name).png"
}
