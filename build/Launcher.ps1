<#
.AUTHOR
Niozerp
Sagebreaker

.VERSION
0.7
#>


#Get script location
$global:InstallPath = Split-Path $MyInvocation.MyCommand.Path
#Static variables
$VIEW_NAME = "BaseView.xaml";
Add-Type -Path "$InstallPath\classes\BaseViewModel.cs";
. "$InstallPath\classes\Classes_Powershell5.ps1";

$global:ViewModel = [MyViewModel]::new();

#Master function
Function Main(){
    LoadAssemblies;
    InitDisplay;
    CreateButtonListeners;
    DisplayWindow;
}

# --- Import core assembly ---
Function LoadAssemblies(){
    Add-Type -AssemblyName "PresentationFramework";
    Add-Type -AssemblyName "System.Windows.Forms";
}

# --- Setting up the window and loading XAML ---
Function InitDisplay(){
    $Xaml = [XML](Get-Content "$InstallPath\view\$VIEW_NAME");
    $XamlReader = New-Object System.Xml.XmlNodeReader $Xaml;
    $global:Window = [Windows.Markup.XamlReader]::Load($XamlReader);
}

# --- Functions ---
Function DisplayWindow(){
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
    Try{
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Return Invoke-WebRequest -Uri $APILink -OutFile "$env:TEMP\$ModList" -PassThru | ConvertFrom-Json
    }Catch{
        if(test-path "$env:temp\$modlist"){
            Return Get-Content "$env:temp\$modlist" | Out-String | ConvertFrom-Json
        }else{
            Return "Uanble to pull mod list. Check your internet connection."
        }
    }
}

function Install-Mod($ModURL,$SaveLocation,$ModName,$ror2loc){
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    try{ Invoke-WebRequest -Uri $ModURL -OutFile "$SaveLocation\$ModName.zip" }catch{return "$($Error[0])"}
    Expand-Archive -Path "$SaveLocation\$ModName.zip" -DestinationPath "$ror2loc\BepInEx" -Force -ErrorAction SilentlyContinue
}

function Disable-Mod($ModLocation,$ror2loc){
    if(Test-Path -Path "$ror2loc\DisabledMods"){
        Get-ChildItem "$ModLocation" -Recurse | Move-Item -Destination "$ror2loc\DisabledMods" -Force
    }else{
        New-Item -ItemType Directory -Path "$ror2loc\DisabledMods" -Force
        Get-ChildItem "$ModLocation" -Recurse | Move-Item -Destination "$ror2loc\DisabledMods" -Force
    }
    
}

function get-ModConfig($ModConfigLocation){
    notepad.exe $ModConfigLocation | Out-Null
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

function Get-InstalledMods($ror2loc){
   $installedModFolders = Get-ChildItem -Path "$ror2loc\BepInEx\plugins"
   $InstalledMods = @()
   foreach($modFolder in $installedModFolders){
        $name = $modFolder.Name
        $m = $name.Split('-')
        $res = @{'name' = $m[2]}
        $res.owner = $m[1]
        $res.version_number = $m[3]
        $res.install_path = $modFolder.FullName
        $res.full_name = $modFolder.Name
        $InstalledMods += [PSCustomObject]$res
   }
    return $InstalledMods
}

function Find-ModConfig($ror2loc,$ModName){
    $configFiles = Get-ChildItem -Path "$ror2loc\BepInEx\config"
    if([boolean]($configFiles.name -like "*$ModName*")){
        return $configFiles.fullname -like "*$ModName*"
    }else{
        return $null
    }
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
$InstalledMods = ((Get-InstalledMods $ror2loc) | Sort-Object -Property name)

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
    $View_Button = $global:Window.FindName('View_Button');

    #grabs the most recent version of BepIsEx and installs it
    $Install_BepInEx.Add_Click({
        $Beps = $(($Mods | select -ExpandProperty versions| where name -Like 'BepInExPack') | Sort-Object version_number -Descending)
        Get-BepInEx -ror2loc $ror2loc -BepURL $Beps[0].download_url
    })

    $View_Button.Add_Click({
        $global:viewModel.ModVersion = $null
        $global:ViewModel.NotifyPropertyChanged("ModVersion");
        $currentmod = $(($Mods | Select -ExpandProperty versions | where name -EQ $global:ViewModel.SelectedMod) | Sort-Object version_number -Descending)
        $global:ViewModel.ModName = $currentmod[0].name #+ [String]$currentmod[0].description
        $global:viewModel.ModDesc = [String]$currentmod[0].description
        foreach($modVer in $currentmod){
            $global:ViewModel.ModVersion += $modVer.version_number
        }
        if([boolean]($InstalledMods.name -like "*$($global:ViewModel.SelectedMod)*")){
            $global:ViewModel.ModIsInstalled = $true
        }else{
            $global:ViewModel.ModIsInstalled = $false
        }
        $ModConfigFile = Find-ModConfig -ModName $global:ViewModel.SelectedMod -ror2loc $ror2loc
        if($ModConfigFile -ne $null){
            $global:ViewModel.ModHasConfig = $true
        }else{
            $global:ViewModel.ModHasConfig = $false
        }
        $global:ViewModel.NotifyPropertyChanged("ModName");
        $global:ViewModel.NotifyPropertyChanged("ModDesc");
        $global:ViewModel.NotifyPropertyChanged("ModVersion");
        $global:ViewModel.NotifyPropertyChanged("ModIsInstalled");
        $global:ViewModel.NotifyPropertyChanged("ModHasConfig");
    })

    $Install_Button.Add_Click({})

    $Disable_Button.Add_Click({})

    $Config_Button.Add_Click({
        $ModConfigFile = Find-ModConfig -ModName $global:ViewModel.ModName -ror2loc $ror2loc
        get-ModConfig -ModConfigLocation $ModConfigFile
    })

}



Main;