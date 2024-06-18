param (
    [string]$ipaFilePath
)

# Check if the IPA file path is provided
if (-not $ipaFilePath) {
    Write-Host "Please provide the path to the Discord IPA file."
    exit 1
}

# Verify if the file exists
if (-not (Test-Path $ipaFilePath)) {
    Write-Host "File not found: $ipaFilePath"
    exit 1
}

# Create a unique temporary folder
$timestamp = Get-Date -Format 'yyyyMMddHHmmss'
$extractedFolder = Join-Path $env:TEMP "DiscordIPA_$timestamp"
New-Item -ItemType Directory -Path $extractedFolder | Out-Null

# Extract the IPA archive to the temporary folder
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory($ipaFilePath, $extractedFolder)

# Navigate to the specified path in the archive and get the folder name
$pnpmFolderPath = Join-Path $extractedFolder "Payload\Discord.app\assets\_node_modules\.pnpm"
$folderName = Get-ChildItem $pnpmFolderPath | Select-Object -First 1 -ExpandProperty Name

# Rename the folder to "somethinglol"
$newFolderName = "somethinglol"
Rename-Item -Path (Join-Path $pnpmFolderPath $folderName) -NewName $newFolderName

# Update the manifest.json file
$manifestPath = Join-Path $extractedFolder "Payload\Discord.app\manifest.json"
$manifestContent = Get-Content $manifestPath -Raw
$manifestContent = $manifestContent -replace [regex]::Escape($folderName), $newFolderName
Set-Content -Path $manifestPath -Value $manifestContent

# Display log
Write-Host "IPA modification completed."
Write-Host "Folder renamed to: $newFolderName"

# Zip the modified content back to the original IPA file using .NET class
$modifiedIpaPath = [System.IO.Path]::ChangeExtension($ipaFilePath, ".modified.ipa")
[System.IO.Compression.ZipFile]::CreateFromDirectory($extractedFolder, $modifiedIpaPath)

# Clean up: Remove the temporary extraction folder
Remove-Item -Path $extractedFolder -Force -Recurse

Write-Host "Modified IPA file saved to: $modifiedIpaPath"