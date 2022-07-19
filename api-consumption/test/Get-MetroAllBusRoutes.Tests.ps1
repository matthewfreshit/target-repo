Set-StrictMode -Version 'Latest';

try{
    Import-Module -Name Pester -MaximumVersion '4.99.99'
} catch {
    Write-Host 'Pester module not found. Please install Pester module.'
    Install-Module Pester -MaximumVersion 4.99.99 -Repository PSGallery -Scope CurrentUser -Force
    Import-Module -Name Pester -MaximumVersion '4.99.99'
}


$rootRepoPath = Split-Path -Path $PSScriptRoot -Parent

Get-Module -Name 'Target.API.Consumption' | Remove-Module -Force -Verbose:$false
Import-Module -Force "$rootRepoPath\src\Target.API.Consumption.psm1" -DisableNameChecking -Global -Verbose:$false

InModuleScope 'Target.API.Consumption' {
    Describe 'Get-MetroAllBusRoutes' {
        Mock Invoke-MetroAPIRequest -MockWith { }
        Context 'Error'{
            It 'Should fail from web request error' {
                Mock Invoke-MetroAPIRequest -MockWith {
                    throw "Web request error"
                }
                { Get-MetroAllBusRoutes } | Should Throw "Web request error"
            }
        }
        Context 'Success'{
            Mock Invoke-MetroAPIRequest -ParameterFilter {
                $IsSchedule -eq $true -and $EndpointPath -eq 'routes'
            } -MockWith {
                return @(
                    [PSCustomObject]@{
                        route_label = 'Metro Blue Line'
                        description = 'Metro Blue Line - Description'
                        route_id = '901'
                    }
                    [PSCustomObject]@{
                        route_label = 'Blue Line Bus'
                        description = 'Blue Line Bus - Description'
                        route_id = '991'
                    }
                    [PSCustomObject]@{
                        route_label = 'Metro Green Line'
                        description = 'Metro Green Line - Description'
                        route_id = '902'
                    }
                    [PSCustomObject]@{
                        route_label = 'Metro Red Line'
                        description = 'Metro Red Line - Description'
                        route_id = '903'
                    }
                )
            }
            It 'Should return all bus routes' {
                $result = Get-MetroAllBusRoutes
                ($result | Measure-Object).Count | Should -Be 4

                Assert-MockCalled -CommandName Invoke-MetroAPIRequest -Times 1 -Exactly
            }
        }
    }
}