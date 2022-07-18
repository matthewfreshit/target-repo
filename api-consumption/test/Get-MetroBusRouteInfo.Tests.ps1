Set-StrictMode -Version 'Latest';

try {
    Import-Module -Name Pester -MaximumVersion '4.99.99'
}
catch {
    Write-Host 'Pester module not found. Please install Pester module.'
    Install-Module Pester -MaximumVersion 4.99.99 -Repository PSGallery -Scope CurrentUser -Force
    Import-Module -Name Pester -MaximumVersion '4.99.99'
}


$rootRepoPath = Split-Path -Path $PSScriptRoot -Parent

Get-Module -Name 'Target.API.Consumption' | Remove-Module -Force -Verbose:$false
Import-Module -Force "$rootRepoPath\src\Target.API.Consumption.psm1" -DisableNameChecking -Global -Verbose:$false


InModuleScope 'Target.API.Consumption' {
    Describe 'Get-MetroBusRouteInfo' {
        Mock Get-MetroAllBusRoutes -MockWith {
            return @(
                [PSCustomObject]@{
                    RouteLabel = 'Metro Blue Line'
                    RouteId    = '901'
                }
                [PSCustomObject]@{
                    RouteLabel = 'Blue Line Bus'
                    RouteId    = '991'
                }
                [PSCustomObject]@{
                    RouteLabel = 'Metro Green Line'
                    RouteId    = '902'
                }
                [PSCustomObject]@{
                    RouteLabel = 'Metro Red Line'
                    RouteId    = '903'
                }
            )
        }
        Context 'Error' {
            It 'Should throw for null route info' {
                { Get-MetroBusRouteInfo -BusRouteName 'Metro bad route' } `
                    | Should Throw "Error getting bus route info for specified route 'Metro bad route' -> No bus route found for given bus route name."
            }

            It 'Should throw for more than one bus route found' {
                { Get-MetroBusRouteInfo -BusRouteName 'Metro' } `
                    | Should Throw "Error getting bus route info for specified route 'Metro' -> More than one bus route was found by given bus route name. Please refine your search criteria."
            }
        }
        Context 'Success' {
            It "Should return route info for 'Metro Blue Line'" {
                $result = Get-MetroBusRouteInfo -BusRouteName 'Metro Blue' #using substring of route name to match route label
                $result.RouteId | Should -Be '901'
                $result.RouteLabel | Should -Be 'Metro Blue Line'

                Assert-MockCalled -CommandName Get-MetroAllBusRoutes -Times 1 -Exactly
            }
        }
    }
}