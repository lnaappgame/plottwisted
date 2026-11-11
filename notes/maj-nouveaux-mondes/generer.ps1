# Génère mondes-maj.dart.txt (blocs GameWorld/Puzzle au format de lib/data/puzzles_data.dart) depuis contenu-mondes.json.
# Contrôles : réponse ≤ 29 lettres et chiffres (titre + nom de l'enfant star) en FR et en US ; {p2} présent si et seulement si p2 rempli ;
# pitch « Pitch express » ≤ 10 mots ; aucun champ vide. Usage : powershell -File notes\maj-nouveaux-mondes\generer.ps1
$ErrorActionPreference = 'Stop'
$dir = Split-Path -Parent $MyInvocation.MyCommand.Path
$j = [IO.File]::ReadAllText((Join-Path $dir 'contenu-mondes.json'), [Text.Encoding]::UTF8) | ConvertFrom-Json
function Q([string]$s) { "'" + ($s -replace '\\', '\\' -replace "'", "\'" -replace '\$', '\$') + "'" }
function Letters([string]$s) { ([regex]::Matches($s, '[\p{L}\p{N}]')).Count }
function Words([string]$s) { ($s -split '\s+' | Where-Object { $_ -match '[\p{L}\p{N}{]' }).Count }
$out = New-Object Text.StringBuilder
$warn = @()
function Person($a, [string]$label) {
  $n = 'real', 'realUs', 'actor', 'actorUs', 'decoy', 'decoyUs', 'decoyFilm', 'decoyFilmUs'
  $s = "    ${label}: PersonRef(`n"
  for ($i = 0; $i -lt 8; $i++) { $v = if ($a) { [string]$a[$i] } else { '' }; $s += "      $($n[$i]): $(Q $v),`n" }
  foreach ($k in 'sameRoleActor', 'sameRoleActorUs', 'sameRoleFilm', 'sameRoleFilmUs', 'violet', 'violetUs') { $s += "      ${k}: '',`n" }
  $s + "    ),`n"
}
[void]$out.Append("// MAJ « nouveaux mondes » : contenu préparé par PT créateur, généré depuis contenu-mondes.json le $(Get-Date -Format 'dd/MM/yyyy HH:mm').`n")
[void]$out.Append("// À coller dans lib/data/puzzles_data.dart par PT prime. Mondes 31 à 35 (ordre validé par Damien le 11/11).`n")
[void]$out.Append("// extraAnswer / extraAnswerUs : champs à créer (notes/maj-enfants-stars-structure-2026-11-11.md).`n`n")
foreach ($w in $j.worlds) {
  [void]$out.Append("  GameWorld(number: $($w.number), categoryLabel: $(Q $w.label), categoryLabelUs: $(Q $w.labelUs), puzzles: [`n")
  $lvl = 0
  foreach ($p in $w.puzzles) {
    $lvl++; $id = "$($w.label) n° $lvl ($($p.title))"
    foreach ($f in 'title', 'titleUs', 'year', 'pitch', 'pitchUs', 'hint', 'hintUs', 'note', 'noteUs') { if (-not $p.$f) { $warn += "$id : champ $f vide" } }
    $fr = (Letters $p.title) + (Letters $p.extra); $en = (Letters $p.titleUs) + (Letters $p.extraUs)
    # Seule exception autorisée (Damien, 11/11) : ENTRETIEN AVEC UN VAMPIRE + KIRSTEN DUNST = 34 / 35, grille testée par PT prime sur petit téléphone.
    $max = if ($p.title -eq 'ENTRETIEN AVEC UN VAMPIRE') { 35 } else { 29 }
    if ($fr -gt $max -or $en -gt $max) { $warn += "$id : réponse trop longue ($fr FR / $en US, maximum $max)" }
    $hasP2 = [bool]$p.p2
    foreach ($t in $p.pitch, $p.pitchUs) {
      if ($t -notmatch '\{p1\}') { $warn += "$id : {p1} absent" }
      if (($t -match '\{p2\}') -ne $hasP2) { $warn += "$id : {p2} et p2 ne concordent pas" }
      if ($w.label -eq 'Pitch express' -and (Words $t) -gt 10) { $warn += "$id : pitch de $(Words $t) mots" }
    }
    foreach ($pp in @($p.p1) + $(if ($hasP2) { , $p.p2 } else { @() })) { }
    if ($p.p1[4] -eq '' -or ($hasP2 -and $p.p2[4] -eq '')) { $warn += "$id : piège rouge vide" }
    $q = $p.title + ' film allocine'
    [void]$out.Append("    Puzzle(`n")
    [void]$out.Append("    title: $(Q $p.title),`n    titleUs: $(Q $p.titleUs),`n")
    if ($p.extra) { [void]$out.Append("    extraAnswer: $(Q $p.extra),`n    extraAnswerUs: $(Q $p.extraUs),`n") }
    [void]$out.Append("    year: $(Q $p.year),`n")
    [void]$out.Append("    pitchTemplate: $(Q $p.pitch),`n    pitchTemplateUs: $(Q $p.pitchUs),`n")
    [void]$out.Append("    allocineUrl: $(Q ('https://www.google.com/search?q=' + [uri]::EscapeDataString($q))),`n")
    [void]$out.Append("    imdbUrl: $(Q ('https://www.imdb.com/find/?q=' + [uri]::EscapeDataString($p.titleUs + ' ' + $p.year))),`n")
    [void]$out.Append("    extraHint: $(Q $p.hint),`n    extraHintUs: $(Q $p.hintUs),`n")
    [void]$out.Append("    revealNote: $(Q $p.note),`n    revealNoteUs: $(Q $p.noteUs),`n")
    [void]$out.Append("    p1InitialColor: NameColor.red,`n    p2InitialColor: NameColor.$(if ($hasP2) { 'red' } else { 'green' }),`n")
    [void]$out.Append((Person $p.p1 'p1'))
    [void]$out.Append((Person $(if ($hasP2) { $p.p2 } else { $null }) 'p2'))
    [void]$out.Append("  ),`n")
  }
  [void]$out.Append("  ]),`n")
}
[IO.File]::WriteAllText((Join-Path $dir 'mondes-maj.dart.txt'), $out.ToString(), (New-Object Text.UTF8Encoding $false))
"Mondes : $($j.worlds.Count) ; niveaux : $(($j.worlds | ForEach-Object { $_.puzzles.Count } | Measure-Object -Sum).Sum)"
if ($warn) { "ALERTES :"; $warn } else { "Aucune alerte." }
