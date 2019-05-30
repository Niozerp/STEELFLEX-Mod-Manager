Class MyViewModel : UI.SViewModel
{
    #Array with DataBinding capabilities
    [System.Collections.ObjectModel.ObservableCollection[Object]]$SoftwareObjects;
    [System.Collections.ObjectModel.ObservableCollection[Object]]$ModList;
    [String]$SelectedMod;
    [String]$SearchBox;
    [String]$ModName;
    [System.Collections.ObjectModel.ObservableCollection[Object]]$ModDesc;
    [Boolean]$ModIsInstalled;
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
