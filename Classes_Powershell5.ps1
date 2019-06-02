Class MyViewModel : UI.SViewModel
{
    #Array with DataBinding capabilities
    [System.Collections.ObjectModel.ObservableCollection[Object]]$SoftwareObjects;
    [System.Collections.ObjectModel.ObservableCollection[Object]]$ModList;
    [String]$SelectedMod;
    [String]$SearchBox;
    [String]$ModName;
    [String]$ModDesc;
    [Boolean]$ModIsInstalled;
    [Boolean]$ModHasConfig
    [System.Collections.ObjectModel.ObservableCollection[Object]]$ModVersion;
    [Object]$SelectedVersion;

    MyViewModel()
    {
        
    }

<#
example stuff
    SetTest([String]$NewValue)
    {
        $this.Test = $NewValue;
        $this.NotifyPropertyChanged("Test");
    }
#>
}
