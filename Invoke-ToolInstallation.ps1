#Requires -Version 3

<#
.Synopsis
   Installs or uninstalls one or more console extensions for 
   System Center Configuration Manager 2012 & 2012R2
.DESCRIPTION
   Installs or uninstalls one or more console extensions for 
   System Center Configuration Manager 2012 & 2012R2
.PARAMETER Path
    Sets the path where the script file(s) will be stored (Or removed from, 
    if the run with -Uninstall).  This path must already exist, the script will not create the path 
    if it is not found. 
.PARAMETER StringToReplace
   Specifies the string you wish to search for and replace within your XML Configuration Files.
	The default string is 'C:\Scripts'.
.PARAMETER Uninstall 
   Runs the script in "Uninstall" mode, to remove the console extension from a computer where it has
   been previously installed. 
.EXAMPLE
    PS > Invoke-ToolInstallation.ps1 -Path 'C:\ConsoleExtensions' -StringToReplace 'C:\Scripts' -Verbose
		VERBOSE: ConfigMgr console environment variable detected: C:\Program Files (x86)\Microsoft Configuration
		Manager\AdminConsole\bin\i386
		VERBOSE: 1 Files were identified in the source Script directory
		VERBOSE: 2 Files were identified in the source Actions directory
		VERBOSE: XML File Name: Create-CMPilotCollection.xml
		VERBOSE: XML GUID Directory: 34446c89-5a0d-4287-88e5-9c87d832a946
		VERBOSE: Removing Create-CMPilotCollection.xml from C:\Program Files (x86)\Microsoft Configuration
		Manager\AdminConsole\XMLStorage\Extensions\Actions\34446c89-5a0d-4287-88e5-9c87d832a946
		VERBOSE: Modifying XML File: 'Create-CMPilotCollection.xml'
		VERBOSE: XML File Name: Create-CMPilotCollection.xml
		VERBOSE: XML GUID Directory: a92615d6-9df3-49ba-a8c9-6ecb0e8b956b
		VERBOSE: Removing Create-CMPilotCollection.xml from C:\Program Files (x86)\Microsoft Configuration
		Manager\AdminConsole\XMLStorage\Extensions\Actions\a92615d6-9df3-49ba-a8c9-6ecb0e8b956b
		VERBOSE: Modifying XML File: 'Create-CMPilotCollection.xml'
		VERBOSE: Copying Script File 'Create-CMPilotCollection.ps1' to C:\ConsoleExtensions'
.EXAMPLE
    PS > Invoke-ToolInstallation.ps1 -Uninstall -Path 'C:\ConsoleExtensions' -Verbose
		VERBOSE: ConfigMgr console environment variable detected: C:\Program Files (x86)\Microsoft Configuration
		Manager\AdminConsole\bin\i386
		VERBOSE: 1 Files were identified in the source Script directory
		VERBOSE: 2 Files were identified in the source Actions directory
		VERBOSE: Removing Create-CMPilotCollection.xml from C:\Program Files (x86)\Microsoft Configuration
		Manager\AdminConsole\XMLStorage\Extensions\Actions\34446c89-5a0d-4287-88e5-9c87d832a946
		VERBOSE: Removing Create-CMPilotCollection.xml from C:\Program Files (x86)\Microsoft Configuration
		Manager\AdminConsole\XMLStorage\Extensions\Actions\a92615d6-9df3-49ba-a8c9-6ecb0e8b956b
		VERBOSE: Removing Script File 'Create-CMPilotCollection.ps1' from C:\ConsoleExtensions'
.AUTHOR
	Original Script Author: Nickolaj Anderson (@NickolajA | www.scconfigmgr.com)
	Updated 2015.09.02 by Dustin Hedges (@dhedges01 | deploymentramblings.wordpress.com)
#>

