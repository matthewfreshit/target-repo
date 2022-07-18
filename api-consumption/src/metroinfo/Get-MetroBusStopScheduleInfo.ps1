Set-StrictMode -Version 'Latest'

function Get-MetroBusStopScheduleInfo {
    <#
    .SYNOPSIS
        Gets information for the specified bus stop schedule.
    .DESCRIPTION
        Get-MetroBusStopScheduleInfo will return the information for the specified bus stops schedule based on PlaceCode.
    .PARAMETER PlaceCode
        Short code for the bus stop location.
    .PARAMETER BusRouteId
        The bus route id assocaited with a valid bus route.
    .PARAMETER DirectionId
        The bus route direction id assocaited with a valid bus route.
    .EXAMPLE
        Get-MetroBusStopScheduleInfo -PlaceCode 'HHTE' -BusRouteId '901' -DirectionId '1'

        This will return the schedule information for the 'HHTE' bus stop code on route '901'.
    #>

    Param (
        [Parameter(Mandatory = $true,
            HelpMessage = "Short code for the bus stop location." )]
        [ValidateNotNullOrEmpty()]
        [string]$PlaceCode,
        [Parameter(Mandatory = $true,
            HelpMessage = "The bus route id assocaited with a valid bus route." )]
        [ValidateNotNullOrEmpty()]
        [string]$BusRouteId,
        [Parameter(Mandatory = $true,
            HelpMessage = "The bus route direction id assocaited with a valid bus route." )]
        [ValidateNotNullOrEmpty()]
        [string]$DirectionId
    )

    Write-Verbose -Message "Starting $($MyInvocation.MyCommand.Name)"

    Write-Verbose -Message ("Getting Bus Stop info for place with code '{0}'" -f $PlaceCode)
    try {
        $endpoint = "$BusRouteId/$DirectionId/$PlaceCode"
        $scheduleInfo = Invoke-MetroAPIRequest -EndpointPath $endpoint -IsNextTripV2 

        $departureTimeInfo = $scheduleInfo | Select-Object -ExpandProperty departures `
            | Where-Object { $_.direction_id -eq $DirectionId -and $_.schedule_relationship -eq "Scheduled" } `
            | Select-Object @{N = 'DepartureTime'; E = { $_.departure_time } } -First 1

        [PSCustomObject]@{
            Alerts = $scheduleInfo.alerts
            DepartureTime = $departureTimeInfo.DepartureTime
        }
    }
    catch {
        throw "Error getting bus stop info for place code '{0}' -> {1}" -f $PlaceCode, $_.Exception.Message
    }
    finally {
        Write-Verbose -Message "Finished $($MyInvocation.MyCommand.Name)"
    }
}

Export-ModuleMember -Function Get-MetroBusStopScheduleInfo