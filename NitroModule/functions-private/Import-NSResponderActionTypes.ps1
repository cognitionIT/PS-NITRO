    function Import-NSResponderActionTypes {
        #Count is 6 action types
        return @('noob', 'respondwith', 'redirect', 'respondwithhtmlpage', 'sqlresponse_ok','sqlresponse_error')
    }
    Set-Variable -Name NSResponderActionTypes -Value $(Import-NSResponderActionTypes) -Option Constant
