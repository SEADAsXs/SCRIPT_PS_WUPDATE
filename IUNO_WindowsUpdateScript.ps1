# LOG PATH
$LogDirectory = "C:\temp"
$LogFile = "$LogDirectory\windowsupdate.log"

# VERIFY LOG PATH
if (!(Test-Path -Path $LogDirectory)) {
    New-Item -ItemType Directory -Force -Path $LogDirectory | Out-Null
}

# START LOG
Start-Transcript -Path $LogFile -Append -ErrorAction SilentlyContinue

# CHECK AND INSTALL MODULES TO UPDATE
function Ensure-Module {
    param (
        [string]$ModuleName,
        [string]$ProviderName = $null
    )
    try {
        if (!(Get-Module -Name $ModuleName -ListAvailable)) {
            Write-Output "[INFO] Instalando Modulo: $ModuleName"
            if ($ProviderName -and !(Get-PackageProvider -Name $ProviderName -ListAvailable)) {
                Install-PackageProvider -Name $ProviderName -Force -SkipPublisherCheck -ErrorAction Stop
            }
            Install-Module -Name $ModuleName -Force -SkipPublisherCheck -ErrorAction Stop
        } else {
            Write-Output "[INFO] Modulo ya instalado: $ModuleName"
        }
    } catch {
        Write-Output "[ERROR] Falló la instalación del Modulo: $ModuleName $_"
        Exit 1
    }
}

# VERIFICO MODULOS INSTALADOS
Ensure-Module -ModuleName "PSWindowsUpdate" -ProviderName "NuGet"

# IMPORTO EL MODULO PSWINDOWSUPDATE
try {
    Import-Module PSWindowsUpdate -Force -ErrorAction Stop
    Write-Output "[SUCCESS] PSWindowsUpdate Modulo importado."
} catch {
    Write-Output "[ERROR] No se puede importar el Modulo: PSWindowsUpdate $_"
    Exit 1
}

# FUNCION PARA VERIFICAR WINDOWS UPDATE
function Run-WindowsUpdate {
    try {
        Write-Output "[INFO] Chequeando Windows Update..."
        $Updates = Get-WindowsUpdate -AcceptAll -Download -Install -AutoReboot
        if ($Updates) {
            Write-Output "[INFO] Actualizaciones disponibles, procediendo con la/s instalacion/es..."
            Install-WindowsUpdate -AcceptAll -Download -Install -AutoReboot | Out-String | Write-Output
            Write-Output "[SUCCESS] Actualizacion/es instalada/s!"
        } else {
            Write-Output "[INFO] No hay actualizaciones disponibles."
        }
    } catch {
        Write-Output "[ERROR] El proceso de actualización falló: $_"
        Exit 1
    }
}

# EJECUTO EL PROCESO WINDOWS UPDATE
Run-WindowsUpdate

# STOP LOG
Stop-Transcript