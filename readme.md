# RELEASE PIPELINE ADJUSTED

- update files in repository

 create release called "empty" with one step and run (will empty the resource group)
> azure resource group deployment 
> - linking to empty.json template
> - linking to empty.param.json parameters  and 
> - Deployment Mode - Complete


refactor azure function 

```csharp
    public static class ToggleFunction
    {
        [FunctionName("toggle")]
        public static async Task<HttpResponseMessage> Run([HttpTrigger(AuthorizationLevel.Function, "get", "post", Route = null)] HttpRequest req,
            ILogger log)
        {
            var userIdKey = req.Query.FirstOrDefault(q => string.Equals(q.Key, "UserId", StringComparison.OrdinalIgnoreCase));
            var userId = string.IsNullOrEmpty(userIdKey.Value) ? int.MaxValue : Convert.ToInt64(userIdKey.Value);
            //refactor this
            var apiUrl = Environment.GetEnvironmentVariable("ApiUrl");
            var url = $"{apiUrl}/api/{(userId > 10 ? "v1" : "v2")}/specials/GetSpecialsByUserId?id={userId}";
            using (HttpClient httpClient = new HttpClient())
            {
                return await httpClient.GetAsync(url);
            }
        }
    }
```


refactor storescontroller (browse method)

```csharp
        public async Task<IActionResult> Browse(int categoryId)
        {
            // Retrieve category and its associated products from database
            // TODO [EF] Swap to native support for loading related data when available
            var categoryModel = _db.Categories.Single(g => g.CategoryId == categoryId);

            if (categoryModel.Name.ToLower().Equals("oil"))
            {
                var url = Environment.GetEnvironmentVariable("FunctionUrl");
                if (HttpContext.User.Identity.IsAuthenticated)
                {
                    url += HttpContext.User.Identity.Name.Equals("Administrator@test.com") ? "&UserID=1" : "&UserID=50";
                }
                using (HttpClient client = new HttpClient())
                {
                    var jsonProducts = await client.GetStringAsync(url);
                    var products = JsonConvert.DeserializeObject<List<Product>>(jsonProducts);
                    foreach (Product product in products)
                    {
                        product.ProductId = _db.Products.First(a => a.SkuNumber == product.SkuNumber).ProductId;
                    }

                    categoryModel.Products = products;
                }
            }
            else
            {
                categoryModel.Products = _db.Products.Where(a => a.CategoryId == categoryModel.CategoryId).ToList();
            }
            return View(categoryModel);

        }
```

add empty web.config into PartsUnlimited.API & PartsUnlimited.Function projects


adjust build definition

> publish also /scripts as build artifacts

adjust release definition

> remove these parameters (from variables and also from release step - optional parameters mapping)
> - ContainerName
> - PartsUnlimitedServerAdminLoginPasswordForTest
> - Cdn* 




# UNIT TESTING

adjust unit testing project (include ```<IsTestProject>``` tag)

```xml
 <PropertyGroup>
    <TargetFramework>netcoreapp1.0</TargetFramework>
    <AssemblyName>PartsUnlimited.UnitTests</AssemblyName>
    <PackageId>PartsUnlimited.UnitTests</PackageId>
    <GenerateRuntimeConfigurationFiles>true</GenerateRuntimeConfigurationFiles>
    <RuntimeFrameworkVersion>1.0.4</RuntimeFrameworkVersion>
    <PackageTargetFallback>$(PackageTargetFallback);dnxcore50;portable-net45+win8</PackageTargetFallback>
    <IsTestProject>true</IsTestProject>
  </PropertyGroup>
```

write unit test - issue with netcore 1.0 ... supported from 2.0 !

**probably we need to import unit testing repo and create build with unit tests there**

# SONARQUBE


- create new repository (sonarqube)
- import this repo into it https://github.com/mnoskovic/sonarqube.git

- download sonarqube.json (locally)
- create new build by "importing existing build definition" (drop json file)
- fix all issues 
> - select hosted agent
> - select azure account for each task
> - provide resource group name "sonarqube-data" for database and "sonarqube" for other resources
> - adjust variables (name e.g. **mno**sq, password for database and encrypt)
- queue new build


- install sonarqube extensions into azure devops (marketplace)
- login to sonarqube "name".azurewebsites.net
- change admin password
- create token and copy to clipboard
- create ednpoint in azure devops
- adjust build to use sonarqube


- adjust the build csproj (sample:)

```xml
    <DebugType>Full</DebugType> 
    <ProjectGuid>{59F65B6D-6476-4517-A5A6-7FA64E13C0CA}</ProjectGuid>

```


- adjust dotnet core test action 
> turn of checkbox for generating code coverage and replace with custom parameters

```
--logger trx;LogFileName=Test-Output.xml --results-directory $(Common.TestResultsDirectory) --collect "Code coverage"
```


adjust nuget packages in unit test project

> - install Microsoft.DotNet.InternalAbstractions
> - update  Microsoft.Net.Test.Sdk   15.8.0



# SELENIUM

- run azure deploy from github
- create new repo and import tests
- build solution and provide outcomes in output (for javascript part publish javascripts, json, feature files as artifacts)

- on release process download artifacts
- for javascript based tests install dependencies (npm install) 
- run tests (c# based, js based)