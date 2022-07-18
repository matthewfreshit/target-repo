Set-StrictMode -Version 'Latest'
function Get-MetroBusStopInfo {
    <#
    .SYNOPSIS
        Gets information for the specified bus stop.
    .DESCRIPTION
        Get-MetroBusStopInfo will return the information for the specified bus stop.
    .PARAMETER BusStopName
        Full/Partial name of the desired bus stop.
    .PARAMETER BusRouteId
        The bus route id assocaited with a valid bus route.
    .PARAMETER DirectionId
        The bus route direction id assocaited with a valid bus route.
    .EXAMPLE
        Get-MetroBusStopInfo -BusStopName 'Nicollet Mall Stat' -BusRouteId '901' -DirectionId '1'

        This will return the information for the 'Nicollet Mall Stat' bus stop.
    #>

    Param (
        [Parameter(Mandatory = $true,
            HelpMessage = "A substring of (or entire) bus stop name which is only in one bus stop on that route" )]
        [ValidateNotNullOrEmpty()]
        [string]$BusStopName,
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

    Write-Verbose -Message ("Getting Bus Stop info for '{0}'" -f $BusStopName)
    try {
        $endpoint = "stops/$BusRouteId/$DirectionId"
        $stopInfo = Invoke-MetroAPIRequest -EndpointPath $endpoint -IsNextTripV2 `
            | Where-Object {$_.description -ilike "*$BusStopName*"} `
            | Select-Object @{N = 'PlaceCode'; E = { $_.place_code } }, @{N = 'Description'; E = { $_.description } }
        if ([string]::IsNullOrEmpty($stopInfo)) {
            throw "No bus stop was found by given bus stop name."
        }
        if (($stopInfo | Measure-Object).Count -gt 1) {
            throw "More than one bus stop was found by given bus stop name. Please refine your search criteria."
        }
        $stopInfo 
    }
    catch {
        throw "Error getting bus stop info for '{0}' -> {1}" -f $BusStopName, $_.Exception.Message
    }
    finally {
        Write-Verbose -Message "Finished $($MyInvocation.MyCommand.Name)"
    }
}

Export-ModuleMember -Function Get-MetroBusStopInfo