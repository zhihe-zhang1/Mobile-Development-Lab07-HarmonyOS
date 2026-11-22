$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$outdir = Join-Path $root 'release'
New-Item -ItemType Directory -Force -Path $outdir | Out-Null
$stage = Join-Path $env:TEMP ('lab07-source-' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $stage | Out-Null
try {
  $items = @('AppScope','entry','hvigor','oh-package.json5','build-profile.json5',
    'hvigorfile.ts','code-linter.json5','.gitignore','README.md',
    'docs','contracts','screenshots','tests','scripts','.github')
  foreach ($item in $items) {
    $from = Join-Path $root $item
    if (Test-Path $from) { Copy-Item -Path $from -Destination $stage -Recurse -Force }
  }
  Get-ChildItem -Path $stage -Recurse -Directory |
    Where-Object { $_.Name -in @('build','.hvigor','node_modules','.idea') } |
    Sort-Object FullName -Descending |
    ForEach-Object { Remove-Item $_.FullName -Recurse -Force }
  $zip = Join-Path $outdir 'Lab07-source.zip'
  if (Test-Path $zip) { Remove-Item $zip -Force }
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  [System.IO.Compression.ZipFile]::CreateFromDirectory($stage, $zip)
  Write-Host "Source package: $zip"
} finally {
  if (Test-Path $stage) { Remove-Item $stage -Recurse -Force }
}
