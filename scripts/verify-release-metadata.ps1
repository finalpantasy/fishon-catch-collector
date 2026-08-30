param(
    [string]$ExpectedTag = ""
)

$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$propertiesPath = Join-Path $projectRoot 'gradle.properties'
$fabricPath = Join-Path $projectRoot 'src/main/resources/fabric.mod.json'
$updatePath = Join-Path $projectRoot 'update.json'

$properties = Get-Content -LiteralPath $propertiesPath
$versionLine = $properties | Where-Object { $_ -match '^mod_version=' } | Select-Object -First 1
$minecraftLine = $properties | Where-Object { $_ -match '^minecraft_version=' } | Select-Object -First 1
if (-not $versionLine -or -not $minecraftLine) {
    throw 'gradle.properties is missing release identity fields.'
}

$version = ($versionLine -split '=', 2)[1].Trim()
$minecraftVersion = ($minecraftLine -split '=', 2)[1].Trim()
$fabric = Get-Content -LiteralPath $fabricPath -Raw | ConvertFrom-Json
$updates = Get-Content -LiteralPath $updatePath -Raw | ConvertFrom-Json
$release = $updates.channels.stable.$minecraftVersion

if ($fabric.id -ne 'fishon-catch-collector') { throw 'Unexpected Fabric mod id.' }
if ($fabric.version -ne '${version}') { throw 'Fabric version must be expanded from Gradle.' }
if ($fabric.environment -ne 'client') { throw 'Collector must remain client-only.' }
if ($fabric.contact.sources -ne 'https://github.com/finalpantasy/fishon-catch-collector') {
    throw 'Fabric source URL does not match the public repository.'
}
if ($updates.schemaVersion -ne 1 -or $updates.modId -ne $fabric.id) {
    throw 'Update document identity is invalid.'
}
if (-not $release -or $release.version -ne $version) {
    throw 'Update document version does not match Gradle.'
}
$expectedUrl = "https://github.com/finalpantasy/fishon-catch-collector/releases/tag/v$version"
if ($release.releaseUrl -ne $expectedUrl) {
    throw 'Update release URL does not match the version.'
}
if ($ExpectedTag -and $ExpectedTag -ne "v$version") {
    throw "Tag $ExpectedTag does not match v$version."
}

Write-Output "Release metadata verified: v$version for Minecraft $minecraftVersion"
