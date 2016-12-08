param(
    [string]$domain,
	[string]$username,
	[string]$password
	)

$credential = New-Object System.Management.Automation.PSCredential($( $domain +"\" + $username),$($password | ConvertTo-SecureString -asPlainText -Force))
Add-Computer -DomainName $domain -Credential $credential -Restart:$false

# configure system here ...

# Install .NET 3.5
install-windowsfeature "net-framework-core"

# install applications here

# most applications need a restart
shutdown -r -f -t 0
