# Config Variables
$SiteURL1 = ""
$SiteURL2 = ""
$ListNameSource = ""
$ListNameTarget = ""
$SourceExportPath = ""
$TargetExportPath = ""

# Connect to SharePoint Sites
Connect-PnPOnline -Url $SiteURL1 -Interactive
$List1Items = Get-PnPListItem -List $ListNameSource -PageSize 500 | Where-Object { $_.FileSystemObjectType -eq "File" }
Disconnect-PnPOnline

Connect-PnPOnline -Url $SiteURL2 -Interactive
$List2Items = Get-PnPListItem -List $ListNameTarget -PageSize 500 | Where-Object { $_.FileSystemObjectType -eq "File" }
Disconnect-PnPOnline

# Initialize hash tables for Site 1 and Site 2
$Site1Files = @{}
$Site2Files = @{}

# Loop through List1 and populate the Site1Files hash table
foreach ($Item1 in $List1Items) {
    $FileName = $Item1.FieldValues['FileLeafRef']
    $FileModificationDate = $Item1.FieldValues['Modified']  # Use Modified date
    $FileSize = $Item1.FieldValues['File_x0020_Size']
    $FileDirRef = $Item1.FieldValues['FileDirRef']

    $Site1Files[$FileName] = @{
        FileModificationDate = $FileModificationDate
        FileSize = $FileSize
        Subfolder = $FileDirRef
    }
}

# Loop through List2 and check for unique files in Site 2
$UniqueToSite2 = @()
foreach ($Item2 in $List2Items) {
    $FileName = $Item2.FieldValues['FileLeafRef']
    $FileModificationDate = $Item2.FieldValues['Modified']  # Use Modified date
    $FileSize = $Item2.FieldValues['File_x0020_Size']
    $FileDirRef = $Item2.FieldValues['FileDirRef']

    $Site2Files[$FileName] = @{
        FileModificationDate = $FileModificationDate
        FileSize = $FileSize
        Subfolder = $FileDirRef
    }

    if (-not $Site1Files.ContainsKey($FileName)) {
        $UniqueToSite2 += [PSCustomObject]@{
            FileName = $FileName
            Subfolder = $FileDirRef
            Site2Modified = $FileModificationDate
            SizeInSite2 = $FileSize
        }
    }
}

# Check for unique files in Site 1
$UniqueToSite1 = @()
foreach ($Item1 in $List1Items) {
    $FileName = $Item1.FieldValues['FileLeafRef']
    $FileModificationDate = $Item1.FieldValues['Modified']  # Use Modified date
    $FileSize = $Item1.FieldValues['File_x0020_Size']
    $FileDirRef = $Item1.FieldValues['FileDirRef']

    if (-not $Site2Files.ContainsKey($FileName)) {
        $UniqueToSite1 += [PSCustomObject]@{
            FileName = $FileName
            Subfolder = $FileDirRef
            Site1Modified = $FileModificationDate
            SizeInSite1 = $FileSize
        }
    }
}

# Ask the user if they want to export the entire list or a specific subfolder for Site 1
$exportChoice = Read-Host "Do you want to export the entire list (press Enter) or a specific subfolder from Site 1? (enter the subfolder name)"

if ($exportChoice -eq "") {
    # User chose to export the entire list for Site 1
    $ExportListSite1 = $UniqueToSite1
} else {
    # User wants to export a specific subfolder for Site 1
    $subfolderName = $exportChoice

    # Filter item results based on Subfolder_Site1
    $ExportListSite1 = $UniqueToSite1 | Where-Object { $_.Subfolder -like "*/$subfolderName/*" -or $_.Subfolder -like "*/$subfolderName" }
}

# Ask the user if they want to export the entire list or a specific subfolder for Site 2
$exportChoice2 = Read-Host "Do you want to export the entire list (press Enter) or a specific subfolder from Site 2? (enter the subfolder name)"

if ($exportChoice2 -eq "") {
    # User chose to export the entire list for Site 2
    $ExportListSite2 = $UniqueToSite2
} else {
    # User wants to export a specific subfolder for Site 2
    $subfolderName = $exportChoice2

    # Filter item results based on Subfolder_Site2
    $ExportListSite2 = $UniqueToSite2 | Where-Object { $_.Subfolder -like "*/$subfolderName/*" -or $_.Subfolder -like "*/$subfolderName*" }
}

# Export the data for Site 2 unique items to Site 2
if ($ExportListSite2.Count -gt 0) {
    $ExportListSite2 | Export-Csv -Path $TargetExportPath -NoTypeInformation
    Write-Host "The results for Site 2 unique items have been exported to $TargetExportPath"
} else {
    Write-Host "No unique files found for Site 2."
}

# Export the data for Site 1 unique items to Site 1
if ($ExportListSite1.Count -gt 0) {
    $ExportListSite1 | Export-Csv -Path $SourceExportPath -NoTypeInformation
    Write-Host "The results for Site 1 unique items have been exported to $SourceExportPath"
} else {
    Write-Host "No unique files found for Site 1."
}
