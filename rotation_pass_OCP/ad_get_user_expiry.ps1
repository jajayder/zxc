[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$Username,

    [Parameter(Mandatory=$true)]
    [string]$Domain
)

$ErrorActionPreference = 'Stop'

Import-Module ActiveDirectory

$user = Get-ADUser -Identity $Username -Server $Domain -Properties PasswordNeverExpires,PasswordExpired,Enabled,'msDS-UserPasswordExpiryTimeComputed'

if ($null -eq $user) {
    throw "Usuario '$Username' nao encontrado no AD."
}

if (-not $user.Enabled) {
    $Ansible.Result = @{
        status = 'AD_ACCOUNT_DISABLED'
        days_remaining = 'N/A'
        expiration_date = $null
    }
    $Ansible.Changed = $false
    return
}

if ($user.PasswordNeverExpires) {
    $Ansible.Result = @{
        status = 'PASSWORD_NEVER_EXPIRES'
        days_remaining = 'N/A'
        expiration_date = $null
    }
    $Ansible.Changed = $false
    return
}

$rawExpiry = [Int64]$user.'msDS-UserPasswordExpiryTimeComputed'

# Valores especiais documentados pelo AD para ausencia/nao expiracao.
if ($rawExpiry -eq 0) {
    $Ansible.Result = @{
        status = 'PASSWORD_EXPIRED'
        days_remaining = -1
        expiration_date = $null
    }
    $Ansible.Changed = $false
    return
}

if ($rawExpiry -eq [Int64]::MaxValue) {
    $Ansible.Result = @{
        status = 'PASSWORD_NEVER_EXPIRES'
        days_remaining = 'N/A'
        expiration_date = $null
    }
    $Ansible.Changed = $false
    return
}

$expiry = [DateTime]::FromFileTime($rawExpiry)
$now = Get-Date
$secondsRemaining = ($expiry - $now).TotalSeconds
$daysRemaining = [Math]::Floor($secondsRemaining / 86400)

if ($secondsRemaining -lt 0) {
    $status = 'PASSWORD_EXPIRED'
} elseif ($daysRemaining -le 10) {
    $status = 'ROTATE'
} else {
    $status = 'NOT_DUE'
}

$Ansible.Result = @{
    status = $status
    days_remaining = [int]$daysRemaining
    expiration_date = $expiry.ToString('yyyy-MM-dd HH:mm:ss')
}
$Ansible.Changed = $false
