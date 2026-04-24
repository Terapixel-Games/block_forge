[CmdletBinding()]
param(
    [ValidateSet("up", "down", "test")]
    [string]$Action = "test",
    [switch]$NoBuild,
    [switch]$KeepRunning,
    [int]$TimeoutSeconds = 180
)

$ErrorActionPreference = "Stop"

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Resolve-Path (Join-Path $scriptRoot "..")
$composeFile = Join-Path $repoRoot "backend/ci/docker-compose.stack.yml"
$projectName = if ($env:STACK_PROJECT_NAME) { $env:STACK_PROJECT_NAME } else { "blockforge-ci" }
$upArgs = @("up", "-d")
if (-not $NoBuild) {
    $upArgs += "--build"
}
$upServices = @("terapixel-platform", "cockroachdb", "nakama")
$dockerCmd = Get-Command docker -ErrorAction SilentlyContinue

function Invoke-Compose {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Args)
    & docker compose -p $projectName -f $composeFile @Args
    if ($LASTEXITCODE -ne 0) {
        throw "docker compose command failed: docker compose -p $projectName -f $composeFile $($Args -join ' ')"
    }
}

function Wait-ForHttp {
    param(
        [string]$Name,
        [string]$Url,
        [int]$TimeoutSec = 180
    )

    $deadline = (Get-Date).AddSeconds($TimeoutSec)
    while ((Get-Date) -lt $deadline) {
        try {
            $invokeParams = @{
                Uri        = $Url
                TimeoutSec = 5
            }
            if ((Get-Command Invoke-WebRequest).Parameters.ContainsKey("UseBasicParsing")) {
                $invokeParams["UseBasicParsing"] = $true
            }
            $response = Invoke-WebRequest @invokeParams
            if ([int]$response.StatusCode -ge 200 -and [int]$response.StatusCode -lt 500) {
                Write-Host "$Name is reachable at $Url (status $([int]$response.StatusCode))."
                return
            }
        }
        catch {
            # Service is still starting.
        }
        Start-Sleep -Seconds 2
    }

    throw "Timed out waiting for $Name at $Url."
}

function Wait-ForTcp {
    param(
        [string]$Name,
        [string]$Host,
        [int]$Port,
        [int]$TimeoutSec = 180
    )

    $deadline = (Get-Date).AddSeconds($TimeoutSec)
    while ((Get-Date) -lt $deadline) {
        $client = New-Object System.Net.Sockets.TcpClient
        try {
            $task = $client.ConnectAsync($Host, $Port)
            if ($task.Wait(1500) -and $client.Connected) {
                Write-Host "$Name is listening at ${Host}:$Port."
                return
            }
        }
        catch {
            # Service is still starting.
        }
        finally {
            $client.Dispose()
        }
        Start-Sleep -Seconds 2
    }

    throw "Timed out waiting for $Name at ${Host}:$Port."
}

function Show-ComposeLogs {
    try {
        & docker compose -p $projectName -f $composeFile logs --no-color --tail 200
    }
    catch {
        Write-Warning "Failed to fetch docker compose logs: $($_.Exception.Message)"
    }
}

if (-not (Test-Path $composeFile)) {
    throw "Compose file not found at $composeFile."
}
if ($null -eq $dockerCmd) {
    throw "Docker CLI was not found in PATH. Install Docker Desktop (or Docker Engine + compose plugin) to run this command."
}

switch ($Action) {
    "up" {
        Invoke-Compose @upArgs @upServices
        Write-Host "Stack is up."
    }
    "down" {
        Invoke-Compose down --volumes --remove-orphans
        Write-Host "Stack is down."
    }
    "test" {
        try {
            Invoke-Compose down --volumes --remove-orphans
            Invoke-Compose @upArgs @upServices
            Wait-ForHttp -Name "Terapixel platform mock" -Url "http://127.0.0.1:18080/health" -TimeoutSec $TimeoutSeconds
            Wait-ForTcp -Name "Nakama" -Host "127.0.0.1" -Port 17350 -TimeoutSec $TimeoutSeconds
            Invoke-Compose run --rm godot-smoke
            Write-Host "Stack smoke tests passed."
        }
        catch {
            Show-ComposeLogs
            throw
        }
        finally {
            if (-not $KeepRunning) {
                Invoke-Compose down --volumes --remove-orphans
            }
            else {
                Write-Host "Keeping stack running because -KeepRunning was set."
            }
        }
    }
}
