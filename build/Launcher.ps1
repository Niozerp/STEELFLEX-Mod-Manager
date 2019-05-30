<#
.AUTHOR
Niozerp
Sagebreaker

.VERSION
0.2
#>


#Get script location
$global:InstallPath = Split-Path $MyInvocation.MyCommand.Path
#Static variables
$VIEW_NAME = "BaseView.xaml";
Add-Type -Path "$InstallPath\classes\BaseViewModel.cs";
. "$InstallPath\classes\Classes_Powershell5.ps1";

$global:ViewModel = [MyViewModel]::new();

#Master function
Function Main()
{
    LoadAssemblies;
    InitDisplay;
    CreateButtonListeners;
    DisplayWindow;
}

# --- Import core assembly ---
Function LoadAssemblies()
{
    Add-Type -AssemblyName "PresentationFramework";
    Add-Type -AssemblyName "System.Windows.Forms";
}

# --- Setting up the window and loading XAML ---
Function InitDisplay()
{
    $Xaml = [XML](Get-Content "$InstallPath\view\$VIEW_NAME");
    $XamlReader = New-Object System.Xml.XmlNodeReader $Xaml;
    $global:Window = [Windows.Markup.XamlReader]::Load($XamlReader);
}

# --- Functions ---
Function DisplayWindow()
{
    $global:Window.DataContext = $ViewModel;
    $global:Window.ShowDialog();
}


Function Get-Folder($initialDirectory){
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms")|Out-Null

    $foldername = New-Object System.Windows.Forms.FolderBrowserDialog
    $foldername.Description = "Select a folder"
    $foldername.rootfolder = "MyComputer"

    if($foldername.ShowDialog() -eq "OK")
    {
        $folder += $foldername.SelectedPath
    }
    return $folder
}

Function Get-ModList{
    $APILink = "https://thunderstore.io/api/v1/package"
    $ModList = "ror2download.json"
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Return Invoke-WebRequest -Uri $APILink -OutFile "$env:TEMP\$ModList" -PassThru | ConvertFrom-Json
}

function Install-Mod($ModURL,$ModLocation){
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    try{ Invoke-WebRequest -Uri $ModURL -OutFile $ModLocation }catch{return "$($Error[0])"}
}

function Disable-Mod($ModLocation){
    

}

function Get-BepInEx($ror2loc,$BepURL){
    New-Item -ItemType Directory -Path "$env:TEMP\RoR2downloads" -Force | Out-Null
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $BepURL -OutFile "$env:TEMP\RoR2downloads\BepInEx.zip" | Out-Null
    Expand-Archive -Path "$env:TEMP\RoR2downloads\BepInEx.zip" -DestinationPath "$env:TEMP\RoR2downloads\" | Out-Null
    Copy-Item -Path "$env:TEMP\RoR2downloads\BepInExPack\BepInEx" -Destination "$ror2loc\" -Force | Out-Null
    Copy-Item -Path "$env:TEMP\RoR2downloads\BepInExPack\doorstop_config.ini" -Destination "$ror2loc\doorstop_config.ini" -Force | Out-Null
    Copy-Item -Path "$env:TEMP\RoR2downloads\BepInExPack\winhttp.dll" -Destination "$ror2loc\winhttp.dll" -Force | Out-Null
    Remove-Item -Path "$env:TEMP\RoR2downloads" -Recurse -Force | Out-Null
}

# --- Establishing the list and game location --- 

if(Test-Path "$env:APPDATA\RoR2\Install.md"){
    $ror2loc = Get-Content "$env:APPDATA\RoR2\Install.md"
}else{
    $ror2loc = Get-Folder -initialDirectory 'C:\'
    New-Item -Path $env:APPDATA -ItemType Directory -Name 'RoR2'
    $ror2loc | Out-File -FilePath "$env:APPDATA\RoR2\Install.md"
    }

$Mods = ((Get-ModList) | Sort-Object -Property name)

foreach($mod in $Mods){
    $global:ViewModel.ModList += $mod.name
}
$global:ViewModel.NotifyPropertyChanged("ModList")

$global:ViewModel.ModIsInstalled = $false
$global:ViewModel.NotifyPropertyChanged("ModIsInstalled");

# --- Button Binding ---
Function CreateButtonListeners(){
    #Button Declaration
    $Update_Button = $global:Window.FindName('Update_Button');
    $Install_BepInEx = $global:Window.FindName('Install_bepinex');
    $Install_Button = $global:Window.FindName('Install_Button');
    $Disable_Button = $global:Window.FindName('Disable_Button');
    $Config_Button = $global:Window.FindName('Config_Button');
    $Test_Button = $global:Window.FindName('Test_Button');

    #grabs the most recent version of BepIsEx and installs it
    $Install_BepInEx.Add_Click({
        $Beps = $(($Mods | select -ExpandProperty versions| where name -Like 'BepInExPack') | Sort-Object version_number -Descending)
        Get-BepInEx -ror2loc $ror2loc -BepURL $Beps[0].download_url
    })

    $SelectionListener = [System.Windows.Controls.Primitives.Selector]::SelectionChangedEvent

    $Test_Button.Add_Click({
        $global:viewModel.ModVersion = $null
        $global:ViewModel.NotifyPropertyChanged("ModVersion");
        $currentmod = $(($Mods | Select -ExpandProperty versions | where name -EQ $global:ViewModel.SelectedMod) | Sort-Object version_number -Descending)
        $global:ViewModel.ModName = $currentmod[0].name
        $global:viewModel.ModDesc = $currentmod[0].description
        foreach($modVer in $currentmod){
            $global:viewModel.ModVersion += $modVer.version_number
        }
        $global:ViewModel.NotifyPropertyChanged("ModName");
        $global:ViewModel.NotifyPropertyChanged("ModDesc");
        $global:ViewModel.NotifyPropertyChanged("ModVersion");
    })
  

    $Mod_Selected = $global:Window.FindName('Mod_List');
    $Mod_Selected.add_SourceUpdated.({
        $currentmod = $(($Mods | Select -ExpandProperty versions | where name -EQ $global:ViewModel.Selected_Mod) | Sort-Object version_number -Descending)
        $global:ViewModel.Mod_Name = $currentmod[0].name
        $global:viewModel.Mod_Desc = $currentmod[0].description
        foreach($modVer in $currentmod){
            $global:ViewModel.Mod_Version += $modVer.version_number
        }
        $global:ViewModel.NotifyPropertyChanged("Mod_Name");
        $global:ViewModel.NotifyPropertyChanged("Mod_Desc");
        $global:ViewModel.NotifyPropertyChanged("Mod_Version");

    })
}



Main;