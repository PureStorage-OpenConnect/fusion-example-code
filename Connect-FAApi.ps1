<#
.SYNOPSIS
    Authenticates to Pure Storage FlashArray REST API and retrieves session token.
.DESCRIPTION
    - Authenticates using API token.
    - Retrieves the x-auth-token from response headers for subsequent requests.
    - Dynamically queries the FlashArray for the latest available API version and uses it for requests.
.PARAMETER Target
    Required. The FQDN or IP address of the FlashArray to target for REST API calls.
.PARAMETER ApiToken
    Required. The API token used for authentication with the FlashArray REST API.
.EXAMPLE
    .\Connect-FAApi.ps1 -Target "10.21.204.131" -ApiToken "366a220f-c563-f660-54d0-a48532628005"
.NOTES
    Author: mnelson@purestorage.com
    Date: 10/23/2023
    Version: 1.1
#>

param (
    [Parameter(Mandatory = $true)]
    [string]$Target,
    [Parameter(Mandatory = $true)]
    [string]$ApiToken
)

################ SETUP ################
# Query the array for the latest available API version
try {
    $apiVersions = Invoke-RestMethod -Uri "https://$Target/api/api_version" -Method Get -SkipCertificateCheck
    $numericApiVersions = $apiVersions.version | Where-Object { $_ -match '^\d+(\.\d+)*$' -and $_ -notmatch '^2\.x$' }
    $latestApiVersion = ($numericApiVersions | Sort-Object { [version]$_ } -Descending)[0]
    Write-Host "Latest API Version detected:" $latestApiVersion
}
catch {
    Write-Host "Could not retrieve API version, defaulting to 2.45"
    $latestApiVersion = "2.45"
}

# Set the Base Uri
if ($latestApiVersion) {
    $baseUrl = "https://$Target/api/$latestApiVersion"
}

# Prepare headers for authentication
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers["api-token"] = $ApiToken

# Authenticate and get session token
$response = Invoke-RestMethod "https://$Target/api/$latestApiVersion/login" -Method 'POST' -Headers $headers -SkipCertificateCheck -ResponseHeadersVariable "respHeaders"

# Display the value of "username" from the response, if present
if ($response.items -and $response.items[0].username) {
    Write-Host "Username:" $response.items[0].username
}
else {
    Write-Host "Username field not found in response."
}

# TO-DO: Check if user is LDAP or local

# Parse "x-auth-token" from response headers and store in $xAuthHeader
$xAuthHeader = $respHeaders["x-auth-token"]
Write-Host "x-auth-token:" $xAuthHeader

# Add x-auth-token to headers for subsequent requests
$headers.Add("x-auth-token", $xAuthHeader)

# You can now use $headers for further authenticated requests to the FA API
###########################################################################

# optional pagination & limit code
$continuation_token = $null
$limit = 10  # Adjust as needed

################ FLEETS ################

# Get Fleet name
$fleetsResponse = Invoke-RestMethod -Uri "$baseUrl/fleets" -Method Get -Headers $headers -SkipCertificateCheck
$fleetName = $fleetsResponse.items[0].name
#Write-Host "Fleet Name: $fleetName"

# Get fleet members
$membersUrl = "$baseUrl/fleets/members?fleet_name=$fleetName"
$membersResponse = Invoke-RestMethod -Uri $membersUrl -Method Get -Headers $headers -SkipCertificateCheck

if (-not $membersResponse.items -or $membersResponse.items.Count -eq 0) {
    Write-Error "No fleet members found."
    exit 1
}

# Extract Fleet member names
$VAR_RESULTS = @()
foreach ($item in $membersResponse.items) {
    if ($item.member -and $item.member.name) {
        $VAR_RESULTS += $item.member.name
    }
    elseif ($item.name) {
        $VAR_RESULTS += $item.name
    }
}

if ($VAR_RESULTS.Count -eq 0) {
    Write-Error "No member names found in fleet members response."
    exit 1
}

# Write out the fleet members
#Write-Host "Extracted Member Names: $($VAR_RESULTS -join ', ')"

################ FLEET VOLUMES QUERY ################
# Query volumes for extracted member names
$volumesUrl = "$baseUrl/volumes?context_names=$($VAR_RESULTS -join ',')"

## uncomment for full response - no limit, and comment out pagination code below
#$volumesResponse = Invoke-RestMethod -Uri $volumesUrl -Method Get -Headers $headers -SkipCertificateCheck
#$volumesResponse | ConvertTo-Json -Depth 5

## with paginated reponse
do {
    ## Build the query string for pagination
    $queryString = "?limit=$limit"
    if ($continuation_token) {
        $queryString += "&continuation_token=$continuation_token"
    }
    $volumesUrl = "$baseUrl/volumes$queryString"
    ## Invoke REST method and capture response headers
    $volumesResponse = Invoke-RestMethod -Uri $volumesUrl -Method Get -Headers $headers -SkipCertificateCheck -ResponseHeadersVariable respHeaders
    ## Output volumes data
    $volumesResponse | ConvertTo-Json -Depth 5
    ## Extract x-next-token from response headers for next page
    $continuation_token = $respHeaders["x-next-token"]
    ## Continue if x-next-token is present
} while ($continuation_token)

