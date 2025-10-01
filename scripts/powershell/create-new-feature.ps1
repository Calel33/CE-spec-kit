#!/usr/bin/env pwsh
# Create a new Context Engineering Kit feature
[CmdletBinding()]
param(
    [switch]$Json,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$FeatureDescription
)
$ErrorActionPreference = 'Stop'

if (-not $FeatureDescription -or $FeatureDescription.Count -eq 0) {
    Write-Error "Usage: ./create-new-feature.ps1 [-Json] <feature description>"
    exit 1
}
$featureDesc = ($FeatureDescription -join ' ').Trim()

. (Join-Path $PSScriptRoot 'common.ps1')

$repoRoot = ([string](Get-RepoRoot)).Trim()
$workflow = ([string](Get-Workflow -RepoRoot $repoRoot)).Trim()
$hasGit = Test-HasGit
Set-Location $repoRoot

$highest = 0
if ($hasGit) {
    git for-each-ref --format='%(refname:short)' refs/heads | ForEach-Object {
        if ($_ -match '^(\d{3})-') {
            $num = [int]$matches[1]
            if ($num -gt $highest) { $highest = $num }
        }
    }
}

if ($highest -eq 0) {
    $candidateDirs = @(
        [System.IO.Path]::Combine($repoRoot, 'specs'),
        [System.IO.Path]::Combine($repoRoot, 'context-eng', 'prp'),
        [System.IO.Path]::Combine($repoRoot, 'context-eng', 'all-in-one')
    )
    foreach ($dir in $candidateDirs) {
        if (-not (Test-Path $dir)) { continue }
        Get-ChildItem -Path $dir -Directory | ForEach-Object {
            if ($_.Name -match '^(\d{3})-') {
                $num = [int]$matches[1]
                if ($num -gt $highest) { $highest = $num }
            }
        }
    }
}

$next = $highest + 1
$featureNum = ('{0:000}' -f $next)

$slug = $featureDesc.ToLower() -replace '[^a-z0-9]', '-' -replace '-{2,}', '-' -replace '^-', '' -replace '-$', ''
$words = ($slug -split '-') | Where-Object { $_ } | Select-Object -First 3
if (-not $words) { $words = @('feature') }
$branchName = "$featureNum-$([string]::Join('-', $words))"

if ($hasGit) {
    try {
        git checkout -b $branchName | Out-Null
    } catch {
        Write-Warning "Failed to create git branch: $branchName"
    }
} else {
    Write-Warning "[cek] Warning: Git repository not detected; skipped branch creation for $branchName"
}

$contextDir = [System.IO.Path]::Combine($repoRoot, '.context-eng')
$checklistTemplate = [System.IO.Path]::Combine($contextDir, 'checklists', 'full-implementation-checklist.md')

$featureDir = $null
$primaryTemplate = $null
$primaryFile = $null
$planFile = $null
$researchFile = $null
$tasksFile = $null
$prpFile = $null
$initialFile = $null

