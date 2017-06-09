    function Import-NSRewriteActionTypes {
        #Count is 23 action types
        return @(
            'noop', 'delete',
            'insert_http_header','delete_http_header','corrupt_http_header',
            'insert_before','insert_after','replace','replace_http_res','delete_all',
            'insert_before_all','insert_after_all','clientless_vpn_encode','clientless_vpn_encode_all',
            'clientless_vpn_decode','clientless_vpn_decode_all',
            'insert_sip_header','delete_sip_header','corrupt_sip_header',
            'replace_res_res','replace_diameter_header_field','replace_dns_header_field','replace_dns_answer_section'
        )
    }
    Set-Variable -Name NSRewriteActionTypes -Value $(Import-NSRewriteActionTypes) -Option Constant
