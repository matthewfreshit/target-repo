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
    Describe 'Get-MetroBusNextTrip' {
        Mock Write-Error { }
        Mock Write-Warning { }
        Mock Get-MetroBusRouteInfo { }
        Mock Get-MetroBusRouteDirectionInfo { }
        Mock Get-MetroBusStopInfo { }
        $date1 = Get-Date -Date 01.01.1970
        $date2 = Get-Date
        (New-TimeSpan -Start $date1 -End $date2).TotalSeconds
        Mock Get-MetroBusRouteInfo -ParameterFilter {
            $BusRouteName -eq 'Metro Blue'
        } -MockWith {
            return [PSCustomObject]@{
                RouteLabel       = 'Metro Blue Line'
                RouteDescription = 'Metro Blue Line - Description'
                RouteId          = '901'
            }
        }
        Mock Get-MetroBusRouteDirectionInfo -ParameterFilter {
            $BusRouteId -eq '901' -and $Direction -eq 'South'
        } -MockWith {
            return [PSCustomObject]@{
                DirectionId   = '0'
                DirectionName = 'Southbound'
            }
        }
        Mock Get-MetroBusStopInfo -ParameterFilter {
            $BusStopName -eq 'Metro Stop 1' -and $BusRouteId -eq '901' -and $DirectionId -eq '0'
        } -MockWith {
            [PSCustomObject]@{
                PlaceCode   = 'LIND'
                Description = 'MSP Airport Terminal 1 - Lindbergh Station'
            }
        }
        Mock Get-MetroBusStopScheduleInfo -ParameterFilter {
            $PlaceCode -eq 'LIND' -and $BusRouteId -eq '901' -and $DirectionId -eq '0'
        } -MockWith {
            [PSCustomObject]@{
                Alerts        = @(
                    [PSCustomObject]@{
                        alert_text  = 'This is an alert'
                        stop_closed = $true
                    }
                )
                DepartureTime = [DateTimeOffset]::Now.AddMinutes(10).ToUnixTimeSeconds()
            }
        }
        
        Context 'Error' {
            It 'Should throw from exception on Get-MetroBusRouteInfo' {
                Mock Get-MetroBusRouteInfo -ParameterFilter {
                    $BusRouteName -eq 'Metro bad route'
                } -MockWith {
                    Throw "Error getting bus route info for specified route 'Metro bad route' -> No bus route found for given bus route name."
                }
                Get-MetroBusNextTrip -BusRouteName 'Metro bad route' -BusStopName 'Metro Stop 1' -Direction 'North'
                Assert-MockCalled -CommandName 'Write-Error' -ParameterFilter {
                    $Message -eq "Error getting bus route info for specified route 'Metro bad route' -> No bus route found for given bus route name."
                } -Times 1 -Exactly -Scope It
            }
            It 'Should throw from exception on Get-MetroBusRouteDirectionInfo' {
                Mock Get-MetroBusRouteDirectionInfo -ParameterFilter {
                    $BusRouteId -eq '901' -and $Direction -eq 'North'
                } -MockWith {
                    Throw "Error getting bus route direction info for route id '901' -> No busses on this route are going in the specified direction 'north'"
                }
                Get-MetroBusNextTrip -BusRouteName 'Metro Blue' -BusStopName 'Metro Stop 1' -Direction 'North'
                Assert-MockCalled -CommandName 'Write-Error' -ParameterFilter {
                    $Message -eq "Error getting bus route direction info for route id '901' -> No busses on this route are going in the specified direction 'north'"
                } -Times 1 -Exactly -Scope It
            }
            It 'Should throw from exception on Get-MetroBusStopInfo' {
                Mock Get-MetroBusStopInfo -ParameterFilter {
                    $BusStopName -eq 'Metro Stop 2' -and $BusRouteId -eq '901' -and $DirectionId -eq '0'
                } -MockWith {
                    Throw "Error getting bus stop info for 'Metro Stop 2' -> No bus stop was found by given bus stop name."
                }
                Get-MetroBusNextTrip -BusRouteName 'Metro Blue' -BusStopName 'Metro Stop 2' -Direction 'South'
                Assert-MockCalled -CommandName 'Write-Error' -ParameterFilter {
                    $Message -eq "Error getting bus stop info for 'Metro Stop 2' -> No bus stop was found by given bus stop name."
                } -Times 1 -Exactly -Scope It
            }
            It 'Should throw from exception on Get-MetroBusStopScheduleInfo' {
                Mock Get-MetroBusStopScheduleInfo -ParameterFilter {
                    $PlaceCode -eq 'HHTE' -and $BusRouteId -eq '901' -and $DirectionId -eq '0'
                } -MockWith {
                    Throw "Error getting bus stop info for place code 'HHTE' -> No bus stop was found by given bus stop name."
                }
                Mock Get-MetroBusStopInfo -ParameterFilter {
                    $BusStopName -eq 'Metro Stop 3' -and $BusRouteId -eq '901' -and $DirectionId -eq '0'
                } -MockWith {
                    [PSCustomObject]@{
                        PlaceCode   = 'HHTE'
                        Description = 'MSP Airport Terminal 2 - HHTE Station'
                    }
                }        
                Get-MetroBusNextTrip -BusRouteName 'Metro Blue' -BusStopName 'Metro Stop 3' -Direction 'South'
                Assert-MockCalled -CommandName 'Write-Error' -ParameterFilter {
                    $Message -eq "Error getting bus stop info for place code 'HHTE' -> No bus stop was found by given bus stop name."
                } -Times 1 -Exactly -Scope It
            }
        }
        Context 'Success' {
            $WarningPreference = 'SilentlyContinue'
            It "Should return info with user prompts" {
                
                Mock Read-Host -ParameterFilter {
                    $Prompt -eq 'Enter bus route name'
                } { return 'Metro Blue' }
                Mock Read-Host -ParameterFilter {
                    $Prompt -eq 'Enter bus stop name'
                } { return 'Metro Stop 1' }
                Mock Read-Host -ParameterFilter {
                    $Prompt -eq 'Enter bus direction (north, east, west, south)'
                } { return 'South' }

                $result = Get-MetroBusNextTrip
                $result | Should -Be "10 minutes"
                Assert-MockCalled -CommandName Get-MetroBusRouteInfo -Times 1 -Exactly -Scope It
                Assert-MockCalled -CommandName Get-MetroBusRouteDirectionInfo -Times 1 -Exactly -Scope It
                Assert-MockCalled -CommandName Get-MetroBusStopInfo -Times 1 -Exactly -Scope It
                Assert-MockCalled -CommandName Get-MetroBusStopScheduleInfo -Times 1 -Exactly -Scope It
            }
            It "Should return route info for 'Metro Blue Line' - 'Metro Stop 1'" {
                $result = Get-MetroBusNextTrip -BusRouteName 'Metro Blue' -BusStopName 'Metro Stop 1' -Direction 'South'
                $result | Should -Be "10 minutes"
                Assert-MockCalled -CommandName Get-MetroBusRouteInfo -Times 1 -Exactly -Scope It
                Assert-MockCalled -CommandName Get-MetroBusRouteDirectionInfo -Times 1 -Exactly -Scope It
                Assert-MockCalled -CommandName Get-MetroBusStopInfo -Times 1 -Exactly -Scope It
                Assert-MockCalled -CommandName Get-MetroBusStopScheduleInfo -Times 1 -Exactly -Scope It
            }
            It "Should warn that bus is DUE any second 'Metro Blue Line' - 'Metro Stop 4'" {
                Mock Get-MetroBusStopInfo -ParameterFilter {
                    $BusStopName -eq 'Metro Stop 5' -and $BusRouteId -eq '901' -and $DirectionId -eq '0'
                } -MockWith {
                    [PSCustomObject]@{
                        PlaceCode   = 'MMT2'
                        Description = 'MSP Airport Terminal 4 - MMT2 Station'
                    }
                }
                Mock Get-MetroBusStopScheduleInfo -ParameterFilter {
                    $PlaceCode -eq 'MMT2' -and $BusRouteId -eq '901' -and $DirectionId -eq '0'
                } -MockWith {
                    [PSCustomObject]@{
                        Alerts        = @()
                        DepartureTime = [DateTimeOffset]::Now.AddSeconds(10).ToUnixTimeSeconds()
                    }
                }
                
                Get-MetroBusNextTrip -BusRouteName 'Metro Blue' -BusStopName 'Metro Stop 5' -Direction 'South'
                
                Assert-MockCalled -CommandName Get-MetroBusRouteInfo -Times 1 -Exactly -Scope It
                Assert-MockCalled -CommandName Get-MetroBusRouteDirectionInfo -Times 1 -Exactly -Scope It
                Assert-MockCalled -CommandName Get-MetroBusStopInfo -Times 1 -Exactly -Scope It
                Assert-MockCalled -CommandName Get-MetroBusStopScheduleInfo -Times 1 -Exactly -Scope It
                Assert-MockCalled -CommandName Write-Warning -ParameterFilter {
                    $Message -eq "Bus is DUE at route 'Metro Blue Line' for stop 'MSP Airport Terminal 4 - MMT2 Station' in 'Southbound' direction in under a minute."
                }
            }
            It "Should return no information for lack of departures 'Metro Blue Line' - 'Metro Stop 4'" {
                Mock Get-MetroBusStopInfo -ParameterFilter {
                    $BusStopName -eq 'Metro Stop 4' -and $BusRouteId -eq '901' -and $DirectionId -eq '0'
                } -MockWith {
                    [PSCustomObject]@{
                        PlaceCode   = 'MMT'
                        Description = 'MSP Airport Terminal 3 - MMT Station'
                    }
                }
                Mock Get-MetroBusStopScheduleInfo -ParameterFilter {
                    $PlaceCode -eq 'MMT' -and $BusRouteId -eq '901' -and $DirectionId -eq '0'
                } -MockWith {
                    [PSCustomObject]@{
                        Alerts        = @()
                        DepartureTime = $null
                    }
                }

                Get-MetroBusNextTrip -BusRouteName 'Metro Blue' -BusStopName 'Metro Stop 4' -Direction 'South'
                
                Assert-MockCalled -CommandName Get-MetroBusRouteInfo -Times 1 -Exactly -Scope It
                Assert-MockCalled -CommandName Get-MetroBusRouteDirectionInfo -Times 1 -Exactly -Scope It
                Assert-MockCalled -CommandName Get-MetroBusStopInfo -Times 1 -Exactly -Scope It
                Assert-MockCalled -CommandName Get-MetroBusStopScheduleInfo -Times 1 -Exactly -Scope It
                Assert-MockCalled -CommandName Write-Warning -ParameterFilter {
                    $Message -eq "Bus route 'Metro Blue Line' has no more departures for stop 'MSP Airport Terminal 3 - MMT Station' in 'Southbound' direction."
                }
            }
        }
    }
}