switch ($workflow) {
    'free-style' {
        $featureDir = [System.IO.Path]::Combine($repoRoot, 'specs', $branchName)
        $primaryTemplate = [System.IO.Path]::Combine($contextDir, 'workflows', 'free-style', 'templates', 'context-spec-template.md')
        $primaryFile = [System.IO.Path]::Combine($featureDir, 'context-spec.md')
        $planFile = [System.IO.Path]::Combine($featureDir, 'plan.md')
        $researchFile = [System.IO.Path]::Combine($featureDir, 'research.md')
        $tasksFile = [System.IO.Path]::Combine($featureDir, 'tasks.md')
    }
    'prp' {
        $featureDir = [System.IO.Path]::Combine($repoRoot, 'context-eng', 'prp', $branchName)
        $primaryTemplate = [System.IO.Path]::Combine($contextDir, 'workflows', 'prp', 'templates', 'initial-template.md')
        $primaryFile = [System.IO.Path]::Combine($repoRoot, 'PRPs', 'INITIAL.md')
        $prpFile = [System.IO.Path]::Combine($repoRoot, 'PRPs', "$branchName.md")
        $planFile = [System.IO.Path]::Combine($featureDir, 'plan.md')
        $researchFile = [System.IO.Path]::Combine($featureDir, 'research.md')
        $tasksFile = [System.IO.Path]::Combine($featureDir, 'tasks.md')
        $initialFile = $primaryFile
    }
    'all-in-one' {
        $featureDir = [System.IO.Path]::Combine($repoRoot, 'context-eng', 'all-in-one', $branchName)
        $primaryTemplate = [System.IO.Path]::Combine($contextDir, 'workflows', 'all-in-one', 'templates', 'all-in-one-template.md')
        $primaryFile = [System.IO.Path]::Combine($featureDir, 'record.md')
        $planFile = [System.IO.Path]::Combine($featureDir, 'plan.md')
        $researchFile = [System.IO.Path]::Combine($featureDir, 'research.md')
        $tasksFile = [System.IO.Path]::Combine($featureDir, 'tasks.md')
    }
    default {
        $featureDir = [System.IO.Path]::Combine($repoRoot, 'specs', $branchName)
        $primaryTemplate = [System.IO.Path]::Combine($contextDir, 'workflows', 'free-style', 'templates', 'context-spec-template.md')
        $primaryFile = [System.IO.Path]::Combine($featureDir, 'context-spec.md')
        $planFile = [System.IO.Path]::Combine($featureDir, 'plan.md')
        $researchFile = [System.IO.Path]::Combine($featureDir, 'research.md')
        $tasksFile = [System.IO.Path]::Combine($featureDir, 'tasks.md')
    }
}

New-Item -ItemType Directory -Path $featureDir -Force | Out-Null
[System.IO.Directory]::CreateDirectory((Split-Path $primaryFile -Parent)) | Out-Null
[System.IO.Directory]::CreateDirectory((Split-Path $planFile -Parent)) | Out-Null
[System.IO.Directory]::CreateDirectory((Split-Path $researchFile -Parent)) | Out-Null
[System.IO.Directory]::CreateDirectory((Split-Path $tasksFile -Parent)) | Out-Null

if ($workflow -eq 'prp') {
    [System.IO.Directory]::CreateDirectory((Split-Path $prpFile -Parent)) | Out-Null
    $prpTemplate = [System.IO.Path]::Combine($contextDir, 'workflows', 'prp', 'templates', 'prp-template.md')
    if ((-not (Test-Path $prpFile)) -and (Test-Path $prpTemplate)) {
        Copy-Item $prpTemplate $prpFile
    }
}

if ((Test-Path $primaryTemplate) -and (-not (Test-Path $primaryFile))) {
    Copy-Item $primaryTemplate $primaryFile
} elseif (-not (Test-Path $primaryFile)) {
    New-Item -ItemType File -Path $primaryFile | Out-Null
}

$env:CONTEXT_FEATURE = $branchName
$env:SPECIFY_FEATURE = $branchName

$output = [ordered]@{
    BRANCH_NAME = $branchName
    FEATURE_NUM = $featureNum
    WORKFLOW = $workflow
    PRIMARY_FILE = $primaryFile
    TEMPLATE_FILE = $primaryTemplate
    FEATURE_DIR = $featureDir
    PLAN_FILE = $planFile
    RESEARCH_FILE = $researchFile
    TASKS_FILE = $tasksFile
    PRP_FILE = $prpFile
    INITIAL_FILE = $initialFile
    CHECKLIST_TEMPLATE = $checklistTemplate
}

if ($Json) {
    [PSCustomObject]$output | ConvertTo-Json -Compress
} else {
    $output.GetEnumerator() | ForEach-Object {
        if ($_.Value) { Write-Output "$($_.Key): $($_.Value)" }
    }
    Write-Output "CONTEXT_FEATURE environment variable set to: $branchName"
}
