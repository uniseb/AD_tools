# Ensure the AD module is loaded
if (-not (Get-Module -Name ActiveDirectory -ErrorAction SilentlyContinue)) {
    Import-Module ActiveDirectory -ErrorAction Stop
}

$ServerName = $env:COMPUTERNAME
$DomainLocalGroup = "PRV-$ServerName-LocalAdmins"
$DomainGroupSam = "group01admins"  # Just the name, no domain prefix
$DomainName = "mydomain.com"  # Ensure we get the group from the correct domain

try {
    # Ensure the AD security group exists
    if (-not (Get-ADGroup -Filter { Name -eq $DomainLocalGroup } -ErrorAction SilentlyContinue)) {
        Write-Output "Error: The group $DomainLocalGroup does not exist in AD."
        exit 1
    }

    # Find the full Distinguished Name (DN) of the group from the correct domain
    $DomainGroup = Get-ADGroup -Filter { SamAccountName -eq $DomainGroupSam } -Server $DomainName -ErrorAction Stop

    if ($null -eq $DomainGroup) {
        Write-Output "Error: The group $DomainGroupSam does not exist in $DomainName."
        exit 1
    }

    $DomainGroupDN = $DomainGroup.DistinguishedName

    # Check if the group is already a member
    $existingMembers = Get-ADGroupMember -Identity $DomainLocalGroup -ErrorAction Stop

    if ($existingMembers.DistinguishedName -contains $DomainGroupDN) {
        Write-Output "$DomainGroupSam is already a member of $DomainLocalGroup."
    } else {
        # Add the correct group using its DN
        Add-ADGroupMember -Identity $DomainLocalGroup -Members $DomainGroupDN -ErrorAction Stop
        Write-Output "Successfully added $DomainGroupSam to $DomainLocalGroup."
    }
}
catch {
    Write-Output "Error: $_"
}
