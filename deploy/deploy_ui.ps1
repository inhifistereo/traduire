[CmdletBinding(DefaultParameterSetName = 'Default')]
param(
    [Parameter(ParameterSetName = 'Default', Mandatory=$true)]
    [string] $AppName,

    [Parameter(ParameterSetName = 'Default', Mandatory=$false)]
    [string] $Uri,

    [Parameter(ParameterSetName = 'Default', Mandatory=$false)]
    [switch] $Upgrade
)

Write-Error -Message "To be written...."
