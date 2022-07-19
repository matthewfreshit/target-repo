# API Consumption

*Target Case Study Project - API Consumption*
<br>

## Case Study Overview

```
In a language of your choice, write a program which will tell you how long it is until the next bus on "BUS ROUTE" leaving from "BUS STOP NAME" going "DIRECTION" using the api defined at http://svc.metrotransit.org/ 

"BUS ROUTE" will be a substring of the bus route name which is only in one bus route 

"BUS STOP NAME" will be a substring of the bus stop name which is only in one bus stop on that route

"DIRECTION" will be "north" "east" "west" or "south"

Eg, if you wanted to know the next bus leaving from our Brooklyn Park campus to our downtown campus:

$ go run nextbus.go "Express - Target - Hwy 252 and 73rd Av P&R - Mpls" "Target North Campus Building F" "south"
2 Minutes

(note that that won't return anything if the last bus for the day has already left)

Or if you wanted to take the light rail from downtown to the Mall of America or the Airport:

$ nextbus.py "METRO Blue Line" "Target Field Station Platform 1" "south"
8 Minutes
```

## Documentation
- [Metro Transit API](http://svc.metrotransit.org/)
- [Swagger Documentation](https://svc.metrotransit.org/swagger/index.html)
- [Metro Transit Website - NexTrip](https://www.metrotransit.org/nextrip)

## Requirements
- [PowerShell 5.1](https://www.microsoft.com/en-us/download/details.aspx?id=54616) or [higher (Preferred)](https://github.com/PowerShell/PowerShell/releases/tag/v7.2.5)

## Installation
1. Clone the repository into an accessible directory on your local machine.
```
git clone https://github.com/matthewfreshit/target-repo.git
```
2. If Powershell is not installed on the machine, install it using the reference links in the `Requirements` section.

3. Create a new **Admin** PowerShell session either in VS Code or in standard Powershell terminal and import the `Target.API.Consumption` module.
```powershell
# Execution policy has to be set due to this not being a digitally signed module.
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Confirm:$false -Force

Import-Module "G:\FreshIT\GitRepos\Target\target-repo\api-consumption\src\Target.API.Consumption.psm1" #Replace with your local relative path to the Target.API.Consumption.psm1 file
```

## Usage
- After importing the module into your Powershell session you will now be able to use the member functions individually, or you can use the `Get-MetroBusNextTrip` function to get the next bus for a given bus route, bus stop, and direction.

<br>

*Invidual Member Function Usage*

```powershell
Get-MetroAllBusRoutes # Returns all Bus Routes

Get-MetroBusRouteInfo -BusRouteName "Metro Blue" # Or we can use 'Blue Line - Mpls - Airport - ' to get the same result. This will return info about the Metro Blue Line route.

Get-MetroBusRouteDirectionInfo -BusRouteId '901' -Direction 'south' # Returns bus route direction info

Get-MetroBusStopInfo -BusStopName 'MSP Airport Terminal 1' -BusRouteId '901' -DirectionId '0' # Returns bus stop info

$schedulInfo = Get-MetroBusStopScheduleInfo -PlaceCode 'LIND' -BusRouteId '901' -DirectionId '0' # Returns bus stop schedule info

$schedulInfo | Format-Custom -Depth 3 # Returns the schedule info in a more readable format
```
<br>

*`Get-MetroBusNextTrip` Function Usage*

```powershell
Get-MetroBusNextTrip #This option will prompt the user to enter the bus route, bus stop, and direction.

Get-MetroBusNextTrip -BusRouteName 'Metro Blue' -BusStopName 'MSP Airport Terminal 1' -Direction 'South' # Should return the next bus for the given bus route, bus stop, and direction if it is available. It will also show any alerts for the bus route and bus stop if they exist.

Get-MetroBusNextTrip -BusRouteName 'Metro Blue' -BusStopName 'MSP Airport Terminal 1' -Direction 'South' -Verbose #Add verbose switch to view logs
```

## Testing
- Unit (Pester) tests have been written for each member function and have 100% code coverage.
- Powershell's Pester Module will need to be installed to run the unit tests. The pester scripts have a `try/catch` built in to install this package if it doesn't exist, but the commands below can be used to install it manually.
```powershell
Install-Module Pester -MaximumVersion 4.99.99 -Repository PSGallery -Scope CurrentUser -Force
Import-Module -Name Pester -MaximumVersion '4.99.99'
```
- To invoke the pester tests, run `Invoke-Pester` from a Powershell session with the `api-consumption` folder set as the current directory.

## Notes
- Extra error handling has been added into this module to create a more seamless user experience. The current structure will prevent full exceptions from displaying and instead return a friendly error message.

## Assumptions
- The API endpoint is accessible.
- The input parameters are valid.
    - **BUS ROUTE** is not null and is a substring of a valid bus route name.
    - **BUS STOP NAME** is not null and is a substring of a valid bus stop name.
    - **DIRECTION** is not null and is one of "*north*", "*east*", "*west*", or "*south*".

## Exceptions
 - The API endpoint is not accessible.
     - Error will be thrown with a message indicating the API endpoint is not accessible.
- The input parameters are invalid.
    - Error message from the API will be returned.

