        function Enable-NSServiceGroup {
            [CmdletBinding()]
            param (
                [Parameter(Mandatory=$true)] [PSObject]$NSSession,
                [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] [string]$Name
            )
            Begin {
                Write-Verbose "$($MyInvocation.MyCommand): Enter"
                $payload = @{servicegroupname=$Name}
            }
            Process {
                $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType servicegroup -Payload $payload -Verbose:$VerbosePreference -Action enable
            }
            End {
                Write-Verbose "$($MyInvocation.MyCommand): Exit"
            }
        }
