# Ensure the AD module is loaded
if (-not (Get-Module -Name ActiveDirectory -ErrorAction SilentlyContinue)) {
    Import-Module ActiveDirectory -ErrorAction Stop
}

$ServerName = $env:COMPUTERNAME
$DomainLocalGroup = "PRV-$ServerName-LocalAdmins"
$DomainGroup = "mydomain\group01admins"  # Fully qualified with the correct domain

try {
    # Ensure the AD group exists
    if (-not (Get-ADGroup -Filter { Name -eq $DomainLocalGroup } -ErrorAction SilentlyContinue)) {
        Write-Output "Error: The group $DomainLocalGroup does not exist in AD."
        exit 1
    }

    # Get current members, filtering by domain
    $existingMembers = Get-ADGroupMember -Identity $DomainLocalGroup -ErrorAction Stop | 
        Where-Object { $_.DistinguishedName -match "DC=mydomain,DC=com" }

    # Extract SamAccountName with domain prefix
    $memberNames = $existingMembers | ForEach-Object { "$($_.SID.AccountDomainName)\$($_.SamAccountName)" }

    if ($memberNames -contains $DomainGroup) {
        Write-Output "$DomainGroup is already a member of $DomainLocalGroup."
    } else {
        # Add the domain group
        Add-ADGroupMember -Identity $DomainLocalGroup -Members $DomainGroup -ErrorAction Stop
        Write-Output "Successfully added $DomainGroup to $DomainLocalGroup."
    }
}
catch {
    Write-Output "Error: $_"
}
