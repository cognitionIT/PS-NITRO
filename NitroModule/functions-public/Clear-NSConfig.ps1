    function Clear-NSConfig {
        <#
        .SYNOPSIS
            Clear the NetScaler Config File 
        .DESCRIPTION
            Clear the NetScaler Config File 
        .PARAMETER NSSession
            An existing custom NetScaler Web Request Session object returned by Connect-NSAppliance
        .PARAMETER Level
            Types of configurations to be cleared. Possible values = basic, extended, full
        .PARAMETER Enforced
            Configurations will be cleared without prompting for confirmation.
        .EXAMPLE
            Clear-NSConfig -NSSession $Session
        .NOTES
            Copyright (c) cognition IT. All rights reserved.
        #>
        <# Reset NS configuration
        CLI: clear ns config [-force] <level>
        <level> = basic, extended or full

        NITRO:
        clear

        URL:http://<NSIP>/nitro/v1/config/

        HTTP Method:POST

        Request Payload:JSON

        object={
        "params":{
              "warning":<String_value>,
              "onerror":<String_value>,
              "action":"clear"
        },
        "sessionid":"##sessionid",
        "nsconfig":{
              "force":<Boolean_value>,
              "level":<String_value>,
        }}

        Response Payload:JSON

        { "errorcode": 0, "message": "Done", "severity": <String_value> }
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)] [PSObject]$NSSession,
            [Parameter(Mandatory=$true)] [ValidateSet("basic", "extended", "full")] [string]$Level="basic",
            [Parameter(Mandatory=$false)] [switch]$Enforced
        )

        Write-Verbose "$($MyInvocation.MyCommand): Enter" 

        $payload = @{}
        If ($Enforced) {
            $payload.Add("force",$true)
        }
        $payload.Add("level",$Level)

        $response = Invoke-NSNitroRestApi -NSSession $NSSession -OperationMethod POST -ResourceType nsconfig -Payload $payload -Action "clear" -Verbose:$VerbosePreference

        Write-Verbose "$($MyInvocation.MyCommand): Exit"
    }
