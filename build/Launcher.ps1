##[Ps1 To Exe]
##
##NcDBCIWOCzWE8paP3wdDwG7CZEQOVvmojZOC6KeQ2tKhlirdBLcVR1VwkzvABl60VfYud/QGsecYUApkN/MG7tI=
##NcDBCIWOCzWE8paP3wdDwG7CZEQOVvmojZOC6KeQ2tKhlirdBLcVR1VwkzvABl60VfYud/QGsecYUAoHIPYO7vzTCIc=
##NcDBCIWOCzWE8paP3wdDwG7CZEQOVvmojZOC6KeQ2tKhlirdBLcVR1VwkzvABl60VfYudvkUp8IURiIaIOUO8KHYHuulEOwagbIf
##Kd3HDZOFADWE8uK1
##Nc3NCtDXThU=
##Kd3HFJGZHWLWoLaVvnQnhQ==
##LM/RF4eFHHGZ7/K1
##K8rLFtDXTiW5
##OsHQCZGeTiiZ4NI=
##OcrLFtDXTiW5
##LM/BD5WYTiiZ4tI=
##McvWDJ+OTiiZ4tI=
##OMvOC56PFnzN8u+VslQ=
##M9jHFoeYB2Hc8u+VslQ=
##PdrWFpmIG2HcofKIo2QX
##OMfRFJyLFzWE8uK1
##KsfMAp/KUzWI0g==
##OsfOAYaPHGbQvbyVvnQX
##LNzNAIWJGmPcoKHc7Do3uAu/DDllPaU=
##LNzNAIWJGnvYv7eVvnRE0W7Lbk4HS/22trKKxY+9+O/+2w==
##M9zLA5mED3nfu77Q7TV64AuzAgg=
##NcDWAYKED3nfu77Q7TV64AuzAgg=
##OMvRB4KDHmHQvbyVvnQX
##P8HPFJGEFzWE8pvb5zFk5lnnQGkpYsDbkLijzZKo7ePpqEU=
##KNzDAJWHD2fS8u+Vgw==
##P8HSHYKDCX3N8u+Vgw==
##LNzLEpGeC3fMu77Ro2k3hQ==
##L97HB5mLAnfMu77Ro2k3hQ==
##P8HPCZWEGmaZ7/K1
##L8/UAdDXTlGDjoHhxhFbw2fLelQYWuC+lZCL4bnx0uXo9gjYR5sTTEZLpR3ZIWebddcqFdgasJE8VBMrKPcZrLfIHoc=
##Kc/BRM3KXBU=
##
##
##fd6a9f26a06ea3bc99616d4851b372ba
<#
.AUTHOR
Niozerp
Sagebreaker

.VERSION
1.1.4
#>


#Get script location
#change when making an executable
$global:InstallPath = [Environment]::CurrentDirectory
#$global:InstallPath = Split-Path $MyInvocation.MyCommand.Path
#Static variables
$VIEW_NAME = "BaseView.xaml";
Add-Type -Path "$InstallPath\BaseViewModel.cs";
. "$InstallPath\Classes_Powershell5.ps1";

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
    $Xaml = [XML](Get-Content "$InstallPath\$VIEW_NAME");
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

function Install-Mod($ModObject,$SaveLocation,$ror2loc,$owner){
    $ModURL = $ModObject.download_url
    $ModName = $ModObject.name
    $InstallName = "smm-$owner-$($ModObject.name)-$($ModObject.version_number)"
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    try{ Invoke-WebRequest -Uri $ModURL -OutFile "$SaveLocation\$ModName.zip" }catch{return "$($Error[0])"}
    Expand-Archive -Path "$SaveLocation\$ModName.zip" -DestinationPath "$ror2loc\BepInEx\plugins\$InstallName" -Force #-ErrorAction SilentlyContinue
}

