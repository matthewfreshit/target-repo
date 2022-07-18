Set-StrictMode -Version 'Latest'

function Get-MetroAllBusRoutes {
    <#
    .SYNOPSIS
        Gets all valid route information for the metro transit.
    .DESCRIPTION
        Get-MetroAllBusRoutes will return all valid route info for the metro transit.
    .EXAMPLE
        Get-MetroAllBusRoutes

        This will return all valid routes.
    #>

    Write-Verbose -Message "Starting $($MyInvocation.MyCommand.Name)"

    Write-Verbose -Message "Getting all Bus routes for the metro"
    $endpoint = "routes"
    $routesInfo = Invoke-MetroAPIRequest -EndpointPath $endpoint -IsNextTripV2 `
        | Select-Object @{N='RouteLabel'; E = {$_.route_label}}, @{N='RouteId'; E = {$_.route_id}}
    
    Write-Verbose -Message "Finished $($MyInvocation.MyCommand.Name)"
    $routesInfo 
}

Export-ModuleMember -Function Get-MetroAllBusRoutes