[CmdletBinding(SupportsShouldProcess=$true) ]
param(
    [parameter(Mandatory=$true, HelpMessage="Specify a valid path to where the script file(s) will be stored", ParameterSetName="Install")]
    [parameter(Mandatory=$true, ParameterSetName="Uninstall")]
    [ValidateNotNullOrEmpty()]
    [ValidatePattern("^[A-Za-z]{1}:\\\w+")]
    [ValidateScript({
        # Check if path contains any invalid characters
        if ((Split-Path -Path $_ -Leaf).IndexOfAny([IO.Path]::GetInvalidFileNameChars()) -ge 0) {
            throw "$(Split-Path -Path $_ -Leaf) contains invalid characters"
        }
        else {
            # Check if the whole path exists
            if (Test-Path -Path $_ -PathType Container) {
                    return $true
            }
            else {
                throw "Unable to locate part of or the whole specified path, specify a valid path"
            }
        }
    })]
	[string]$Path,
	[parameter(Mandatory = $false, HelpMessage = "The string you wish to replace inside your XML Configuration Files.  Default is 'C:\Scripts'", ParameterSetName = "Install")]
	[ValidateNotNullOrEmpty()]
	[System.String]$StringToReplace='C:\Scripts',
    [parameter(Mandatory=$true, ParameterSetName="Uninstall")]
    [switch]$Uninstall
)
Begin {	
	# Validate that the script is being executed elevated
    try {
        $CurrentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $WindowsPrincipal = New-Object Security.Principal.WindowsPrincipal -ArgumentList $CurrentIdentity
        if (-not($WindowsPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))) {
            Write-Warning -Message "Script was not executed elevated, please re-launch." ; break
        }
    } 
    catch {
        Write-Warning -Message $_.Exception.Message ; break
    }
    # Determine PSScriptRoot
    $ScriptRoot = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
    # Validate ConfigMgr console presence
    if ($env:SMS_ADMIN_UI_PATH -ne $null) {
        try {
            if (Test-Path -Path $env:SMS_ADMIN_UI_PATH -PathType Container -ErrorAction Stop) {
                Write-Verbose -Message "ConfigMgr console environment variable detected: $($env:SMS_ADMIN_UI_PATH)"
            }
        }
        catch [Exception] {
            Write-Warning -Message $_.Exception.Message ; break
        }
    }
    else {
        Write-Warning -Message "ConfigMgr console environment variable was not detected" ; break
    }
	
	# Determine Admin console root
	$AdminConsoleRoot = ($env:SMS_ADMIN_UI_PATH).Substring(0, $env:SMS_ADMIN_UI_PATH.Length - 9)
	$ActionsRoot = "$AdminConsoleRoot\XMLStorage\Extensions\Actions"
	
	try
	{
		if (Test-Path -Path "$ScriptRoot\Scripts" -ErrorAction Stop)
		{
			$FileCount = $(Get-ChildItem -Path "$ScriptRoot\Scripts" -Recurse -Force).Count
			if ($FileCount -gt 0)
			{
				Write-Verbose -Message "$FileCount Files were identified in the source Script directory"
			}
			else
			{
				Write-Warning -Message "No scripts were found in the source Script directory"; break
			}
		}
		if (Test-Path -Path "$ScriptRoot\Actions" -ErrorAction Stop)
		{
			Remove-Variable FileCount -Force -ErrorAction SilentlyContinue | Out-Null
			$FileCount = $(Get-ChildItem -Path "$ScriptRoot\Actions" -Include *.xml -Recurse -Force).Count
			if ($FileCount -gt 0)
			{
				Write-Verbose -Message "$FileCount Files were identified in the source Actions directory"
			}
			else
			{
				Write-Warning -Message "No scripts were found in the source Actions directory"; break
			}
		}		
	}
	Catch [Exception]
	{
		Write-Warning -Message $_.Exception.Message; break
	}


