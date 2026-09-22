param([string]$InputPath)
$ErrorActionPreference = 'Stop'

$BatchLimitMB = 10
$BatchLimit = $BatchLimitMB * 1MB
$RepoUrl = 'https://github.com/spirit2k5/denz-iphones.git'
$UserHome = [Environment]::GetFolderPath('UserProfile')
$Desktop = [Environment]::GetFolderPath('Desktop')
$Downloads = Join-Path $UserHome 'Downloads'
$Documents = [Environment]::GetFolderPath('MyDocuments')
$RepoDir = Join-Path $Desktop 'denz-iphones-upload'
$ExtractDir = Join-Path $Desktop 'denz-media-source'

Write-Host "Denz iPhones small-batch media uploader" -ForegroundColor Cyan
Write-Host "Maximum target per commit/push: $BatchLimitMB MB" -ForegroundColor Cyan

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw 'Git is not installed or is not available in PATH.'
}

function Find-WebsiteRoot([string]$Start) {
    if (-not $Start -or -not (Test-Path -LiteralPath $Start)) { return $null }
    $item = Get-Item -LiteralPath $Start
    if (-not $item.PSIsContainer) { return $null }

    if ((Test-Path (Join-Path $item.FullName 'assets\img')) -and (Test-Path (Join-Path $item.FullName 'index.html'))) {
        return $item
    }

    return Get-ChildItem -LiteralPath $item.FullName -Directory -Recurse -ErrorAction SilentlyContinue |
        Where-Object {
            (Test-Path (Join-Path $_.FullName 'assets\img')) -and
            (Test-Path (Join-Path $_.FullName 'index.html'))
        } |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
}

function Pick-Source {
    Add-Type -AssemblyName System.Windows.Forms

    $pick = New-Object System.Windows.Forms.OpenFileDialog
    $pick.Title = 'Select the corrected Denz iPhones ZIP'
    $pick.Filter = 'ZIP files (*.zip)|*.zip|All files (.*)|*.*'
    $pick.Multiselect = $false

    if ($pick.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        return $pick.FileName
    }

    $folder = New-Object System.Windows.Forms.FolderBrowserDialog
    $folder.Description = 'Or choose the extracted Denz iPhones website folder'
    if ($folder.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        return $folder.SelectedPath
    }

    return $null
}

$Source = $null
$Zip = $null

if ($InputPath -and (Test-Path -LiteralPath $InputPath)) {
    $selected = Get-Item -LiteralPath $InputPath
    if ($selected.PSIsContainer) { $Source = Find-WebsiteRoot $selected.FullName }
    elseif ($selected.Extension -ieq '.zip') { $Zip = $selected }
}

if (-not $Source -and -not $Zip) {
    $roots = @($Desktop, $Downloads, $Documents) | Where-Object { $_ -and (Test-Path -LiteralPath $_) }

    foreach ($root in $roots) {
        $Source = Find-WebsiteRoot $root
        if ($Source) { break }
    }

    if (-not $Source) {
        $ZipCandidates = @()
        foreach ($root in $roots) {
            $ZipCandidates += @(
                Get-ChildItem -LiteralPath $root -File -Filter '*.zip' -Recurse -ErrorAction SilentlyContinue |
                    Where-Object {
                        $_.Name -match '(?i)(carlton.*R100|denz.*iphone|fixed.*delivery|carlton_fixed)'
                    }
            )
        }
        $Zip = $ZipCandidates | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    }
}

if (-not $Source -and -not $Zip) {
    Write-Host ''
    Write-Host 'I could not find the corrected website automatically.' -ForegroundColor Yellow
    Write-Host 'A file picker will open. Select the corrected Denz iPhones ZIP.' -ForegroundColor Yellow
    $picked = Pick-Source
    if (-not $picked) { throw 'No ZIP or website folder was selected.' }

    $selected = Get-Item -LiteralPath $picked
    if ($selected.PSIsContainer) { $Source = Find-WebsiteRoot $selected.FullName }
    elseif ($selected.Extension -ieq '.zip') { $Zip = $selected }
}

if ($Zip) {
    if (Test-Path $ExtractDir) { Remove-Item $ExtractDir -Recurse -Force }
    New-Item -ItemType Directory -Path $ExtractDir | Out-Null
    Write-Host "Extracting: $($Zip.FullName)" -ForegroundColor Yellow
    Expand-Archive -LiteralPath $Zip.FullName -DestinationPath $ExtractDir -Force
    $Source = Find-WebsiteRoot $ExtractDir
}

if (-not $Source) {
    throw 'The selected ZIP/folder does not contain the Denz website (index.html + assets\img).'
}

Write-Host "Website source: $($Source.FullName)" -ForegroundColor Green

if (Test-Path $RepoDir) { Remove-Item $RepoDir -Recurse -Force }
Write-Host 'Cloning the current GitHub repo...' -ForegroundColor Yellow
git clone $RepoUrl $RepoDir
if ($LASTEXITCODE -ne 0) { throw 'Git clone failed. Check your internet/GitHub sign-in.' }

$MediaRoots = @(
    (Join-Path $Source.FullName 'assets\img'),
    (Join-Path $Source.FullName 'assets\videos')
)

$Files = @(
    foreach ($root in $MediaRoots) {
        if (Test-Path $root) { Get-ChildItem -Path $root -File -Recurse }
    }
)

if (-not $Files -or $Files.Count -eq 0) {
    throw 'No media files were found in assets\img or assets\videos.'
}

$Batches = @()
$Current = @()
$CurrentBytes = 0

foreach ($File in ($Files | Sort-Object FullName)) {
    if ($File.Length -gt $BatchLimit) {
        throw "A single media file is larger than $BatchLimitMB MB: $($File.FullName)"
    }

    if ($Current.Count -gt 0 -and ($CurrentBytes + $File.Length) -gt $BatchLimit) {
        $Batches += ,@($Current)
        $Current = @()
        $CurrentBytes = 0
    }

    $Current += $File
    $CurrentBytes += $File.Length
}

if ($Current.Count -gt 0) { $Batches += ,@($Current) }

Write-Host ("Media files found: {0} | Planned batches: {1}" -f $Files.Count, $Batches.Count) -ForegroundColor Cyan

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
        if (-not (Test-Path $DestinationDir)) {
            New-Item -ItemType Directory -Path $DestinationDir -Force | Out-Null
        }
        Copy-Item -LiteralPath $File.FullName -Destination $Destination -Force
        $RelativePaths += ($Relative -replace '\\','/')
    }

    foreach ($Path in $RelativePaths) {
        git -C $RepoDir add -- $Path
        if ($LASTEXITCODE -ne 0) { throw "git add failed for $Path" }
    }

    $Changes = git -C $RepoDir diff --cached --name-only
    if (-not $Changes) {
        Write-Host 'Already uploaded - skipping this batch.' -ForegroundColor DarkGray
        continue
    }

    git -C $RepoDir commit -m "Upload media batch $BatchNo of $($Batches.Count)"
    if ($LASTEXITCODE -ne 0) { throw "git commit failed on batch $BatchNo" }

    git -C $RepoDir push origin main
    if ($LASTEXITCODE -ne 0) {
        throw "git push failed on batch $BatchNo. Run this uploader again after fixing the connection; uploaded batches will be skipped."
    }

    Write-Host "Batch $BatchNo uploaded successfully." -ForegroundColor Green
}

Write-Host "`nAll available media batches are uploaded." -ForegroundColor Green
Write-Host "Repo: https://github.com/spirit2k5/denz-iphones" -ForegroundColor Cyan
