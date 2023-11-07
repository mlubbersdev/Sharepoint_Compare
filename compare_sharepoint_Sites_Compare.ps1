# Config Variables
$SiteURL1 = ""
$SiteURL2 = ""
$ListNameSource = ""
$ListNameTarget = ""
$SourceExportPath = ""
$TargetExportPath = ""
$ComparisonPath = ""

# Connect to SharePoint Sites
Connect-PnPOnline -Url $SiteURL1 -Interactive
$List1Items = @()
$List1ItemsPage = Get-PnPListItem -List $ListNameSource -PageSize 500 | Where-Object { $_.FileSystemObjectType -eq "File" }
$List1Items += $List1ItemsPage
while ($List1ItemsPage.Count -eq 500) {
    $List1ItemsPage = Get-PnPListItem -List $ListNameSource -PageSize 500 -StartIndex $List1Items.Count | Where-Object { $_.FileSystemObjectType -eq "File" }
    $List1Items += $List1ItemsPage
}
Disconnect-PnPOnline

Connect-PnPOnline -Url $SiteURL2 -Interactive
$List2Items = @()
$List2ItemsPage = Get-PnPListItem -List $ListNameTarget -PageSize 500 | Where-Object { $_.FileSystemObjectType -eq "File" }
$List2Items += $List2ItemsPage
while ($List2ItemsPage.Count -eq 500) {
    $List2ItemsPage = Get-PnPListItem -List $ListNameTarget -PageSize 500 -StartIndex $List2Items.Count | Where-Object { $_.FileSystemObjectType -eq "File" }
    $List2Items += $List2ItemsPage
}
Disconnect-PnPOnline

# ComparisonResults to store the file comparison results
$ComparisonResults = @()

# Initialize the Site1Files hash table
$Site1Files = @{}
# Initialize the Site2Files hash table
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
        Subfolder_Site1 = $FileDirRef
        Subfolder_Site2 = $null
    }
}

# Loop through List2 and populate the Site2Files hash table
foreach ($Item2 in $List2Items) {
    $FileName = $Item2.FieldValues['FileLeafRef']
    $FileModificationDate = $Item2.FieldValues['Modified']  # Use Modified date
    $FileSize = $Item2.FieldValues['File_x0020_Size']
    $FileDirRef = $Item2.FieldValues['FileDirRef']

    if ($Site1Files.ContainsKey($FileName)) {
        $Site1File = $Site1Files[$FileName]
        $Site1File.Subfolder_Site2 = $FileDirRef

        $ComparisonResult = [PSCustomObject]@{
            FileName = $FileName
            Subfolder_Site1 = $Site1File.Subfolder_Site1
            Subfolder_Site2 = $Site1File.Subfolder_Site2
            Site1Modified = $Site1File.FileModificationDate  # Use Site1Modified
            Site2Modified = $FileModificationDate  # Use Site2Modified
            SizeInSite1 = $Site1File.FileSize
            SizeInSite2 = $FileSize
            AgeComparison = if ($FileModificationDate -lt $Site1File.FileModificationDate) { "Site1 Newer" } elseif ($FileModificationDate -gt $Site1File.FileModificationDate) { "Site2 Newer" } else { "Same Age" }
            SizeComparison = if ($FileSize -lt $Site1File.FileSize) { "Site1 Larger" } elseif ($FileSize -gt $Site1File.FileSize) { "Site2 Larger" } else { "Same Size" }
        }
        $ComparisonResults += $ComparisonResult
    } else {
        $Site2Files[$FileName] = @{
            FileModificationDate = $FileModificationDate
            FileSize = $FileSize
            Subfolder_Site1 = $null
            Subfolder_Site2 = $FileDirRef
        }
    }
}

# Identify files unique to Site 1
$UniqueToSite1 = $Site1Files.Keys | Where-Object { -not $Site2Files.ContainsKey($_) }

# Identify files unique to Site 2
$UniqueToSite2 = $Site2Files.Keys | Where-Object { -not $Site1Files.ContainsKey($_) }

# Verify the content of $UniqueToSite1 and $UniqueToSite2
Write-Host "Files unique to Site 1 (Source):"
$UniqueToSite1 | ForEach-Object { Write-Host $_.InputObject }

Write-Host "Files unique to Site 2 (Target):"
$UniqueToSite2 | ForEach-Object { Write-Host $_.InputObject }

# Output the comparison results
$ComparisonResults | Format-Table -AutoSize

# Ask the user if they want to export the entire list or a specific subfolder
$exportChoice = Read-Host "Do you want to export the entire list (press Enter) or a specific subfolder from site 1? (enter the subfolder name)?"
$exportChoice2 = Read-Host "Do you want to export the entire list (press Enter) or a specific subfolder from site 2? (enter the subfolder name)?"
if ($exportChoice -eq "") {
    # Export the entire list
    $ExportList = $List1Items
} else {
    # Export a specific subfolder and its subfolders
    $subfolderName = $exportchoice
    $subfolderName2 = $exportChoice2
    
    # Filter item results based on Subfolder_Site1
    $ExportList = $ComparisonResults | Where-Object { $_.Subfolder_Site1 -like "*/$subfolderName/*" -or $_.Subfolder_Site1 -like "*/$subfolderName" }

     # Further filter the results based on Subfolder_Site2
    $ExportList = $ExportList | Where-Object { $_.Subfolder_Site2 -like "*$subfolderName*" }
}

# Export the selected list or subfolder to a CSV file
$ExportList | Export-Csv -Path $ComparisonPath -NoTypeInformation
