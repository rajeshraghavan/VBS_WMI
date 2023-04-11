 # This script removes images for this version

$ErrorActionPreference="Stop"
. "$PSScriptRoot\init.ps1"

Write-Output "Removes images for this release. Run after upgrading to a newer release."
$CLEAN=$(Read-Host -prompt "Clean images? (default n)")
$CLEAN=$CLEAN.StartsWith('y') -Or $CLEAN.StartsWith('n')


if ($CLEAN) {
	foreach ($img_env in (Get-ChildItem env:*_IMAGE)) {
		if ($img.Value.StartsWith("${REGISTRY}/")) {
			docker rmi $img.Value
		}
	}
	
	docker image prune -f 
