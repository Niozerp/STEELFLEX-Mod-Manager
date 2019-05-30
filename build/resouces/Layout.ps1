#Get-ModList
##Locate Risk of Rain 2 Directory
#Assume that script launched from the risk of rain 2 directory aka we should be able to Test-path .\risk of rain 2.exe and get true.
    #ask for the directory if this is not the case... with a pop up..?
#evaluate list of isntalled mods and ....with a clever use of regex determine their versions


#Button: Refresh List
<#
    Re-pulls Get-ModList and updates the list of mods
#>


#Button: Install Mod
<#
    .ARGS
        Version
        ModURL
        Location(Non-User interactive)
    .Process
        based on the version, pulls the location_url and downloads the file
        extracts the file into .\BepInEx\plugins\MODNAME
        Updates wheather or not the mod is installed on the user's computer
#>

#Button: Disable Mod
<#
    .ARGS
        ModName
        Bolean value of installation status
        ModLocation
    .Process
        Move the whole mod folder to some other folder outside of .\BepInEx\Plugins
#>

#Dropdown: Mod Version
<#
    .ARGS
        The previous versions of the mod
    .Process
        Set's the variable mod version, some how (function or status state)
#>

#Configure Mod
<#
    .ARGS
        Mod Location
        Existance of a configuration file
    .Process
        uses notepade.exe to open the config file
#>