################ FLEET HOSTS QUERY ################
# Query hosts for extracted member names
$hostsUrl = "$baseUrl/hosts?context_names=$($VAR_RESULTS -join ',')"

## full response - no limit, and comment out pagination code below
#$hostsResponse = Invoke-RestMethod -Uri $hostsUrl -Method Get -Headers $headers -SkipCertificateCheck
#$hostsResponse | ConvertTo-Json -Depth 5

## with paginated reponse
do {
    ## Build the query string for pagination
    $queryString = "?limit=$limit"
    if ($continuation_token) {
        $queryString += "&continuation_token=$continuation_token"
    }
    $hostsUrl = "$baseUrl/hosts$queryString"
    ## Invoke REST method and capture response headers
    $hostsResponse = Invoke-RestMethod -Uri $hostsUrl -Method Get -Headers $headers -SkipCertificateCheck -ResponseHeadersVariable respHeaders
    ## Output hosts data
    $hostsResponse | ConvertTo-Json -Depth 5
    ## Extract x-next-token from response headers for next page
    $continuation_token = $respHeaders["x-next-token"]
    ## Continue if x-next-token is present
} while ($continuation_token)

################ FLEET PRESETS QUERY ################
$presetsUrl = "$baseUrl/volumes?context_names=$($VAR_RESULTS -join ',')"
$presetsResponse = Invoke-RestMethod -Uri $presetsUrl -Method Get -Headers $headers -SkipCertificateCheck -ResponseHeadersVariable respHeaders $presetsResponse | ConvertTo-Json -Depth 5

################ FLEET WORKLOADS QUERY ################
$workloadsUrl = "$baseUrl/volumes?context_names=$($VAR_RESULTS -join ',')"
$workloadsResponse = Invoke-RestMethod -Uri $workloadsUrl -Method Get -Headers $headers -SkipCertificateCheck -ResponseHeadersVariable respHeaders
$workloadsResponse | ConvertTo-Json -Depth 5


################ CREATE VOLUME, HOST, AND CONNECT THEM ON ANOTHER FLASHARRAY IN THE FLEET ################

# Select a secondary FlashArray in the fleet
$otherArrayName = $VAR_RESULTS | Where-Object { $_ -ne $Target } | Select-Object -First 1
if (-not $otherArrayName) {
    Write-Error "No other FlashArray found in the fleet."
    exit 1
}
Write-Host "Selected secondary FlashArray for operations: $otherArrayName"

# Create a new volume on the secondary FlashArray
$newVolumeName = "APIDemo-Vol01"
$volumePayload = @{
    name    = $newVolumeName
    size    = 10737418240 # 10 GiB in bytes
    context = @{
        name = $otherArrayName
    }
}
$createVolumeUrl = "$baseUrl/volumes"
$createVolumeResponse = Invoke-RestMethod -Uri $createVolumeUrl -Method Post -Headers $headers -Body ($volumePayload | ConvertTo-Json) -ContentType "application/json" -SkipCertificateCheck
Write-Host "Created volume:" $newVolumeName "on" $otherArrayName

# Create a new host on the secondary FlashArray
$newHostName = "FleetDemoHost01"
$IQN = "iqn.2023-07.com.fleetdemo:host01"
$hostPayload = @{
    name    = $newHostName
    iqn     = @($IQN)
    context = @{
        name = $otherArrayName
    }
}
$createHostUrl = "$baseUrl/hosts"
$createHostResponse = Invoke-RestMethod -Uri $createHostUrl -Method Post -Headers $headers -Body ($hostPayload | ConvertTo-Json) -ContentType "application/json" -SkipCertificateCheck
Write-Host "Created host:" $newHostName "with IQN:" $IQN "on" $otherArrayName

# Connect the newly created volume to the newly created host
$connectPayload = @{
    volume = @{
        name    = $newVolumeName
        context = @{
            name = $otherArrayName
        }
    }
    host   = @{
        name    = $newHostName
        context = @{
            name = $otherArrayName
        }
    }
}
$connectUrl = "$baseUrl/host-volume-connections"
$connectResponse = Invoke-RestMethod -Uri $connectUrl -Method Post -Headers $headers -Body ($connectPayload | ConvertTo-Json) -ContentType "application/json" -SkipCertificateCheck
Write-Host "Connected volume" $newVolumeName "to host" $newHostName "on" $otherArrayName

# Output results
$createVolumeResponse | ConvertTo-Json -Depth 5
$createHostResponse | ConvertTo-Json -Depth 5
$connectResponse | ConvertTo-Json -Depth 5

# End of script
