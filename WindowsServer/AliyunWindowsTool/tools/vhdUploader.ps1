# Get the ID and security principal of the current user account
$myWindowsID=[System.Security.Principal.WindowsIdentity]::GetCurrent()
$myWindowsPrincipal=new-object System.Security.Principal.WindowsPrincipal($myWindowsID)
  
# Get the security principal for the Administrator role
$adminRole=[System.Security.Principal.WindowsBuiltInRole]::Administrator
  
# Check to see if we are currently running "as Administrator"
if($myWindowsPrincipal.IsInRole($adminRole))
{
    # We are running "as Administrator" - so change the title and background color to indicate this
    $Host.UI.RawUI.WindowTitle = $myInvocation.MyCommand.Definition + "(Elevated)"
    $Host.UI.RawUI.BackgroundColor = "DarkBlue"
    clear-host
 }
 else
 {
    # We are not running "as Administrator" - so relaunch as administrator
    
    # Create a new process object that starts PowerShell
    $newProcess = new-object System.Diagnostics.ProcessStartInfo "PowerShell";
    
    # Specify the current script path and name as a parameter
    $newProcess.Arguments = $myInvocation.MyCommand.Definition;
    
    # Indicate that the process should be elevated
    $newProcess.Verb = "runas";
    
    # Start the new process
    [System.Diagnostics.Process]::Start($newProcess);
    
    # Exit from the current, unelevated, process
    exit
 }
  
function Check-NullOrEmpty
{
    Param ( [string] $string )
    if ([string]::IsNullOrEmpty($string)){
        break;
    }
}

function Install-PSModule
{
    Param ( [string] $moduleName )
    $module = Get-Module -Name $moduleName -ListAvailable
    if ($module -eq $null){
        Install-Module $moduleName -MaximumVersion 2.3.0 -Force
    }
}

Add-Type -AssemblyName Microsoft.VisualBasic
$subName = [Microsoft.VisualBasic.Interaction]::InputBox('Enter Azure Subscription Name', 'Subscription Name')
Check-NullOrEmpty($subName);
$storName = [Microsoft.VisualBasic.Interaction]::InputBox('Enter Azure Storage Account Name', 'Storage Name')
Check-NullOrEmpty($subName);
$localVhdPath = [Microsoft.VisualBasic.Interaction]::InputBox('Enter Local VHD Path like E:\win.vhd', 'Local Path')
Check-NullOrEmpty($localVhdPath);

$cloudEnvName = "AzureChinaCloud"
Install-PSModule AzureRm.Profile
Install-PSModule AzureRm.Compute
Install-PSModule AzureRm.Storage

$azureCred = Add-AzureRmAccount -EnvironmentName $cloudEnvName -SubscriptionName $subName

if ($azureCred -eq $null){
    Throw "Error in input credential. Please Try again."
}

$targetStor = Get-AzureRmStorageAccount | Where-Object { $_.StorageAccountName -eq $storName }
if ($targetStor -eq $null){
    Throw "Cannot find target storage account. Please try again."
}

$currentEnv = Get-AzureRmEnvironment -Name $cloudEnvName
$destUrl = "https://" + $storName +".blob." + $currentEnv.StorageEndpointSuffix + "/vhds/" + $localVhdPath.split('\')[-1]

Add-AzureRmVhd -ResourceGroupName $targetStor.ResourceGroupName -Destination $destUrl -LocalFilePath $localVhdPath

Write-Host "Vhd upload done!" -ForegroundColor Yellow

Write-Host "Press any key to continue ..."

$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") 