function Disable-Mod($ModLocation,$ror2loc){
    if(Test-Path -Path "$ror2loc\DisabledMods"){
        Move-Item -Path $ModLocation -Destination "$ror2loc\DisabledMods" -Force
    }else{
        New-Item -ItemType Directory -Path "$ror2loc\DisabledMods" -Force
        Move-Item -Path $ModLocation -Destination "$ror2loc\DisabledMods" -Force
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
   try{
        $installedModFolders = Get-ChildItem -Path "$ror2loc\BepInEx\plugins" -ErrorAction stop
   }catch{
        return [PSCustomObject]$res
   }
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
    $global:ror2loc = Get-Content "$env:APPDATA\RoR2\Install.md"
}else{
    $global:ror2loc = Get-Folder -initialDirectory 'C:\'
    New-Item -Path $env:APPDATA -ItemType Directory -Name 'RoR2'
    $global:ror2loc | Out-File -FilePath "$env:APPDATA\RoR2\Install.md"
    }

$global:Mods = ((Get-ModList) | Sort-Object -Property name)
$global:InstalledMods = ((Get-InstalledMods $global:ror2loc) | Sort-Object -Property name)

foreach($mod in $global:Mods){
    $global:ViewModel.ModList += $mod.name
}
$global:ViewModel.NotifyPropertyChanged("ModList")

$global:ViewModel.ModIsInstalled = $false
$global:viewModel.ModHasConfig = $false
$global:ViewModel.NotifyPropertyChanged("ModIsInstalled");
$global:ViewModel.NotifyPropertyChanged("ModHasConfig");

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
    $Update_Button.Add_Click({
        $global:Mods = ((Get-ModList) | Sort-Object -Property name)
        $global:InstalledMods = ((Get-InstalledMods $global:ror2loc) | Sort-Object -Property name)

        foreach($mod in $global:Mods){
        $global:ViewModel.ModList += $mod.name
        }
        $global:ViewModel.NotifyPropertyChanged("ModList")

    })

    $Install_BepInEx.Add_Click({
        $Beps = $(($global:Mods | select -ExpandProperty versions| where name -Like 'BepInExPack') | Sort-Object version_number -Descending)
        Get-BepInEx -ror2loc $global:ror2loc -BepURL $Beps[0].download_url
    })

    $View_Button.Add_Click({
        $global:InstalledMods = ((Get-InstalledMods $global:ror2loc) | Sort-Object -Property name)
        $global:viewModel.ModVersion = $null
        $global:ViewModel.NotifyPropertyChanged("ModVersion");
        $currentmod = $(($global:Mods | Select -ExpandProperty versions | where name -EQ $global:ViewModel.SelectedMod) | Sort-Object version_number -Descending)
        $global:ViewModel.ModName = $currentmod[0].name #+ [String]$currentmod[0].description
        $global:viewModel.ModDesc = [String]$currentmod[0].description
        $global:ViewModel.SelectedVersion = $currentmod[0].version_number
        foreach($modVer in $currentmod){
            $global:ViewModel.ModVersion += $modVer.version_number
        }
        if([boolean]($global:InstalledMods.name -EQ "$($global:ViewModel.SelectedMod)")){
            $global:ViewModel.ModIsInstalled = $true
        }else{
            $global:ViewModel.ModIsInstalled = $false
        }
        $ModConfigFile = Find-ModConfig -ModName $global:ViewModel.SelectedMod -ror2loc $global:ror2loc
        if($ModConfigFile -ne $null){
            $global:ViewModel.ModHasConfig = $true
        }else{
            $global:ViewModel.ModHasConfig = $false
        }
        $global:ViewModel.NotifyPropertyChanged("ModName");
        $global:ViewModel.NotifyPropertyChanged("ModDesc");
        $global:ViewModel.NotifyPropertyChanged("ModVersion");
        $global:ViewModel.NotifyPropertyChanged("SelectedVersion");
        $global:ViewModel.NotifyPropertyChanged("ModIsInstalled");
        $global:ViewModel.NotifyPropertyChanged("ModHasConfig");
    })

    $Install_Button.Add_Click({
        $ModName = $global:ViewModel.ModName
        $currentmod = $($global:Mods | Select -ExpandProperty versions | where {($_.name -EQ $ModName) -and ($_.version_number -eq $global:ViewModel.SelectedVersion)})
        $owner = $($global:mods | Where name -EQ $ModName).owner
        $SaveLocation = "$env:APPDATA\RoR2\"

        Install-Mod -ModObject $currentmod -SaveLocation $SaveLocation -ror2loc $global:ror2loc -owner $owner

        $global:InstalledMods = ((Get-InstalledMods $global:ror2loc) | Sort-Object -Property name)

        #update the buttons
        if([boolean]($global:InstalledMods.name -EQ "$($global:ViewModel.ModName)")){
            $global:ViewModel.ModIsInstalled = $true
        }else{
            $global:ViewModel.ModIsInstalled = $false
        }
        $ModConfigFile = Find-ModConfig -ModName $global:ViewModel.ModName -ror2loc $global:ror2loc
        if($ModConfigFile -ne $null){
            $global:ViewModel.ModHasConfig = $true
        }else{
            $global:ViewModel.ModHasConfig = $false
        }
        $global:ViewModel.NotifyPropertyChanged("ModIsInstalled");
        $global:ViewModel.NotifyPropertyChanged("ModHasConfig");
    })

    $Disable_Button.Add_Click({
        $ModLocation  = $($global:InstalledMods | where name -EQ $global:ViewModel.ModName).install_path
        Disable-Mod -ModLocation $ModLocation -ror2loc $global:ror2loc

        $global:InstalledMods = ((Get-InstalledMods $global:ror2loc) | Sort-Object -Property name)
        if([boolean]($global:InstalledMods.name -EQ "$($global:ViewModel.ModName)")){
            $global:ViewModel.ModIsInstalled = $true
        }else{
            $global:ViewModel.ModIsInstalled = $false
        }
        $ModConfigFile = Find-ModConfig -ModName $global:ViewModel.ModName -ror2loc $global:ror2loc
        if($ModConfigFile -ne $null){
            $global:ViewModel.ModHasConfig = $true
        }else{
            $global:ViewModel.ModHasConfig = $false
        }
        $global:ViewModel.NotifyPropertyChanged("ModHasConfig");
        $global:ViewModel.NotifyPropertyChanged("ModIsInstalled");
    })

    $Config_Button.Add_Click({
        $ModConfigFile = Find-ModConfig -ModName $global:ViewModel.ModName -ror2loc $global:ror2loc
        get-ModConfig -ModConfigLocation $ModConfigFile
    })

}



Main;