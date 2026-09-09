[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$Username,

    [Parameter(Mandatory=$true)]
    [string]$Domain,

    [Parameter(Mandatory=$true)]
    [string]$Password
)

$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.DirectoryServices.AccountManagement

$context = New-Object System.DirectoryServices.AccountManagement.PrincipalContext(
    [System.DirectoryServices.AccountManagement.ContextType]::Domain,
    $Domain
)

try {
    $valid = $context.ValidateCredentials(
        $Username,
        $Password,
        [System.DirectoryServices.AccountManagement.ContextOptions]::Negotiate
    )

    $Ansible.Result = @{ valid = [bool]$valid }
    $Ansible.Changed = $false
}
finally {
    $context.Dispose()
}
