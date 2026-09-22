$ErrorActionPreference = 'Stop'
$BatchLimitMB = 10
$BatchLimit = $BatchLimitMB * 1MB
$RepoUrl = 'https://github.com/spirit2k5/denz-iphones.git'
$Desktop = [Environment]::GetFolderPath('Desktop')
$RepoDir = Join-Path $Desktop 'denz-iphones-upload'

Write-Host "Denz iPhones small-batch media uploader" -ForegroundColor Cyan
Write-Host "Maximum target per commit/push: $BatchLimitMB MB" -ForegroundColor Cyan

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw 'Git is not installed or is not available in PATH.'
}

# Find the latest extracted Denz website folder on the Desktop.
$Source = Get-ChildItem -Path $Desktop -Directory -Recurse -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -eq 'Denz_iPhones_Luxury_Store' } |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1

# If it is not extracted yet, try the latest corrected ZIP and extract it automatically.
if (-not $Source) {
    $Zip = Get-ChildItem -Path $Desktop -File -Recurse -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -eq 'carlton_fixed_flat_delivery_R100.zip' } |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1

    if (-not $Zip) {
        throw 'Could not find Denz_iPhones_Luxury_Store or carlton_fixed_flat_delivery_R100.zip on the Desktop.'
    }

    $ExtractDir = Join-Path $Desktop 'denz-media-source'
    if (Test-Path $ExtractDir) { Remove-Item $ExtractDir -Recurse -Force }
    New-Item -ItemType Directory -Path $ExtractDir | Out-Null
    Write-Host "Extracting corrected ZIP..." -ForegroundColor Yellow
    Expand-Archive -Path $Zip.FullName -DestinationPath $ExtractDir -Force

    $Source = Get-ChildItem -Path $ExtractDir -Directory -Recurse |
        Where-Object { $_.Name -eq 'Denz_iPhones_Luxury_Store' } |
        Select-Object -First 1
}

Write-Host "Source: $($Source.FullName)" -ForegroundColor Green

if (Test-Path (Join-Path $RepoDir '.git')) {
    Write-Host 'Updating existing local repo...' -ForegroundColor Yellow
    git -C $RepoDir pull --ff-only
} else {
    if (Test-Path $RepoDir) { Remove-Item $RepoDir -Recurse -Force }
    Write-Host 'Cloning GitHub repo...' -ForegroundColor Yellow
    git clone $RepoUrl $RepoDir
}

$MediaRoots = @(
    (Join-Path $Source.FullName 'assets\img'),
    (Join-Path $Source.FullName 'assets\videos')
)

$Files = foreach ($root in $MediaRoots) {
    if (Test-Path $root) { Get-ChildItem -Path $root -File -Recurse }
}

if (-not $Files -or $Files.Count -eq 0) {
    throw 'No media files were found in assets\img or assets\videos.'
}

# Build <=10 MB batches. The largest supplied video is under 10 MB.
$Batches = @()
$Current = @()
$CurrentBytes = 0
foreach ($File in ($Files | Sort-Object FullName)) {
    if ($Current.Count -gt 0 -and ($CurrentBytes + $File.Length) -gt $BatchLimit) {
        $Batches += ,@($Current)
        $Current = @()
        $CurrentBytes = 0
    }
    $Current += $File
    $CurrentBytes += $File.Length
}
if ($Current.Count -gt 0) { $Batches += ,@($Current) }

Write-Host ("Media files: {0} | Batches: {1}" -f $Files.Count, $Batches.Count) -ForegroundColor Cyan

$BatchNo = 0
foreach ($Batch in $Batches) {
    $BatchNo++
    $BatchBytes = ($Batch | Measure-Object Length -Sum).Sum
    Write-Host ("`nBatch {0}/{1} - {2:N2} MB" -f $BatchNo, $Batches.Count, ($BatchBytes / 1MB)) -ForegroundColor Magenta

    $RelativePaths = @()
    foreach ($File in $Batch) {
        $Relative = $File.FullName.Substring($Source.FullName.Length).TrimStart('\')
        $Destination = Join-Path $RepoDir $Relative
        $DestinationDir = Split-Path $Destination -Parent
        if (-not (Test-Path $DestinationDir)) { New-Item -ItemType Directory -Path $DestinationDir -Force | Out-Null }
        Copy-Item -LiteralPath $File.FullName -Destination $Destination -Force
        $RelativePaths += ($Relative -replace '\','/')
    }

    foreach ($Path in $RelativePaths) {
        git -C $RepoDir add -- $Path
        if ($LASTEXITCODE -ne 0) { throw "git add failed for $Path" }
    }

    $Changes = git -C $RepoDir diff --cached --name-only
    if (-not $Changes) {
        Write-Host 'Nothing new in this batch; skipping commit.' -ForegroundColor DarkGray
        continue
    }

    git -C $RepoDir commit -m "Upload media batch $BatchNo of $($Batches.Count)"
    if ($LASTEXITCODE -ne 0) { throw "git commit failed on batch $BatchNo" }

    git -C $RepoDir push origin main
    if ($LASTEXITCODE -ne 0) {
        throw "git push failed on batch $BatchNo. Fix GitHub sign-in/network and run the script again; completed batches are already safe."
    }

    Write-Host "Batch $BatchNo uploaded successfully." -ForegroundColor Green
}

Write-Host "`nAll media batches are uploaded." -ForegroundColor Green
Write-Host "Repo: https://github.com/spirit2k5/denz-iphones" -ForegroundColor Cyan
