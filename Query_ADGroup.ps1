#Script to query AD group

Param (
    [string]$LDAPGroup = $( Read-Host "Enter the LDAP (AD) group name that needs to be queried " )
     )

    

# Group queries AD group and formats in a table.
Get-ADGroupMember $LDAPGroup | FORMAT-Table 
$OutputVar = (Get-ADGroupMember $LDAPGroup | select-string -Pattern "CN" | measure-object -line) | Out-String

Get-ADGroupMember $LDAPGroup | select-string -Pattern "CN" | measure-object -line # this gives number of members in the group
