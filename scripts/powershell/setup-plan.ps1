#!/usr/bin/env pwsh
[CmdletBinding(DefaultParameterSetName="Default")]
param(
    [switch]$Json,
    [switch]$Help
)

$ErrorActionPreference = 'Stop'
$setupScript = Join-Path $PSScriptRoot 'context-plan-setup.ps1'

if ($Help) {
    & $setupScript -Help
    exit 0
}

$forwardArgs = @()
if ($Json) { $forwardArgs += '-Json' }

& $setupScript @forwardArgs
