

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
    Describe 'Invoke-MetroAPIRequest' {
        Function New-MockObject {
            <# Function that will be used to mock .Net class objects #>
            param (
                [Parameter(Mandatory = $true)]
                [ValidateNotNullOrEmpty()]
                [type]$Type,
                [ValidateNotNullOrEmpty()]
                [hashtable]$Properties
            )
            $mock = [System.Runtime.Serialization.Formatterservices]::GetUninitializedObject($Type)
            if ($null -ne $Properties) {
                foreach ($property in $Properties.GetEnumerator()) {
                    $addMemberSplat = @{
                        MemberType = [System.Management.Automation.PSMemberTypes]::NoteProperty
                        Name       = "$($property.Key)"
                        Value      = $property.Value
                        Force      = $true
                    }
                    $mock | Add-Member @addMemberSplat
                }
            }
            $mock
        }
        Mock Invoke-WebRequest -MockWith { }
        Context 'Error'{
            It 'Should fail from 404 web request error' {
                Mock Invoke-WebRequest -MockWith {
                    $errorDetails = '{"detail": "Web request error", "title": "Bad Request"}'
                    $statusCode = 404
                    $response = New-MockObject System.Net.Http.HttpResponseMessage -Properties @{
                        StatusCode = $statusCode
                    } 
                    $exception = New-MockObject System.Net.WebException -Properties @{
                        Message  = "The remote server returned an error: (404)"
                        Status   = $statusCode
                        Response = $response
                    }
                    $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidOperation
                    $errorID = 'WebCmdletWebResponseException,Microsoft.PowerShell.Commands.InvokeWebRequestCommand'
                    $targetObject = $null
                    $errorRecord = New-Object Management.Automation.ErrorRecord $exception, $errorID, $errorCategory, $targetObject
                    $errorRecord.ErrorDetails = $errorDetails
                    Throw $errorRecord
                }
                { Invoke-MetroAPIRequest -EndpointPath '99999' -IsNextTripV2 } | Should Throw "Web request error"
            }

            It 'Should fail from 404 web request error' {
                Mock Invoke-WebRequest -MockWith {
                    Throw "Random web request error"
                }
                { Invoke-MetroAPIRequest -EndpointPath '99999' -IsNextTripV2 } | Should Throw "Random web request error"
            }
        }
        Context 'Success'{
            It 'Should return all bus routes' {
                Mock Invoke-WebRequest -ParameterFilter {
                    $Uri -eq 'https://svc.metrotransit.org/schedule/routes'
                } -MockWith {
                    return @{
                        Content = @"
[{"route_label": "Metro Blue Line", "description": "Metro Blue Line - Description", "route_id": "901" },
{"route_label": "Blue Line Bus", "description": "Blue Line Bus - Description", "route_id": "991" },
{"route_label": "Metro Green Line", "description": "Metro Green Line - Description", "route_id": "902" },
{"route_label": "Metro Red Line", "description": "Metro Red Line - Description", "route_id": "903" }]
"@ 
                    }
                }
                $result = Invoke-MetroAPIRequest -EndpointPath 'routes' -IsSchedule
                ($result | Measure-Object).Count | Should -Be 4

                Assert-MockCalled -CommandName Invoke-WebRequest -Times 1 -Exactly -Scope It
            }
            It 'Should return all directions for bus route' {
                Mock Invoke-WebRequest -ParameterFilter {
                    $Uri -eq 'https://svc.metrotransit.org/nextripv2/directions/901'
                } -MockWith {
                    return @{
                        Content = @"
[{"direction_id": "0", "direction_name": "Northbound"},
{"direction_id": "1", "direction_name": "Southbound"}]
"@ 
                    }
                }
                $result = Invoke-MetroAPIRequest -EndpointPath 'directions/901' -IsNextTripV2
                ($result | Measure-Object).Count | Should -Be 2

                Assert-MockCalled -CommandName Invoke-WebRequest -Times 1 -Exactly -Scope It
            }
            It 'Should return all alerts' {
                Mock Invoke-WebRequest -ParameterFilter {
                    $Uri -eq 'https://svc.metrotransit.org/alerts/all'
                } -MockWith {
                    return @{
                        Content = @"
[{"id": "0", "cause": "Contruction"},
{"id": "1", "cause": "Wreck"}]
"@ 
                    }
                }
                $result = Invoke-MetroAPIRequest -EndpointPath 'all' -IsAlerts
                ($result | Measure-Object).Count | Should -Be 2

                Assert-MockCalled -CommandName Invoke-WebRequest -Times 1 -Exactly -Scope It
            }

            It 'Should return address from tripfinder' {
                Mock Invoke-WebRequest -ParameterFilter {
                    $Uri -eq 'https://svc.metrotransit.org/tripplanner/findaddress/magickey'
                } -MockWith {
                    return @{
                        Content = @"
[{"address": "1234 Quiet St.", "x": "10", "y": "20"},
{"address": "1235 Quiet St.", "x": "20", "y": "30"}]
"@ 
                    }
                }
                $result = Invoke-MetroAPIRequest -EndpointPath 'findaddress/magickey' -IsTripPlanner
                ($result | Measure-Object).Count | Should -Be 2

                Assert-MockCalled -CommandName Invoke-WebRequest -Times 1 -Exactly -Scope It
            }
        }
    }
}