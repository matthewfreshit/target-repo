Set-StrictMode -Version 'Latest'

function Get-MetroBusNextTrip {
    <#
    .SYNOPSIS
        Gets the time until next bus trip for a given stop in a given direction.
    .DESCRIPTION
        Get-MetroBusNextTrip will return the time until the next bus trip for a given stop in a given direction.
    .PARAMETER BusRouteName
        Full/Partial name of the desired bus route.
    .PARAMETER BusStopName
        Full/Partial name of the desired bus stop.
    .PARAMETER Direction
        Direction of the desired bus stop.
    .EXAMPLE
        Get-MetroBusNextTrip

        This will prompt the user for each of the inputs individually and return the time until the next bus will arive.
    .EXAMPLE
        Get-MetroBusNextTrip -BusRouteName 'METRO Blue' -BusStopName 'Nicollet Mall Stat' -Direction 'North'

        This will return the time until the next bus will arrive for the Target North Campus Building F in the North direction.
    #>

    Param (
        [Parameter(Mandatory = $false,
            HelpMessage = "A substring of (or entire) bus route name which is only in one bus route" )]
        [ValidateNotNullOrEmpty()]
        [string]$BusRouteName = (Read-Host -Prompt 'Enter bus route name'),
        [Parameter(Mandatory = $false,
            HelpMessage = "A substring of (or entire) bus stop name which is only in one bus stop on that route" )]
        [ValidateNotNullOrEmpty()]
        [string]$BusStopName = (Read-Host -Prompt 'Enter bus stop name'),
        [Parameter(Mandatory = $false,
            HelpMessage = "Direction of the bus route" )]
        [ValidateSet('north', 'east', 'west', 'south', IgnoreCase = $true)]
        [string]$Direction = (Read-Host -Prompt 'Enter bus direction (north, east, west, south)')
    )

    Write-Verbose -Message "Starting $($MyInvocation.MyCommand.Name)"
    try {
        $busRouteInfo = Get-MetroBusRouteInfo -BusRouteName $BusRouteName 

        $directionInfo = Get-MetroBusRouteDirectionInfo -BusRouteId $busRouteInfo.RouteId -Direction $Direction
    
        $busStopInfoSplat = @{
            BusStopName = $BusStopName;
            BusRouteId  = $busRouteInfo.RouteId;
            DirectionId = $directionInfo.DirectionId;
        }
    
        $busStopInfo = Get-MetroBusStopInfo @busStopInfoSplat
    
        $busStopScheduleInfoSplat = @{
            BusRouteId = $busRouteInfo.RouteId 
            DirectionId = $directionInfo.DirectionId 
            PlaceCode = $busStopInfo.PlaceCode
        }

        $busStopSchedule = Get-MetroBusStopScheduleInfo @busStopScheduleInfoSplat
    
        if (($busStopSchedule.Alerts | Measure-Object).Count -gt 0) {
            if ($busStopSchedule.Alerts.stop_closed -eq $true) {
                Write-Warning -Message "Bus stop is closed."
            }
            Write-Warning -Message ($busStopSchedule.Alerts.alert_text -join ' ')
        }
        if ([string]::IsNullOrEmpty($busStopSchedule.DepartureTime)) {
            Write-Warning -Message ("Bus route '{0}' has no more departures for stop '{1}' in '{2}' direction." `
                    -f $busRouteInfo.RouteLabel, $busStopInfo.Description, $directionInfo.DirectionName)
            return
        }
    
        Write-Verbose -Message "Calculating time until next trip."
    
        $localTime = (Get-Date).ToLocalTime()

        #Calculate the time until the next bus arrives by using the Epoch time as a base.
        $departureTime = (Get-Date 01.01.1970).AddSeconds($busStopSchedule.DepartureTime).ToLocalTime()
        $timeUntilDeparture = $departureTime - $localTime
        $OutputTime = ""
        if ($timeUntilDeparture.TotalMinutes -ge 1) {
            $roundedMinutes = [Math]::Ceiling($timeUntilDeparture.TotalMinutes)
            $OutputTime += ($roundedMinutes).ToString() + " minutes"
        }
        else {
            Write-Warning -Message ("Bus is DUE at route '{0}' for stop '{1}' in '{2}' direction in under a minute." `
                    -f $busRouteInfo.RouteLabel, $busStopInfo.Description, $directionInfo.DirectionName)
            return
        }
    
        $OutputTime
    }
    catch {
        Write-Error -Message $_.Exception.Message
    }
    finally {
        Write-Verbose -Message "Finished $($MyInvocation.MyCommand.Name)"
    }
}

Export-ModuleMember -Function Get-MetroBusNextTrip