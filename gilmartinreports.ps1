# Register Entra ID App for interactive login (only needs to be run once)
Register-PnPEntraIDAppForInteractiveLogin -ApplicationName "gilmartin-reports" -Tenant "gilmartincap.onmicrosoft.com"

# Connect to SharePoint using interactive login
$siteUrl = "https://gilmartinir.sharepoint.com/sites/gilmartin"
Connect-PnPOnline -Url $siteUrl -Interactive

# Define document library
$libraryName = "Documents"  # change if your library name is different

# Get all folders in the document library (recursively)
$folders = Get-PnPListItem -List $libraryName -PageSize 1000 -Fields "FileDirRef", "FSObjType" |
    Where-Object { $_["FSObjType"] -eq 1 }

# Prepare result array
$folderPermissions = @()

foreach ($folder in $folders) {
    $folderPath = $folder["FileDirRef"]
    $item = Get-PnPListItem -List $libraryName -Identity $folder.Id

    # Check if folder has unique permissions
    if ($item.HasUniqueRoleAssignments) {
        $roles = Get-PnPProperty -ClientObject $item -Property RoleAssignments
        $groupNames = @()

        foreach ($role in $roles) {
            $member = Get-PnPProperty -ClientObject $role -Property Member
            if ($member.PrincipalType -eq "SecurityGroup" -or $member.PrincipalType -eq "SharePointGroup") {
                $groupNames += $member.Title
            }
        }

        # Save result
        $folderPermissions += [PSCustomObject]@{
            FolderPath = $folderPath
            Groups     = $groupNames -join ", "
        }
    }
}

# Output results
$folderPermissions | Format-Table -AutoSize
