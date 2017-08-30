function Compare-EsxImageProfilePlus{
<#
.SYNOPSIS
Compare two EsxImageProfile.
Based on "Compare-EsxImageProfile" but with a simpler output.

.DESCRIPTION
Compare two EsxImageProfile.
Based on "Compare-EsxImageProfile" but with a simpler output.

.NOTES
Author: Christophe Calvet
Blog: http://www.thecrazyconsultant.com/

.PARAMETER ReferenceProfile
Specifies the reference image profile for comparison.

.PARAMETER ComparisonProfile
The image profile to compare against.

.PARAMETER IncludeVibInOutput
Add the Vib in the output table. Only useful if extra information need to be extracted.

.EXAMPLE
#The standard output list Vib Name, Vendor And Version for both the source and destination profile, and the analysis.
Compare-EsxImageProfilePlus $ImageProfile1 $ImageProfile2 | select * | ogv

#The switch IncludeVibInOutput is used to extra more information like CreationDate or Description in the example below.
Compare-EsxImageProfilePlus $ImageProfile1 $ImageProfile2 -IncludeVibInOutput | select Name,VendorRef,VersionRef,@{N="CreationDateRef";E={$_.VibRef.CreationDate}},@{N="DescriptionRef";E={$_.VibRef.Description}},VendorComp,VersionComp,@{N="CreationDateComp";E={$_.VibComp.CreationDate}},@{N="DescriptionComp";E={$_.VibComp.Description}},Analysis | ogv
#>
	[CmdletBinding()]
	param(
	[Parameter(Mandatory=$true)]
	[VMware.ImageBuilder.Types.ImageProfile]$ReferenceProfile,
	[Parameter(Mandatory=$true)]
	[VMware.ImageBuilder.Types.ImageProfile]$ComparisonProfile,
	[switch]$IncludeVibInOutput
	)
	process{

$ViblistReferenceProfile = ($ReferenceProfile.viblist)
$ViblistComparisonProfile = ($ComparisonProfile.viblist)

	
	$ListOfAllVib  = $ViblistReferenceProfile + $ViblistComparisonProfile

	$CompareResult = Compare-EsxImageProfile $ReferenceProfile $ComparisonProfile
	$UpgradeFromRef = $CompareResult.UpgradeFromRef
	$DowngradeFromRef = $CompareResult.DowngradeFromRef

	$VibNameUpgradeFromRef = $UpgradeFromRef | foreach-object{
	$VibName = $_ -replace ('.*bootbank_','') -replace ('.*re_locker_','') -replace ('_.*','')
	$VibName
	}

	$VibNameDowngradeFromRef = $DowngradeFromRef | foreach-object{
	$VibName = $_ -replace ('.*bootbank_','') -replace ('.*re_locker_','') -replace ('_.*','')
	$VibName
	}

	$ListOfAllVib | select -unique Name | foreach-object {
		$Name = $_.Name
		$Analysis = "NotTested"
		$VibRef = ($ViblistReferenceProfile | where {$_.Name -eq $Name})
		$VibComp = ($ViblistComparisonProfile | where {$_.Name -eq $Name})

		If (($VibRef -and !$VibComp )){
		$Analysis = "OnlyInRef"
		}
		If ((!$VibRef -and $VibComp )){
		$Analysis = "OnlyInComp"
		}

		If (($VibRef -and $VibComp)){
			If (($VibRef.version) -eq ($VibComp.version)){
			$Analysis = "Identical"
			}
			if ($Name -in $VibNameUpgradeFromRef){
			$Analysis = "UpgradeFromRef"
			}
			if ($Name -in $VibNameDowngradeFromRef){
			$Analysis = "DowngradeFromRef"
			}	
		}


								if($IncludeVibInOutput){
									$Result = New-Object -Type PSObject -Prop ([ordered]@{
									'Name' = $Name
									'VendorRef' = $VibRef.Vendor
									'VersionRef' = $VibRef.Version
									'VibRef' = $Vibref
									'VendorComp' = $VibComp.Vendor
									'VersionComp' = $VibComp.Version
									'VibComp' = $VibComp
									'Analysis' = $Analysis	
									 })    
									Return $Result
								}
								Else{
									$Result = New-Object -Type PSObject -Prop ([ordered]@{
									'Name' = $Name
									'VendorRef' = $VibRef.Vendor
									'VersionRef' = $VibRef.Version
									'VendorComp' = $VibComp.Vendor
									'VersionComp' = $VibComp.Version								
									'Analysis' = $Analysis									
									 })    
									Return $Result								
								}
				
		}
	
	
	}

}
