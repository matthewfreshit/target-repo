Set-StrictMode -Version 'Latest'

function Invoke-MetroAPIRequest {
    <#
    .SYNOPSIS
        Gets all valid route information for the metro transit.
    .DESCRIPTION
        Invoke-MetroAPIRequest will return all valid route info for the metro transit.
    .PARAMETER Direction
        Direction of the desired bus stop.
    .EXAMPLE
        Invoke-MetroAPIRequest

        This will return all valid routes.
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
    $RespError = $null
    try {
        $returnInfo = (Invoke-WebRequest -Uri $uri -ErrorVariable RespError).Content | ConvertFrom-Json
        $returnInfo
    }
    catch {
        $jsonCorrected = [Text.Encoding]::UTF8.GetString([Text.Encoding]::GetEncoding(28591).GetBytes(($RespError[0].Message))) 
        $errResponse = $jsonCorrected | ConvertFrom-Json
        throw $errResponse.detail
    }
}

Export-ModuleMember -Function Invoke-MetroAPIRequest