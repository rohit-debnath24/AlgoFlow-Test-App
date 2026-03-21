# 1. Read .env file in the same directory as the script
$envFilePath = Join-Path $PSScriptRoot ".env"

if (-not (Test-Path $envFilePath)) {
    Write-Host "❌ No .env file found at: $envFilePath" -ForegroundColor Red
    Write-Host "Please create a .env file containing DOCKER_USERNAME, DOCKER_PASSWORD, and BACKEND_URL." -ForegroundColor Yellow
    exit 1
}

# 2. Securely parse the .env file into a hashtable
$envHash = @{}
Get-Content $envFilePath | Where-Object { $_ -match "^\s*([^#][^=]+)=(.*)$" } | ForEach-Object {
    $envHash[$matches[1].Trim()] = $matches[2].Trim()
}

$DockerUser = $envHash["DOCKER_USERNAME"]
$DockerPass = $envHash["DOCKER_PASSWORD"]
$BackendUrl = $envHash["BACKEND_URL"]

if ([string]::IsNullOrWhiteSpace($DockerUser) -or [string]::IsNullOrWhiteSpace($DockerPass) -or [string]::IsNullOrWhiteSpace($BackendUrl)) {
    Write-Host "❌ Error: One or more required variables are missing from your .env file." -ForegroundColor Red
    exit 1
}

# 3. Check if GitHub CLI is installed or find it in default location
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    $ghPath = "C:\Program Files\GitHub CLI"
    if (Test-Path "$ghPath\gh.exe") {
        # Temporarily add it to PATH for this session
        $env:Path += ";$ghPath"
    } else {
        Write-Host "❌ GitHub CLI (gh) is not installed." -ForegroundColor Red
        Write-Host "Please install it from https://cli.github.com/ or run 'winget install --id GitHub.cli'" -ForegroundColor Yellow
        exit 1
    }
}

# 4. Check if user is logged into GitHub CLI
$authStatus = gh auth status 2>&1
if ($authStatus -match "You are not logged into any GitHub hosts") {
    Write-Host "⏳ You need to login to GitHub CLI first. Running 'gh auth login'..." -ForegroundColor Cyan
    gh auth login
}

# 5. Fetch all the user's Github repos and display an interactive menu
Write-Host "Fetching your GitHub repositories..." -ForegroundColor Cyan
$reposJson = gh repo list --json nameWithOwner --limit 100 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to fetch repositories from GitHub." -ForegroundColor Red
    Write-Host "Make sure your GitHub CLI is authenticated properly (run 'gh auth login')." -ForegroundColor Yellow
    exit 1
}

$repos = $reposJson | ConvertFrom-Json
if ($null -eq $repos -or $repos.Count -eq 0) {
    Write-Host "❌ You don't seem to have any repositories on your GitHub account yet." -ForegroundColor Red
    exit 1
}

Write-Host "`n============== GLOBAL SECRET SYNC ==============" -ForegroundColor Magenta
Write-Host "Which repository would you like to inject the local .env secrets into?" -ForegroundColor Yellow

for ($i = 0; $i -lt $repos.Count; $i++) {
    Write-Host "  [$i] $($repos[$i].nameWithOwner)" -ForegroundColor White
}
Write-Host "================================================" -ForegroundColor Magenta

$selection = Read-Host "`nEnter the number of the target repository (or type 'q' to quit)"

if ($selection -eq 'q' -or [string]::IsNullOrWhiteSpace($selection)) {
    Write-Host "Operation cancelled." -ForegroundColor Yellow
    exit 0
}

try {
    $selInt = [int]$selection
    if ($selInt -lt 0 -or $selInt -ge $repos.Count) { throw }
} catch {
    Write-Host "❌ Invalid selection. Please enter a valid number from the list." -ForegroundColor Red
    exit 1
}

$targetRepo = $repos[$selInt].nameWithOwner

Write-Host "🚀 Preparing to inject secrets from your local .env into $targetRepo..." -ForegroundColor Cyan

# 6. Inject Secrets remotely into the selected repository
gh secret set DOCKER_USERNAME --body $DockerUser --repo $targetRepo
if ($LASTEXITCODE -eq 0) { Write-Host "✅ DOCKER_USERNAME set successfully on $targetRepo." -ForegroundColor Green }

gh secret set DOCKER_PASSWORD --body $DockerPass --repo $targetRepo
if ($LASTEXITCODE -eq 0) { Write-Host "✅ DOCKER_PASSWORD set successfully on $targetRepo." -ForegroundColor Green }

gh secret set BACKEND_URL --body $BackendUrl --repo $targetRepo
if ($LASTEXITCODE -eq 0) { Write-Host "✅ BACKEND_URL set successfully on $targetRepo." -ForegroundColor Green }

Write-Host "🎉 All environment secrets have been globally synced to $targetRepo! You can now just 'git push' to deploy." -ForegroundColor Magenta
