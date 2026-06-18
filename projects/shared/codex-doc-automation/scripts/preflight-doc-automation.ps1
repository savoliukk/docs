[CmdletBinding()]
param(
    [string]$DocsRoot = "C:\work\docs",
    [string]$SCDocsRoot = "C:\work\SCDocs"
)

$ErrorActionPreference = "Stop"

function Convert-ToSafeDirectoryPath {
    param([Parameter(Mandatory = $true)][string]$Path)
    return ($Path -replace "\\", "/")
}

function Write-Section {
    param([Parameter(Mandatory = $true)][string]$Title)
    Write-Host ""
    Write-Host "## $Title"
}

function Get-Route {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [string]$Path
    )

    $lower = $Name.ToLowerInvariant()
    $sample = ""

    if ($Path -and (Test-Path -LiteralPath $Path) -and ([System.IO.Path]::GetExtension($Path) -ieq ".md")) {
        try {
            $sample = (Get-Content -LiteralPath $Path -TotalCount 80 -ErrorAction SilentlyContinue) -join "`n"
        } catch {
            $sample = ""
        }
    }

    $combined = "$lower`n$($sample.ToLowerInvariant())"

    if ($combined -match "firegw|fireudp|udpnew|externaltrafficpolicy|metallb|nodeport|device-facing udp|udp device|l4 surface|mikrotik.*dst-nat") {
        return "tirascloud-2/udp-edge-exposure"
    }

    if ($lower -match "runbook.*tirascloud|software supply chain") {
        return "tirascloud-2/app-ci-cd"
    }

    if ($lower -match "nist|owasp|cis|security|access|secrets|blueprint|discovery") {
        return "shared/security-governance"
    }

    if ($combined -match "sbom|provenance") {
        return "tirascloud-2/app-ci-cd"
    }

    if ($lower -match "sc_infrastructure|service center|scnet|vpn|sc_vpn") {
        return "service-center/gitops-docs"
    }

    if ($lower -match "workflow|iac|gitops|infracluster|infrafoundation|helm|rollback|kubectl|kubeadm|microk8s|observability|redis|minio|percona") {
        return "tirascloud-gitops-or-platform"
    }

    if ($lower -match "jira") {
        return "shared/process-management"
    }

    if ($combined -match "nist|owasp|cis|security|access|secrets|blueprint|discovery|shared password|credential|privileged|cyberark|hashicorp|boundary|ztna|zero trust") {
        return "shared/security-governance"
    }

    if ($combined -match "sc_infrastructure|service center|scnet|vpn|sc_vpn") {
        return "service-center/gitops-docs"
    }

    if ($combined -match "workflow|iac|gitops|infracluster|infrafoundation|helm|rollback|kubectl|kubeadm|microk8s|observability|redis|minio|percona") {
        return "tirascloud-gitops-or-platform"
    }

    return "shared/triage-needed"
}

function Invoke-GitStatus {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        Write-Host "- ${Name}: missing ($Path)"
        return
    }

    $safePath = Convert-ToSafeDirectoryPath -Path $Path
    $status = & git -c "safe.directory=$safePath" -C $Path status --short 2>&1

    if ($LASTEXITCODE -ne 0) {
        Write-Host "- ${Name}: git status failed"
        $status | ForEach-Object { Write-Host "  $_" }
        return
    }

    if ($status.Count -eq 0) {
        Write-Host "- ${Name}: clean"
        return
    }

    Write-Host "- ${Name}: dirty"
    $status | ForEach-Object { Write-Host "  $_" }
}

$processRoot = Join-Path $DocsRoot "process"
$projectsRoot = Join-Path $DocsRoot "projects"

Write-Section "Read-only preflight"
Write-Host "Docs root: $DocsRoot"
Write-Host "Process inbox: $processRoot"
Write-Host "Projects root: $projectsRoot"
Write-Host "SCDocs root: $SCDocsRoot"

Write-Section "Git status"
$repos = @(
    @{ Name = "docs"; Path = $DocsRoot },
    @{ Name = "SCDocs"; Path = $SCDocsRoot },
    @{ Name = "ideal-octo-giggle"; Path = "C:\work\ideal-octo-giggle" },
    @{ Name = "TirasCloud-2"; Path = "C:\work\TirasCloud-2" },
    @{ Name = "SCNet"; Path = "C:\work\SCNet" },
    @{ Name = "SCNode"; Path = "C:\work\SCNode" },
    @{ Name = "SCInfrastructure"; Path = "C:\work\SCInfrastructure" }
)

foreach ($repo in $repos) {
    Invoke-GitStatus -Name $repo.Name -Path $repo.Path
}

Write-Section "Process inbox routing"
if (-not (Test-Path -LiteralPath $processRoot)) {
    Write-Host "Process inbox is missing."
    exit 1
}

$processFiles = Get-ChildItem -LiteralPath $processRoot -File | Sort-Object Name
Write-Host "Files found: $($processFiles.Count)"
Write-Host ""
Write-Host "| File | Route | Size |"
Write-Host "| --- | --- | ---: |"
foreach ($file in $processFiles) {
    $route = Get-Route -Name $file.Name -Path $file.FullName
    Write-Host "| $($file.Name) | $route | $($file.Length) |"
}

Write-Section "Potential SCDocs duplicates"
if (-not (Test-Path -LiteralPath $SCDocsRoot)) {
    Write-Host "SCDocs root is missing."
} else {
    $scdocsFiles = Get-ChildItem -LiteralPath $SCDocsRoot -Recurse -File
    $duplicateCount = 0

    foreach ($file in $processFiles) {
        $sameName = $scdocsFiles | Where-Object { $_.Name -eq $file.Name }
        if ($sameName.Count -gt 0) {
            $duplicateCount += $sameName.Count
            foreach ($match in $sameName) {
                Write-Host "- $($file.Name) -> $($match.FullName)"
            }
        }
    }

    if ($duplicateCount -eq 0) {
        Write-Host "No exact same-name duplicates found."
    }
}

Write-Section "Secret-risk wording scan"
$markdownFiles = $processFiles | Where-Object { $_.Extension -ieq ".md" }
$secretPatterns = @(
    "password",
    "passwd",
    "token",
    "secret",
    "private key",
    "BEGIN .*PRIVATE KEY",
    "api[_-]?key",
    "client_secret"
)

if ($markdownFiles.Count -eq 0) {
    Write-Host "No markdown files to scan."
} else {
    $hits = Select-String -LiteralPath $markdownFiles.FullName -Pattern $secretPatterns -AllMatches -ErrorAction SilentlyContinue
    if ($null -eq $hits -or $hits.Count -eq 0) {
        Write-Host "No secret-risk wording found."
    } else {
        $hits | Group-Object Path | Sort-Object Name | ForEach-Object {
            Write-Host "- $($_.Name): $($_.Count) hit(s). Review before promotion; line contents intentionally not printed."
        }
    }
}

Write-Section "Manual prompts"
Write-Host "Run 1 prompt: $projectsRoot\shared\codex-doc-automation\prompts\run-1-analyze-and-draft.prompt.md"
Write-Host "Run 2 prompt: $projectsRoot\shared\codex-doc-automation\prompts\run-2-apply-approved-docs.prompt.md"

Write-Host ""
Write-Host "Preflight complete. No files were modified."
