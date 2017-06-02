    function Disable-NSMode {
        <#
        .SYNOPSIS
            Disable NetScaler appliance mode(s)
        .DESCRIPTION
            Disable one or more NetScaler appliance mode(s)
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER Mode
            Mode(s) to be disabled. This can be passed as multiple modes (comma or space separated).
        .EXAMPLE
            Disable-NSMode -NSSession $Session -Mode "usnip"
        .EXAMPLE
            Disable-NSMode -NSSession $Session -Mode "usnip","mbf"
        .EXAMPLE
            Disable-NSMode -NSSession $Session -Mode "usnip mbf"
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)] [string[]]$Mode
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter"

        $modeParsed = $Mode.Trim().ToUpper() -join ' '

        $payload = @{mode=$modeParsed}
        $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType nsmode -Payload $payload -Action disable -Verbose:$VerbosePreference

        Write-Verbose "$($MyInvocation.MyCommand): Exit"
    }
