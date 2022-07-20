Set-StrictMode -Version 'Latest';

try{
    Import-Module -Name Pester -MaximumVersion '4.10.1'
} catch {
    Write-Host 'Pester module not found. Please install Pester module.'
    Install-Module Pester -MaximumVersion 4.10.1 -Repository PSGallery -Scope CurrentUser -Force
    Import-Module -Name Pester -MaximumVersion '4.10.1'
}

$rootRepoPath = Split-Path -Path $PSScriptRoot -Parent

Get-Module -Name 'Target.API.Consumption' | Remove-Module -Force -Verbose:$false
Import-Module -Force "$rootRepoPath\src\Target.API.Consumption.psm1" -DisableNameChecking -Global -Verbose:$false

InModuleScope 'Target.API.Consumption' {
    Describe 'Get-MetroBusRouteDirectionInfo' {
        Mock Invoke-MetroAPIRequest -MockWith { }
        Context 'Error'{
            It 'Should throw for null direction info' {
                { Get-MetroBusRouteDirectionInfo -BusRouteId '901' -Direction 'north' } `
                    | Should Throw "Error getting bus route direction info for route id '901' -> No busses on this route are going in the specified direction 'north'"
            }

            It 'Should fail from web request error' {
                Mock Invoke-MetroAPIRequest -MockWith {
                    throw "Web request error"
                }
                { Get-MetroBusRouteDirectionInfo -BusRouteId '901' -Direction 'north' } | Should Throw "Web request error"
            }

            It 'Should only take in valid "Direction" (north, south, east, west)' {
                { Get-MetroBusRouteDirectionInfo -BusRouteId '901' -Direction 'test' } | Should Throw
            }
        }
        Context 'Success'{
            Mock Invoke-MetroAPIRequest -ParameterFilter {
                $IsNextTripV2 -eq $true -and $EndpointPath -eq 'directions/901'
            } -MockWith {
                return @(
                    [PSCustomObject]@{
                        direction_id = '0'
                        direction_name = 'Northbound'
                    }
                    [PSCustomObject]@{
                        direction_id = '1'
                        direction_name = 'Southbound'
                    }
                )
            }
            It 'Should return southbound direction info' {
                $result = Get-MetroBusRouteDirectionInfo -BusRouteId '901' -Direction 'north'
                $result.DirectionId | Should -Be '0'
                $result.DirectionName | Should -Be 'Northbound'

                Assert-MockCalled -CommandName Invoke-MetroAPIRequest -Times 1 -Exactly
            }
        }
    }
}