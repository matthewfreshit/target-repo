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

## Requirements
- [PowerShell 5.1](https://www.microsoft.com/en-us/download/details.aspx?id=54616) or [higher](https://github.com/PowerShell/PowerShell/releases/tag/v7.2.5)

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

