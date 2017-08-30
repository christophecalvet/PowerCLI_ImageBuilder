function Merge-EsxImageProfile{
<#
.SYNOPSIS
Create a new EsxImageProfile by merging two EsxImageProfile and keep highest vib.

.DESCRIPTION
Create a new EsxImageProfile by merging two EsxImageProfile and keep highest vib.
Based on "New-EsxImageProfile"
Requirement: Compare-EsxImageProfilePlus

.NOTES
Author: Christophe Calvet
Blog: http://www.thecrazyconsultant.com/

.PARAMETER Profile1
First Image profile

.PARAMETER Profile2
Second Image Profile

.EXAMPLE
$NewProfile = Merge-EsxImageProfile $Profile1 $Profile2 -AcceptanceLevel "PartnerSupported" -OverrideProfileWithSameName

#>
	[CmdletBinding()]
	param(
	[Parameter(Mandatory=$true)]
	[VMware.ImageBuilder.Types.ImageProfile]$Profile1,
	[Parameter(Mandatory=$true)]
	[VMware.ImageBuilder.Types.ImageProfile]$Profile2,
	$NewName,
	$NewVendor,
	$NewDescription,
	[ValidateSet('VMwareCertified','VMwareAccepted','PartnerSupported','CommunitySupported')] 
	[string]$AcceptanceLevel = "VMwareCertified",
	[switch]$OverrideProfileWithSameName		
	)
	process{
		if(!$NewName){
		$NewName = 	"$($Profile1.name)" + "___" + "$($Profile2.name)"
		}
		if(!$NewVendor){
		$NewVendor = "$($Profile1.vendor)" + "___" + "$($Profile2.vendor)"
		}
		if(!$NewDescription){
		$NewDescription	= "$($Profile1.Description)" + "___" + "$($Profile2.Description)"
		}				
		if($OverrideProfileWithSameName){
		get-EsxImageProfile -name $NewName | Remove-EsxImageProfile
		}
		
		#Put latest VIB in one array $SoftwarePackage
		$SoftwarePackage = @()	

		$CompareResult = Compare-EsxImageProfilePlus $Profile1 $Profile2 -IncludeVibInOutput
			$CompareResult | foreach-object{
			$CurrentVib = $_
			$Analysis = $_.Analysis
			$Name = $_.name
				switch($Analysis){
				OnlyInRef{$SoftwarePackage += $CurrentVib.VibRef}
				OnlyInComp{$SoftwarePackage += $CurrentVib.VibComp}
				Identical{$SoftwarePackage += $CurrentVib.VibRef}
				UpgradeFromRef{$SoftwarePackage += $CurrentVib.VibComp}
				DowngradeFromRef{$SoftwarePackage += $CurrentVib.VibRef}
				Default{Write-Error "The output of Compare-EsxImageProfilePlus is wrong"}
				}
			
			}

		#Build new profile
		New-EsxImageProfile -NewProfile -name $NewName -vendor $NewVendor -SoftwarePackage $SoftwarePackage -AcceptanceLevel $AcceptanceLevel -Description $NewDescription
		
		
	}
}
