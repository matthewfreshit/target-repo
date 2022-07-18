Set-StrictMode -Version 'Latest'

function Get-MetroBusRouteInfo {
    <#
    .SYNOPSIS
        Gets information for the specified bus route.
    .DESCRIPTION
        Get-MetroBusRouteInfo will return the information for the specified bus route.
    .PARAMETER BusRouteName
        Full/Partial name of the desired bus route.
    .EXAMPLE
        Get-MetroBusRouteInfo -BusRouteName 'METRO Blue'

        This will return the information for the 'METRO Blue' bus route.
    #>

    Param (
        [Parameter(Mandatory = $true,
            HelpMessage = "A substring of (or entire) bus route name which is only in one bus route" )]
        [ValidateNotNullOrEmpty()]
        [string]$BusRouteName
    )

    Write-Verbose -Message "Starting $($MyInvocation.MyCommand.Name)"

    Write-Verbose -Message ("Getting Bus Routes info for '{0}'" -f $BusRouteName)
    try {
        $busRouteInfo = Get-MetroAllBusRoutes | Where-Object { $_.RouteLabel -ilike "*$BusRouteName*" }
        if ([string]::IsNullOrEmpty($busRouteInfo)) {
            throw "No bus route found for given bus route name"
        }
        if (($busRouteInfo | Measure-Object).Count -gt 1) {
            throw "More than one bus route was found by given bus route name. Please refine your search criteria."
        }
        $busRouteInfo
    }
    catch {
        throw "Error getting bus route info for specified route '{0}' -> {1}" -f $BusRouteName, $_.Exception.Message
    }
    finally {
        Write-Verbose -Message "Finished $($MyInvocation.MyCommand.Name)"
    }
}

Export-ModuleMember -Function Get-MetroBusRouteInfo