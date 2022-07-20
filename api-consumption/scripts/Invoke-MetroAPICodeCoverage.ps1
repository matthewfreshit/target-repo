#Requires -Version 5
#Requires -Modules @{ ModuleName='Pester'; MaximumVersion='4.10.1' }
Set-StrictMode -Version 'Latest';

function Invoke-MetroAPICodeCoverage {
    try{
        Import-Module -Name Pester -MaximumVersion '4.10.1'
    } catch {
        Write-Host 'Pester module not found. Please install Pester module.'
        Install-Module Pester -MaximumVersion 4.10.1 -Repository PSGallery -Scope CurrentUser -Force
        Import-Module -Name Pester -MaximumVersion '4.10.1'
    }
    
    [string] $script:root = Split-Path -Path $PSScriptRoot -Parent
    [string] $script:src = "$($script:root)/src";
    [string] $script:test = "$($script:root)/test";
    
    #Invoke-Pester -Path $script:root
    Invoke-Pester -Script "$($script:test)\Get-MetroAllBusRoutes.Tests.ps1" -CodeCoverage "$($script:src)\metroinfo\Get-MetroAllBusRoutes.ps1"
    Invoke-Pester -Script "$($script:test)\Get-MetroBusRouteDirectionInfo.Tests.ps1" -CodeCoverage "$($script:src)\metroinfo\Get-MetroBusRouteDirectionInfo.ps1"
    Invoke-Pester -Script "$($script:test)\Get-MetroBusRouteInfo.Tests.ps1" -CodeCoverage "$($script:src)\metroinfo\Get-MetroBusRouteInfo.ps1"
    Invoke-Pester -Script "$($script:test)\Get-MetroBusStopInfo.Tests.ps1" -CodeCoverage "$($script:src)\metroinfo\Get-MetroBusStopInfo.ps1"
    Invoke-Pester -Script "$($script:test)\Get-MetroBusStopScheduleInfo.Tests.ps1" -CodeCoverage "$($script:src)\metroinfo\Get-MetroBusStopScheduleInfo.ps1"
    Invoke-Pester -Script "$($script:test)\Invoke-MetroAPIRequest.Tests.ps1" -CodeCoverage "$($script:src)\common\Invoke-MetroAPIRequest.ps1"
    Invoke-Pester -Script "$($script:test)\Get-MetroBusNextTrip.Tests.ps1" -CodeCoverage "$($script:src)\Get-MetroBusNextTrip.ps1"
}

Export-ModuleMember -Function Invoke-MetroAPICodeCoverage