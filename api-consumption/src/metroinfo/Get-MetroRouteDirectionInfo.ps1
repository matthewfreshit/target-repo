Set-StrictMode -Version 'Latest'

function Get-MetroRouteDirectionInfo {
    <#
    .SYNOPSIS
        Gets direction information for the specified bus stop.
    .DESCRIPTION
        Get-MetroRouteDirectionInfo will return direction information for the specified bus stop.
    .PARAMETER BusRouteId
        The bus route id assocaited with a valid bus route.
    .PARAMETER Direction
        Direction of the desired bus stop.
    .EXAMPLE
        Get-MetroRouteDirectionInfo -BusRouteId '901' -Direction 'north'

        This will return the direction information for bus route '901' and direction 'north'.
    #>

    Param (
        [Parameter(Mandatory = $true,
            HelpMessage = "The bus route id assocaited with a valid bus route." )]
        [ValidateNotNullOrEmpty()]
        [string]$BusRouteId,
        [Parameter(Mandatory = $true,
            HelpMessage = "Direction of the bus route" )]
        [ValidateSet('north', 'east', 'west', 'south', IgnoreCase = $true)]
        [string]$Direction
    )

    Write-Verbose -Message "Starting $($MyInvocation.MyCommand.Name)"

    Write-Verbose -Message ("Getting Bus route direction info for route id '{0}'" -f $BusRouteId)
    try {
        $directionEndpoint = "directions/$BusRouteId"
        $directionInfo = Invoke-MetroAPIRequest -EndpointPath $directionEndpoint -IsNextTripV2 `
            | Where-Object { $_.direction_name -ilike "$Direction*" } `
            | Select-Object @{N = 'DirectionId'; E = { $_.direction_id } }, @{N = 'DirectionName'; E = { $_.direction_name } } 
        if ([string]::IsNullOrEmpty($directionInfo)) {
            throw "No busses on this route are going in the specified direction '{0}'" -f $Direction
        }
        $directionInfo
    }
    catch {
        throw "Error getting bus route direction info for route id '{0}' -> {1}" -f $BusRouteId, $_.Exception.Message
    }
    finally {
        Write-Verbose -Message "Finished $($MyInvocation.MyCommand.Name)"
    }
}

Export-ModuleMember -Function Get-MetroRouteDirectionInfo