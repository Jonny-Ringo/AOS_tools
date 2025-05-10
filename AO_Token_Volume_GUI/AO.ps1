function Get-Page {
    param (
        [string]$cursor,
        [int]$maxRetries = 3,
        [int]$retryDelaySeconds = 2
    )

    for ($retryCount = 0; $retryCount -le $maxRetries; $retryCount++) {
        try {
            # Construct the GraphQL query as a string
            $query = @{
                query = "query {
                    transactions(
                        tags: [
                        { name: ""From-Process"", values: [""0syT13r0s0tgPmIed95bJnuSqaD29HQNN8D3ElLSrsc""] },
                        { name: ""Action"", values: [""Credit-Notice""] }
                    ],
                        block: { min: $min, max: $max },
			first: 100,
                        after: ""$cursor""
                    ) {
                        edges {
                            node {
                                id
                                tags {
                                    name
                                    value
                                }
                            }
                            cursor
                        }
                        pageInfo {
                            hasNextPage
                        }
                    }
                }"
            }

            # Convert the hashtable to a JSON string
            $jsonQuery = $query | ConvertTo-Json -Compress

            # Make the API request
            $response = Invoke-RestMethod -Uri 'https://arweave-search.goldsky.com/graphql' `
                                       -Method POST `
                                       -ContentType 'application/json' `
                                       -Body $jsonQuery

            # If successful, return the response immediately
            return $response
        }
        catch {
            $retryNumber = $retryCount + 1
            Write-Host "Request failed (Attempt $retryNumber of $($maxRetries + 1)): $($_.Exception.Message)" -ForegroundColor Yellow
            
            if ($retryCount -eq $maxRetries) {
                Write-Host "Max retries reached. Moving to next page..." -ForegroundColor Red
                return $null
            }
            
            $delay = $retryDelaySeconds * [Math]::Pow(2, $retryCount)  # Exponential backoff
            Write-Host "Waiting $delay seconds before retry..." -ForegroundColor Yellow
            Start-Sleep -Seconds $delay
        }
    }
}

Write-Host "Starting script..."

$min = $args[0]
$max = $args[1]
$cursor = ""
$total = [long]0
$pageNum = 1

Write-Host "Getting total volume for interactions between $min and $max"

while ($true) {
    Write-Host "Getting page $pageNum..."
    $pageNum++

    # Fetch the page data
    $page = Get-Page -cursor $cursor
    
    # If page is null (all retries failed), continue to next iteration
    if ($null -eq $page) {
        Write-Host "Skipping failed page and continuing..." -ForegroundColor Yellow
        # Use the existing cursor to try the next page
        continue
    }
    
    Write-Host "Fetched data for page $pageNum"

    # Check if the edges array is not null or empty
    if ($null -eq $page.data.transactions.edges -or $page.data.transactions.edges.Count -eq 0) {
        Write-Host "No more transactions found."
        break
    }

    # Sum the quantities from the page using [long] for large numbers
    $pageQty = $page.data.transactions.edges.node.tags |
               Where-Object { $_.name -eq "Quantity" } |
               ForEach-Object { [long]$_.value } |
               Measure-Object -Sum |
               Select-Object -ExpandProperty Sum

    Write-Host "Transfers from page: $pageQty"
    $total += $pageQty
    Write-Host "Current total: $total"

    # Check if there's another page
    if ($page.data.transactions.pageInfo.hasNextPage -eq $false) {
        Write-Host "No more pages to fetch."
        break
    }

    # Update the cursor
    $cursor = $page.data.transactions.edges[-1].cursor
    Write-Host "Updated cursor to: $cursor"

}

# Ensure the final total is displayed as a full integer
Write-Host ("Final total: {0:N0}" -f [math]::truncate($total)) -ForegroundColor Green
Write-Host "Finished script."