if ($Uninstall){
        $Method = "Uninstall"
    }
    else {
        $Method = "Install"
    }
}
Process
{
	switch ($Method)
	{
		"Install" {
			foreach ($XMLFile in (Get-ChildItem -Path "$ScriptRoot\Actions" -Include *.xml -Recurse))
			{
				$GUID = $XMLFile.Directory.BaseName
				Write-Verbose "XML File Name: $($XMLFile.Name)"
				Write-Verbose "XML GUID Directory: $GUID"
				
				# Remove the existing XML File (if it exists)
				if (Test-Path -Path "$ActionsRoot\$GUID\$($XMLFile.Name)")
				{
					Try
					{
						Write-Verbose -Message "Removing $($XMLFile.Name) from $ActionsRoot\$GUID"
						Remove-Item -Path "$ActionsRoot\$GUID\$($XMLFile.Name)" -Force -ErrorAction Stop
					}
					Catch
					{
						Write-Warning -Message "Unable to remove existing XML File from $ActionsRoot\$GUID\$($XMLFile.Name)"
						Write-Warning $_.Exception.Message
					}
				}
				
				# Edit the script path within the XML file and write the XML file out to the destination directory
				New-Item -Path "$ActionsRoot\$GUID" -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
				Write-Verbose -Message "Modifying XML File: '$($XMLFile.Name)'"
				Get-Content $XMLFile.FullName | ForEach-Object{
					$Line = $_
					$Line = $Line.Replace("$StringToReplace", "$Path")
					$Line | Out-File "$ActionsRoot\$GUID\$($XMLFile.Name)" -Append
				}
			}
			
			# Copy script over to the specified Scripts folder
			foreach ($Script in (Get-ChildItem -Path "$ScriptRoot\Scripts" -Recurse))
			{
				if (Test-Path -Path "$Path\$($Script.Name)")
				{
					Try
					{
						Write-Verbose "Copying Script File '$($Script.Name)' to $Path'"
						Copy-Item -Path $Script.FullName -Destination $Path -Force -ErrorAction Stop -Confirm
						
					}
					Catch
					{
						Write-Warning "Unable to copy '$($Script.Name)' to $Path"
						Write-Warning $_.Exception.Message
					}
				}
				else{
					Try
					{
						Write-Verbose "Copying Script File '$($Script.Name)' to $Path'"
						Copy-Item -Path $Script.FullName -Destination $Path -Force -ErrorAction Stop
						
					}
					Catch
					{
						Write-Warning "Unable to copy '$($Script.Name)' to $Path"
						Write-Warning $_.Exception.Message
					}
				}
			}
			
		}
		"Uninstall" {
			# Remove XML file(s)
			foreach ($XMLFile in (Get-ChildItem -Path "$ScriptRoot\Actions" -Include *.xml -Recurse))
			{
				$GUID = $XMLFile.Directory.BaseName
				
				# Remove the existing XML File (if it exists)
				if (Test-Path -Path "$ActionsRoot\$GUID\$($XMLFile.Name)")
				{
					Try
					{
						Write-Verbose -Message "Removing $($XMLFile.Name) from $ActionsRoot\$GUID"
						Remove-Item -Path "$ActionsRoot\$GUID\$($XMLFile.Name)" -Force -ErrorAction Stop
					}
					Catch
					{
						Write-Warning -Message "Unable to remove existing XML File from $ActionsRoot\$GUID\$($XMLFile.Name)"
						Write-Warning $_.Exception.Message
					}
				}
			}
			
			# Remove Script Files from the Path specified
			foreach ($Script in (Get-ChildItem -Path "$ScriptRoot\Scripts" -Recurse))
			{
				if (Test-Path -Path "$Path\$($Script.Name)")
				{
					$ScriptToRemove = Get-Item "$Path\$($Script.Name)"
					Try
					{
						Write-Verbose "Removing Script File '$($Script.Name)' from $Path'"
						Remove-Item -Path $ScriptToRemove.FullName -Force -ErrorAction Stop
						
					}
					Catch
					{
						Write-Warning "Unable to remove '$($Script.Name)' from $Path"
						Write-Warning $_.Exception.Message
					}
				}
			}
		}
	}
}