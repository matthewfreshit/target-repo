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
    Describe 'Get-MetroBusStopScheduleInfo' {
        Mock Invoke-MetroAPIRequest -MockWith { }
        Context 'Error' {
            It 'Should throw for null stop info' {
                { Get-MetroBusStopScheduleInfo -PlaceCode 'LIND' -BusRouteId '901' -DirectionId '1' } `
                    | Should Throw "Error getting bus stop info for place code 'LIND' -> No bus stop was found by given bus stop name."
            }
        }
        Context 'Success' {
            Mock Invoke-MetroAPIRequest -ParameterFilter {
                $IsNextTripV2 -eq $true -and $EndpointPath -eq '901/0/LIND'
            } -MockWith {
                return [PSCustomObject]@{
                    alerts = @(
                        [PSCustomObject]@{
                            alert_text = 'This is an alert'
                            stop_closed = $true
                        }
                    )
                    departures = @(
                        [PSCustomObject]@{
                            direction_id = '0'
                            departure_time = 1658179680
                            description = "departure to Mall of America"
                            route_id = "901"
                            schedule_relationship = "Skipped"
                        }
                    )
                    stops = @(
                        [PSCustomObject]@{
                            stop_id = 51420
                            description = "This is the stop for 51420"
                        }
                    )
                }
            }
            Mock Invoke-MetroAPIRequest -ParameterFilter {
                $IsNextTripV2 -eq $true -and $EndpointPath -eq '901/1/HHTE'
            } -MockWith {
                return [PSCustomObject]@{
                    alerts = @()
                    departures = @(
                        [PSCustomObject]@{
                            direction_id = '1'
                            departure_time = 1658179680
                            description = "departure to the best Mall of America"
                            route_id = "901"
                            schedule_relationship = "Scheduled"
                        }
                        [PSCustomObject]@{
                            direction_id = '1'
                            departure_time = 1658179681
                            description = "departure to the best Pizza Place"
                            route_id = "901"
                            schedule_relationship = "Scheduled"
                        }
                        [PSCustomObject]@{
                            direction_id = '1'
                            departure_time = 1658179682
                            description = "departure to the best Sushi Place"
                            route_id = "901"
                            schedule_relationship = "Scheduled"
                        }
                    )
                    stops = @(
                        [PSCustomObject]@{
                            stop_id = 51421
                            description = "This is the stop for 51421"
                        }
                    )
                }
            }
            
            It "Should return 0 alerts and 1658179680 for departure time" {
                $result = Get-MetroBusStopScheduleInfo -PlaceCode 'HHTE' -BusRouteId '901' -DirectionId '1' 
                $result.Alerts.Count | Should -Be 0 
                $result.DepartureTime | Should -Be 1658179680 

                Assert-MockCalled -CommandName Invoke-MetroAPIRequest -Times 1 -Exactly -Scope It
            }

            It "Should return 1 alert and null for departure time" {
                $result = Get-MetroBusStopScheduleInfo -PlaceCode 'LIND' -BusRouteId '901' -DirectionId '0' 
                $result.Alerts.Count | Should -Be 1 
                $result.DepartureTime | Should -Be $null 

                Assert-MockCalled -CommandName Invoke-MetroAPIRequest -Times 1 -Exactly -Scope It
            }
        }
    }
}