Import-Module "$PSScriptRoot/modules/export/Export.psm1"
$s = Get-DatasetSchema -DatasetName 'entra_role_assignments'
Write-Host "Schema version: $($s.version)"
$sample = [pscustomobject]@{RoleId='r1';RoleDisplayName='Admin';MemberId='u1';MemberType='User';MemberDisplayName='User One';MemberPrincipalName='user@contoso.com'}
$ok = Test-ObjectAgainstSchema -InputObject $sample -Schema $s
Write-Host "Validation: $ok"
