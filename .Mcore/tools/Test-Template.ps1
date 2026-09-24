param()
$ErrorActionPreference = 'Stop'
$coreRoot = Split-Path -Parent $PSScriptRoot
$scripts = @(Get-ChildItem -LiteralPath $coreRoot -Recurse -Filter *.ps1 -File)
foreach ($script in $scripts) {
    $tokens = $null; $errors = $null
    [void][Management.Automation.Language.Parser]::ParseFile($script.FullName, [ref]$tokens, [ref]$errors)
    if ($errors.Count) { throw ($errors | Out-String) }
}
. (Join-Path $PSScriptRoot 'Skills.ps1')
$catalog = @(Get-McoreSkills)
$routing = Get-Content (Join-Path $coreRoot 'skills-routing.json') -Raw | ConvertFrom-Json
foreach ($rule in $routing.rules) {
    if ($rule.folder -notin $catalog.folder) { throw "Missing routed skill: $($rule.folder)" }
    if ($rule.pattern) { [void][regex]::new($rule.pattern) }
}
foreach ($file in @(Get-ChildItem -LiteralPath $coreRoot -Recurse -File -Filter *.json)) {
    [void](Get-Content -LiteralPath $file.FullName -Raw | ConvertFrom-Json)
}
foreach ($name in @('state.json','team.json','.login.json','.vault-key.dpapi','project-vault.json')) {
    if (Test-Path -LiteralPath (Join-Path $coreRoot $name)) { throw "Template contains live state: $name" }
}
foreach ($name in @('.runtime','users','project-events')) {
    $path = Join-Path $coreRoot $name
    if (Test-Path -LiteralPath $path) {
        if (@(Get-ChildItem -LiteralPath $path -Recurse -Force -File).Count) { throw "Template contains runtime data: $name" }
    }
}
[pscustomobject]@{ passed = $true; scripts = $scripts.Count; skills = $catalog.Count; template_clean = $true } | ConvertTo-Json
