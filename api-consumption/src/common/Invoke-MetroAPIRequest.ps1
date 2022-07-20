Set-StrictMode -Version 'Latest'

function Invoke-MetroAPIRequest {
    <#
    .SYNOPSIS
        Gets all valid route information for the metro transit.
    .DESCRIPTION
        Invoke-MetroAPIRequest will return all valid route info for the metro transit.
    .PARAMETER Origin
        Origin info the the Metro Transit API
    .PARAMETER EndpointPath
        Path to the requested endpoint
    .PARAMETER IsNextTripV2
        Switch for 'nextripv2' route
    .PARAMETER IsAlerts
        Switch for 'alerts' route
    .PARAMETER IsTripPlanner
        Switch for 'tripplanner' route
    .PARAMETER IsSchedule
        Switch for 'schedule' route
    .EXAMPLE
        Invoke-MetroAPIRequest -Origin 'https://example.svc.org' -EndpointPath 'routes' -IsSchedule

        This will return all bus routes from the 'schedule' route from origin 'https://example.svc.org'.
    .EXAMPLE
        Invoke-MetroAPIRequest -EndpointPath 'routes' -IsNextTripV2

        This will return all bus routes from the 'nextripv2' route.
    .EXAMPLE
        Invoke-MetroAPIRequest -EndpointPath 'all' -IsAlerts

        This will return all alerts from the 'alerts' route.
    .EXAMPLE
        Invoke-MetroAPIRequest -EndpointPath 'findaddress/magickey' -IsTripPlanner

        This will return the address matching magic key from the 'tripplanner' route.
    #>

    Param (
        [Parameter(Mandatory = $false,
            HelpMessage = "Origin info the the Metro Transit API" )]
        [ValidateNotNullOrEmpty()]
        [string]$Origin = 'https://svc.metrotransit.org',
        [Parameter(Mandatory = $true,
            HelpMessage = "Endpoint path info" )]
        [ValidateNotNullOrEmpty()]
        [string]$EndpointPath,
        [Parameter(ParameterSetName = 'NextTrip', Mandatory = $true,
            HelpMessage = "Switch for 'nextripv2' route" )]
        [switch]$IsNextTripV2,
        [Parameter(ParameterSetName = 'Alerts', Mandatory = $true,
            HelpMessage = "Switch for 'alerts' route")]
        [switch]$IsAlerts,
        [Parameter(ParameterSetName = 'TripPlanner', Mandatory = $true,
            HelpMessage = "Switch for 'tripplanner' route")]
        [switch]$IsTripPlanner,
        [Parameter(ParameterSetName = 'Schedule', Mandatory = $true,
            HelpMessage = "Switch for 'schedule' route")]
        [switch]$IsSchedule
    )

    Write-Verbose -Message "Starting $($MyInvocation.MyCommand.Name)"
    $selectedRoute = $null
    foreach ($parm in $PSBoundParameters.GetEnumerator()) {
        if ($parm.Value -is [switch]) {
            $selectedRoute = switch ($parm.Key) {
                'IsNextTripV2' { 'nextripv2' }
                'IsAlerts' { 'alerts' }
                'IsTripPlanner' { 'tripplanner' }
                'IsSchedule' { 'schedule' }
            }
        }
    }
    $uri = "$Origin/$selectedRoute/$EndpointPath"
    Write-Verbose -Message ("Web request to {0}" -f $uri)
    try {
        $returnInfo = (Invoke-WebRequest -Uri $uri).Content | ConvertFrom-Json
        $returnInfo 
    }
    catch {
        if($_.ErrorDetails){
            $errResponse = $_.ErrorDetails.Message | ConvertFrom-Json
            throw $errResponse.detail
        } else {
            throw $_.Exception.Message
        }
    }
}

Export-ModuleMember -Function Invoke-MetroAPIRequest