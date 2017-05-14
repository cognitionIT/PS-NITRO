Measure-Command {

#NetScaler IP Address
$NSIP = "192.168.0.201"

#Parameters: NetScaler IP, Username, Password
login-netscaler $NSIP nsroot nsroot

#Parameters: NTP IP Address, NetScaler IP
Add-NetScalerNTP 129.6.15.28 $NSIP
Add-NetScalerNTP 129.6.15.29 $NSIP
Add-NetScalerNTP 129.6.15.30 $NSIP

#Parameters: , NetScaler IP, Ldap Profile Name, DC IP Address, Security, Port, Type, Timeout, Base DN, Bind Account, Password, Login Name, Group Attribute, Sub Attribute, SSO Attribute
Add-NetScalerLdapServer $NSIP XenAppBlog-LDAP 192.168.0.200 PLAINTEXT 389 AD 600 "dc=bretty,dc=me,dc=uk" david.brett@bretty.me.uk password userprincipalname memberof cn userprincipalname

#Parameters: NetScaler IP, LDAP Policy Name, Expression, LDAP Profile Name
Add-NetScalerLdapPolicy $NSIP XenAppBlog-LDAP-Policy ns_true XenAppBlog-LDAP

#Parameters: NetScaler IP, Session Action Name, Default Auth, ICA Proxy, StoreFront Address, SSO Domain
Add-NetScalerSessionAction $NSIP XenAppBlog-Web ALLOW ON https://storefront.bretty.me.uk/citrix/brettyweb bretty.me.uk

#Parameters: NetScaler IP, Session Policy Name, Expression, Session Profile Name
Add-NetScalerSessionPolicy $NSIP XenAppBlog-Web-Policy "REQ.HTTP.HEADER User-Agent NOTCONTAINS CitrixReceiver && REQ.HTTP.HEADER Referer EXISTS" XenAppBlog-Web

#Parameters: NetScaler IP, NetScaler Gateway Name, Type
Add-NetScalerGateway $NSIP XenAppBlogGateway SSL

#Parameters: NetScaler IP, Content Switch Name, Type, IP Address, Port
Add-ContentSwitch $NSIP XenAppBlog-CS SSL 192.168.0.242 443

#Parameters: NetScaler IP, Content Switch Name, NetScaler Gateway Name
Bind-ContentSwitchDefaultvServer $NSIP XenAppBlog-CS XenAppBlogGateway

#Parameters: NetScaler IP, Content Switch Name, Certificate Name
Bind-CertificateCS $NSIP XenAppBlog-CS wildcard.bretty.me.uk_external

#Parameters: NetScaler IP, NetScaler Gateway Name, Certificate Name
Bind-CertificateGW $NSIP XenAppBlogGateway wildcard.bretty.me.uk_external

#Parameters: NetScaler IP, NetScaler Gateway Name, LDAP Policy Name
Bind-GatewayLDAP $NSIP XenAppBlogGateway XenAppBlog-LDAP-Policy

#Parameters: NetScaler IP, NetScaler Gateway Name, Session Policy Name
Bind-GatewaySession $NSIP XenAppBlogGateway XenAppBlog-Web-Policy

#Parameters: NetScaler IP, NetScaler Gateway Name, STA Address
Bind-GatewaySTA $NSIP XenAppBlogGateway http://xd.bretty.me.uk

logout-netscaler $NSIP

}