param(
    [string] $symbolsPath,
    [string] $searchPattern,
    [string] $sourceFolder, # Support for sourceFolder has been Deprecated.
    [string] $symbolsProduct,
    [string] $symbolsVersion,
    [string] $symbolsMaximumWaitTime,
    [string] $symbolsFolder,
    [string] $symbolsArtifactName
)

Write-Verbose "Entering script PublishSymbols.ps1"

# Import the Task.Common and Task.Internal dll that has all the cmdlets we need for Build
import-module "Microsoft.TeamFoundation.DistributedTask.Task.Internal"
import-module "Microsoft.TeamFoundation.DistributedTask.Task.Common"

# Store the path to the directory where this script is located.
[string]$scriptDirectoryPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
Write-Warning "scriptDirectoryPath = $scriptDirectoryPath"

# If symbols path is not set, we only index sources
Write-Verbose "symbolsPath= $symbolsPath"

if (!$searchPattern)
{
    $searchPattern = "**\bin\**\*.pdb"
    Write-Verbose "searchPattern not sent to script, defaulting to $searchPattern"
}

# Warn if deprecated paramter was used.
if ($sourceFolder)
{
    Write-Warning (Get-LocalizedString -Key 'The source folder parameter has been deprecated. Ignoring the value: {0}' -ArgumentList $sourceFolder)
}

if (!$symbolsProduct)
{
    $symbolsProduct = $env:Build_DefinitionName
    Write-Verbose "symbolsProduct not sent to script, defaulting to $symbolsProduct"
}

if (!$symbolsVersion)
{
    $symbolsVersion = $env:Build_BuildNumber
    Write-Verbose "symbolsVersion not sent to script, defaulting to $symbolsVersion"
}

$maxWaitTime = $null
if (!$symbolsMaximumWaitTime)
{
    $maxWaitTime = 2 * 60 * 60 * 1000 #2h in milliseconds
    Write-Verbose "symbolsMaximumWaitTime not sent to script, using the default maxWaitTime of 2 hours"
}
elseif (![Int32]::TryParse($symbolsMaximumWaitTime, [ref] $maxWaitTime))
{
    $maxWaitTime = 2 * 60 * 60 * 1000 #2h in milliseconds
    Write-Verbose "Could not parse symbolsMaximumWaitTime input, using the default maxWaitTime of 2 hours"
}
else
{
    #Convert the UI value (in minutes) to milliseconds
    $maxWaitTime = $maxWaitTime * 60 * 1000
    Write-Verbose "Converted symbolsMaximumWaitTime parameter value of $symbolsMaximumWaitTime minutes to $maxWaitTime milliseconds"
}

Write-Verbose "maxWaitTime= $maxWaitTime milliseconds"

#maxSemaphoreAge is in minutes (default to 1d)
$maxSemaphoreAge = 24 * 60
Write-Verbose "maxSemaphoreAge= $maxSemaphoreAge minutes"

Write-Verbose "symbolsFolder= $symbolsFolder"

# TODO: REMOVE THIS AND USE THE PERMALINK FROM ENV VAR
$repositoryEndpoint = Get-ServiceEndpoint -Context $distributedTaskContext -Name $env:Build_Repository_Name

#The symbols search folder defaults to source folder.  Override if symbolsFolder is passed
$symbolsSearchFolder = $env:Build_SourcesDirectory
if ($symbolsFolder)
{
    $symbolsSearchFolder = $symbolsFolder
}

Write-Host "Find-Files -SearchPattern $searchPattern -RootFolder $symbolsSearchFolder"
[Collections.Generic.List[String]]$pdbFiles = Find-Files -SearchPattern $searchPattern -RootFolder $symbolsSearchFolder
foreach ($pdbFile in $pdbFiles)
{
    Write-Verbose "pdbFile= $pdbFile"
}
$fileCount = $pdbFiles.Count
Write-Host (Get-LocalizedString -Key "Found {0} files to index..." -ArgumentList $fileCount)

Write-Host "Invoke-IndexSources -RepositoryEndpoint <repositoryEndpoint> -SourceFolder $sourceFolder -PdbFiles <pdbFiles>"
Invoke-IndexSources -RepositoryEndpoint $repositoryEndpoint -SourceFolder $sourceFolder -PdbFiles $pdbFiles

if ($symbolsPath)
{
    $utcNow = Get-Date
    $utcNow = $utcNow.ToUniversalTime()
    $semaphoreMessage = "Machine: $env:ComputerName, BuildUri: $env:Build_BuildUri, BuildNumber: $env:Build_BuildNumber, RepositoryName: $env:Build_Repository_Name, RepositoryUri: $env:Build_Repository_Uri, Team Project: $env:System_TeamProject, CollectionUri: $env:System_TeamFoundationCollectionUri at $utcNow UTC"
    Write-Verbose "semaphoreMessage= $semaphoreMessage"

    Write-Host "Invoke-PublishSymbols -PdbFiles <pdbFiles> -Share $symbolsPath -Product $symbolsProduct -Version $symbolsVersion -MaximumWaitTime $maxWaitTime -MaximumSemaphoreAge $maxSemaphoreAge -ArtifactName $symbolsArtifactName"
    Invoke-PublishSymbols -PdbFiles $pdbFiles -Share $symbolsPath -Product $symbolsProduct -Version $symbolsVersion -MaximumWaitTime $maxWaitTime -MaximumSemaphoreAge $maxSemaphoreAge -SemaphoreMessage $semaphoreMessage -ArtifactName $symbolsArtifactName
}
else
{
    Write-Verbose "symbolsPath was not set on script, publish symbols step was skipped"
}

Write-Verbose "Leaving script PublishSymbols.ps1"
