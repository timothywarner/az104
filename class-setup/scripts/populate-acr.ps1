# Script to populate ACR with sample images
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$AcrName
)

# Function to validate Azure context
function Test-AzureContext {
    $context = Get-AzContext
    if (-not $context) {
        Write-Error "Not logged into Azure. Please run Connect-AzAccount first."
        return $false
    }

    Write-Host "`nCurrent Azure Context:"
    Write-Host "----------------------------------------"
    Write-Host "Subscription: $($context.Subscription.Name)"
    Write-Host "Account: $($context.Account.Id)"
    Write-Host "----------------------------------------`n"

    $confirmation = Read-Host "Is this the correct context? (y/n)"
    if ($confirmation -ne 'y') {
        Write-Error "Please select the correct subscription using Set-AzContext or Connect-AzAccount"
        return $false
    }
    return $true
}

# Validate Azure context
if (-not (Test-AzureContext)) {
    exit 1
}

# Login to ACR
Write-Host "Logging into ACR..."
try {
    az acr login --name $AcrName
}
catch {
    Write-Error "Failed to login to ACR: $_"
    exit 1
}

# Sample images to pull and push
$images = @(
    @{
        source = "mcr.microsoft.com/azuredocs/azure-vote-front:v1"
        target = "samples/azure-vote-front:v1"
    }
    @{
        source = "mcr.microsoft.com/oss/nginx/nginx:1.23.3"
        target = "samples/nginx:1.23.3"
    }
    @{
        source = "mcr.microsoft.com/azuredocs/aci-helloworld:latest"
        target = "samples/aci-helloworld:latest"
    }
)

# Pull and push each image
foreach ($image in $images) {
    Write-Host "`nProcessing image: $($image.source)"
    
    try {
        # Pull the image
        Write-Host "Pulling image..."
        docker pull $image.source

        # Tag for ACR
        $targetImage = "$AcrName.azurecr.io/$($image.target)"
        Write-Host "Tagging as $targetImage"
        docker tag $image.source $targetImage

        # Push to ACR
        Write-Host "Pushing to ACR..."
        docker push $targetImage

        Write-Host "Successfully processed $($image.source)" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to process $($image.source): $_"
    }
}

Write-Host "`nACR population complete!"
Write-Host "Sample images are now available in your registry under the 'samples' repository." 