# Install required module if not already installed
Install-Module -Name Microsoft.Graph.Authentication -Force -AllowClobber

# Import required modules
Import-Module Microsoft.Graph.Authentication

# Connect to Microsoft Graph
Connect-MgGraph -Scopes "Application.Read.All"

# Retrieve all applications
$allApplications = @()
$pageSize = 100
$nextLink = $null

do {
    $applicationsPage = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/applications\$($nextLink -replace '\?', '&')"

    $allApplications += $applicationsPage.Value

    $nextLink = $applicationsPage.'@odata.nextLink'
} while ($nextLink)

# Query each application
foreach ($application in $allApplications) {
    Write-Host "Application Name: $($application.displayName)"
    Write-Host "Application ID: $($application.id)"
    
# Retrieve secrets
    $secretsUri = "https://graph.microsoft.com/v1.0/applications/$($application.id)/passwordCredentials"
    $secrets = Invoke-MgGraphRequest -Method GET -Uri $secretsUri

# Query secrets
    foreach ($secret in $secrets.value) {
        try {
            $expiryDateTime = [DateTime]$secret.endDateTime
            $expiryDate = $expiryDateTime.Date

            if ($expiryDate -ne $null) {
                $daysUntilExpiry = ($expiryDate - (Get-Date).Date).Days

                if ($daysUntilExpiry -le 90) {
                    Write-Host -ForegroundColor Red "Secret Expiring within 3 Months:"
                    Write-Host "  Key ID: $($secret.keyId)"
                    Write-Host "  Expiry Date: $($expiryDate.ToString("yyyy-MM-dd"))"
                    Write-Host "  Days Until Expiry: $daysUntilExpiry"
                }
            } else {
                throw "Invalid DateTime format"
            }
        }
        catch {
            Write-Host "Error parsing secret expiry date. Skipping secret."
        }
    }

    Write-Host
}

# Disconnect from Microsoft Graph
Disconnect-MgGraph