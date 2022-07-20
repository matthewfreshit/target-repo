Set-StrictMode -Version 'Latest';

try {
    Import-Module -Name Pester -MaximumVersion '4.10.1'
}
catch {
    Write-Host 'Pester module not found. Please install Pester module.'
    Install-Module Pester -MaximumVersion 4.10.1 -Repository PSGallery -Scope CurrentUser -Force
    Import-Module -Name Pester -MaximumVersion '4.10.1'
}

$rootRepoPath = Split-Path -Path $PSScriptRoot -Parent

Get-Module -Name 'Target.API.Consumption' | Remove-Module -Force -Verbose:$false
Import-Module -Force "$rootRepoPath\src\Target.API.Consumption.psm1" -DisableNameChecking -Global -Verbose:$false

InModuleScope 'Target.API.Consumption' {
    Describe 'Get-MetroBusStopInfo' {
        Mock Invoke-MetroAPIRequest -MockWith { }
        Context 'Error' {
            It 'Should throw for null stop info' {
                { Get-MetroBusStopInfo -BusStopName 'MSP Airport Terminal 10' -BusRouteId '901' -DirectionId '1' } `
                    | Should Throw "Error getting bus stop info for 'MSP Airport Terminal 10' -> No bus stop was found by given bus stop name."
            }

            It 'Should throw for more than one bus route found' {
                Mock Invoke-MetroAPIRequest -ParameterFilter {
                    $IsNextTripV2 -eq $true -and $EndpointPath -eq 'stops/901/0'
                } -MockWith {
                    return @(
                        [PSCustomObject]@{
                            place_code = 'LIND'
                            description = 'MSP Airport Terminal 1 - Lindbergh Station'
                        }
                        [PSCustomObject]@{
                            place_code = 'HHTE'
                            description = 'MSP Airport Terminal 2 - Humphrey Station'
                        }
                    )
                }
                { Get-MetroBusStopInfo -BusStopName 'MSP Airport Terminal' -BusRouteId '901' -DirectionId '0' } `
                    | Should Throw "Error getting bus stop info for 'MSP Airport Terminal' -> More than one bus stop was found by given bus stop name. Please refine your search criteria."
            }
        }
        Context 'Success' {
            Mock Invoke-MetroAPIRequest -ParameterFilter {
                $IsNextTripV2 -eq $true -and $EndpointPath -eq 'stops/901/1'
            } -MockWith {
                return @(
                    [PSCustomObject]@{
                        place_code = 'TF1'
                        description = 'Target Field Station Platform 1'
                    }
                    [PSCustomObject]@{
                        place_code = 'TF2'
                        description = 'Target Field Station Platform 2'
                    }
                    [PSCustomObject]@{
                        place_code = 'LIND'
                        description = 'MSP Airport Terminal 1 - Lindbergh Station'
                    }
                    [PSCustomObject]@{
                        place_code = 'HHTE'
                        description = 'MSP Airport Terminal 2 - Humphrey Station'
                    }
                )
            }
            It "Should return stop info for 'MSP Airport Terminal 1 - Lindbergh Station'" {
                $result = Get-MetroBusStopInfo -BusStopName 'MSP Airport Terminal 1' -BusRouteId '901' -DirectionId '1' #using substring of stop name to match route label
                $result.PlaceCode | Should -Be 'LIND'
                $result.Description | Should -Be 'MSP Airport Terminal 1 - Lindbergh Station'

                Assert-MockCalled -CommandName Invoke-MetroAPIRequest -Times 1 -Exactly
            }
        }
    }
}