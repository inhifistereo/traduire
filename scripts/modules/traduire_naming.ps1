Set-Variable -Name cwd                  -Value $PWD.Path
Set-Variable -Name root                 -Value (Get-Item $PWD.Path).Parent.FullName
Set-Variable -Name UriFriendlyAppName   -Value $AppName.Replace("-","")                 -Option Constant

Set-Variable -Name CORE_RG_NAME         -Value ("{0}_core_rg" -f $AppName)              -Option Constant
Set-Variable -Name APP_RG_NAME          -Value ("{0}_app_rg" -f $AppName)               -Option Constant
Set-Variable -Name APP_UI_RG            -Value ("{0}_ui_rg" -f $AppName)                -Option Constant

Set-Variable -Name APP_UI_NAME          -Value ("{0}-ui" -f $AppName)                   -Option Constant
Set-Variable -Name APP_PUBSUB_NAME      -Value ("{0}-pubsub" -f $AppName)               -Option Constant
Set-Variable -Name APP_K8S_NAME         -Value ("{0}-aks" -f $AppName)                  -Option Constant
Set-Variable -Name APP_ACR_NAME         -Value ("{0}acr" -f $UriFriendlyAppName)        -Option Constant
Set-Variable -Name APP_KV_NAME          -Value ("{0}-kv" -f $AppName)                   -Option Constant
Set-Variable -Name APP_SA_NAME          -Value ("{0}files" -f $UriFriendlyAppName)      -Option Constant
Set-Variable -Name APP_SERVICE_ACCT     -Value ("{0}-traduire-identity" -f $AppName)    -Option Constant
Set-Variable -Name APP_COGS_NAME        -Value ("{0}-cogs" -f $AppName)                 -Option Constant
Set-Variable -Name APP_AI_NAME          -Value ("{0}-appinsights" -f $AppName)          -Option Constant
Set-Variable -Name APP_SB_NAMESPACE     -Value ("{0}-sbns" -f $AppName)                 -Option Constant
Set-Variable -Name APP_NAMESPACE        -Value "traduire"                               -Option Constant

Set-Variable -Name UI_SOURCE_DIR        -Value (Join-Path -Path $root -ChildPath "src\ui")
Set-Variable -Name INFRA_DIR            -Value (Join-Path -Path $root -ChildPath "src\ui")
Set-Variable -Name APP_SOURCE_DIR       -Value (Join-Path -Path $root -ChildPath "src")