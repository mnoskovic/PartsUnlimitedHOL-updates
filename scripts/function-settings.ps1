param
(
    [Parameter(Mandatory=$true)]
    $ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    $WebAppName,

    [Parameter(Mandatory=$false)]
    $FunctionAppName = "$WebAppName-func",
    
    [Parameter(Mandatory=$false)]
    $FunctionName = "toggle"
)

$context = Get-AzureRmContext
$subscriptionId = $context.Subscription.Id
#$subscriptionId

$tenantId = $context.Tenant.Id
#$tenantId

$accountId = $context.Account.Id
#$accountId
   
$cache = $context.TokenCache
$cacheItems= $cache.ReadItems()     
$token =  ($cacheItems | where { $_.TenantId -eq $tenantId -and $_.DisplayableId -eq $accountId })[0]
#$token

$accessToken = $token.AccessToken
#$accessToken

$uri = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.Web/sites/$FunctionAppName/functions/$FunctionName/listsecrets?api-version=2016-08-01"
#$uri
 
$headers = @{
    'Host' = 'management.azure.com'
    'Content-Type' = 'application/json';
    'Authorization' = "Bearer $accessToken";
}

$response = iwr -Method Post -Uri $uri -Headers $headers -UseBasicParsing
$responseContent = ConvertFrom-Json $response.Content
$functionUrl = $responseContent.trigger_url
#$functionUrl


$webApp = Get-AzureRmWebApp -ResourceGroupName $ResourceGroupName -Name $WebAppName
#$webApp

$webAppSettings = $webApp.SiteConfig.AppSettings
#$webAppSettings

$newWebAppSettings = @{}
ForEach ($kvp in $webAppSettings) {
    $newWebAppSettings[$kvp.Name] = $kvp.Value
}
 
$newWebAppSettings["Function"] = $functionUrl

Set-AzureRMWebApp -ResourceGroupName $ResourceGroupName -Name $WebAppName -AppSettings $newWebAppSettings 