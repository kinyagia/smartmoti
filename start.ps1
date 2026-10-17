$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $PSScriptRoot
$runtime = Join-Path $PSScriptRoot '.venv\Scripts\python.exe'
if (-not (Test-Path -LiteralPath $runtime)) {
    python -m venv .venv
    if ($LASTEXITCODE -ne 0) { throw 'Could not create the Python environment.' }
}
& $runtime -c 'import jaclang' 2>$null
if ($LASTEXITCODE -ne 0) {
    & $runtime -m pip install --no-deps jaclang==0.16.7
    if ($LASTEXITCODE -ne 0) { throw 'Could not install Jac.' }
}
& $runtime -c 'import cryptography.fernet' 2>$null
if ($LASTEXITCODE -ne 0) {
    & $runtime -m pip install cryptography==50.0.2
    if ($LASTEXITCODE -ne 0) { throw 'Could not install credential encryption.' }
}
& $runtime server.py @args
