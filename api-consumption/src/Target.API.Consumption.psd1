@{
    RootModule            = 'Target.API.Consumption.psm1'
    Author                = 'Matthew Leleux'
    Description           = 'Target Case Study Project - API Consumption'
    PowerShellVersion     = '5.1'
    ProcessorArchitecture = 'None'
    FunctionsToExport     = '*'
    CmdletsToExport       = '*'
    VariablesToExport     = '*'
    AliasesToExport       = '*'
    FileList              = @(
        './Get-MetroBusNextTrip.ps1',
        './common/Invoke-MetroAPIRequest.ps1',
        './metroinfo/Get-MetroAllBusRoutes.ps1',
        './metroinfo/Get-MetroBusRouteInfo.ps1',
        './metroinfo/Get-MetroBusStopInfo.ps1',
        './metroinfo/Get-MetroBusStopScheduleInfo.ps1',
        './metroinfo/Get-MetroBusRouteDirectionInfo.ps1'
    )
    PrivateData           = @{
        PSData = @{
            Tags       = @('Target', 'matthewfreshit')
            ProjectUri = 'https://github.com/matthewfreshit/target-repo/api-consumption'
        }
    }
}
