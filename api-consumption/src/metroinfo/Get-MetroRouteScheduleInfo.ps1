Set-StrictMode -Version 'Latest'

function Get-MetroRouteScheduleInfo {
    <#
    .SYNOPSIS
        Gets direction information for the specified bus stop.
    .DESCRIPTION
        Get-MetroRouteScheduleInfo will return direction information for the specified bus stop.
    .PARAMETER BusRouteId
        The bus route id assocaited with a valid bus route.
    .PARAMETER Direction
        Direction of the desired bus stop.
    .EXAMPLE
        Get-MetroRouteScheduleInfo -BusRouteId '901' -Direction 'north'

        This will return the direction information for bus route '901' and direction 'north'.
    #>

    Param (
        [Parameter(Mandatory = $true,
            HelpMessage = "The bus route id assocaited with a valid bus route." )]
        [ValidateNotNullOrEmpty()]
        [string]$BusRouteId,
        [Parameter(Mandatory = $true,
            HelpMessage = "Direction of the bus route" )]
        [ValidateSet('north', 'east', 'west', 'south', IgnoreCase = $false)]
        [string]$Direction
    )

    Write-Verbose -Message "Starting $($MyInvocation.MyCommand.Name)"

    Write-Verbose -Message ("Getting Bus route direction info for route id '{0}'" -f $BusRouteId)
    try {
        $endpoint = "directions/$BusRouteId"
        $DirectionInfo = Invoke-MetroAPIRequest -EndpointPath $endpoint -IsNextTripV2 `
            | Where-Object { $_.direction_name -ilike "$Direction*" } `
            | Select-Object @{N = 'DirectionId'; E = { $_.direction_id } }, @{N = 'DirectionName'; E = { $_.direction_name } } 
        $DirectionInfo
    }
    catch {
        throw "Error getting bus route direction info for route id '{0}' -> {1}" -f $BusRouteId, $_.Exception.Message
    }
    finally {
        Write-Verbose -Message "Finished $($MyInvocation.MyCommand.Name)"
    }
}

Export-ModuleMember -Function Get-MetroRouteScheduleInfo