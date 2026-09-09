[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$Username,

    [Parameter(Mandatory=$true)]
    [string]$Domain,

    [Parameter(Mandatory=$true)]
    [string]$OldPassword,

    [Parameter(Mandatory=$true)]
    [string]$NewPassword
)

$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.DirectoryServices.AccountManagement

$context = New-Object System.DirectoryServices.AccountManagement.PrincipalContext(
    [System.DirectoryServices.AccountManagement.ContextType]::Domain,
    $Domain
)

try {
    if (-not $context.ValidateCredentials($Username, $OldPassword, [System.DirectoryServices.AccountManagement.ContextOptions]::Negotiate)) {
        throw "Senha atual invalida para '$Username'."
    }

    $principal = [System.DirectoryServices.AccountManagement.UserPrincipal]::FindByIdentity(
        $context,
        [System.DirectoryServices.AccountManagement.IdentityType]::SamAccountName,
        $Username
    )

    if ($null -eq $principal) {
        throw "Usuario '$Username' nao encontrado no dominio '$Domain'."
    }

    $principal.ChangePassword($OldPassword, $NewPassword)
    $principal.Save()

    $Ansible.Result = @{ changed = $true }
    $Ansible.Changed = $true
}
finally {
    if ($null -ne $principal) {
        $principal.Dispose()
    }
    $context.Dispose()
}
