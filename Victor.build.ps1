#requires -Modules @{ModuleName = 'InvokeBuild'; ModuleVersion = '5.9.1'}

[Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidUsingInvokeExpression', '')]
[Diagnostics.CodeAnalysis.SuppressMessage('PSReviewUnusedParameter', '')]
param
(
    [version]$NewVersion,

    [string]$PSGalleryApiKey
)

# Synopsis: Update manifest version
task UpdateVersion {
    $ManifestPath = "Victor.psd1"
    $ManifestContent = Get-Content $ManifestPath -Raw
    $Manifest = Invoke-Expression "DATA {$ManifestContent}"

    if ($NewVersion -le [version]$Manifest.ModuleVersion)
    {
        throw "Can't go backwards: $NewVersion =\=> $($Manifest.ModuleVersion)"
    }

    $ModuleVersionPattern = "(?<=\n\s*ModuleVersion\s*=\s*(['`"]))(\d+\.)+\d+"

    $ManifestContent = $ManifestContent -replace $ModuleVersionPattern, $NewVersion
    $ManifestContent | Out-File $ManifestPath -Encoding utf8
}

# Synopsis: Run PSSA, excluding Tests folder and *.build.ps1
task PSSA {
    $Files = Get-ChildItem -File -Recurse -Filter *.ps*1 | Where-Object FullName -notmatch '\bTests\b|\.build\.ps1$|install-build-dependencies\.ps1'
    $Files | ForEach-Object {
        Invoke-ScriptAnalyzer -Path $_.FullName -Recurse -Settings .\.vscode\PSScriptAnalyzerSettings.psd1
    }
}

# Synopsis: Clean build folder
task Clean {
    remove Build
}

# Synopsis: Build module at manifest version
task Build Clean, {
    $ManifestPath = "Victor.psd1"
    $ManifestContent = Get-Content $ManifestPath -Raw
    $Manifest = Invoke-Expression "DATA {$ManifestContent}"

    $Version = $Manifest.ModuleVersion
    $BuildFolder = New-Item "Build/Victor/$Version" -ItemType Directory -Force
    $BuiltManifestPath = Join-Path $BuildFolder $ManifestPath
    $BuiltRootModulePath = Join-Path $BuildFolder $Manifest.RootModule

    $CsProjPath = $PSScriptRoot |
        Join-Path -ChildPath Victor |
        Join-Path -ChildPath Victor.csproj
    dotnet publish $CsProjPath --output $BuildFolder
    assert $?

    Copy-Item $ManifestPath $BuildFolder
    Copy-Item "README.md" $BuildFolder
    Copy-Item "LICENSE" $BuildFolder

    $UsingStatements = @()
    $RootModuleContent = Get-Content $Manifest.RootModule
    foreach ($Region in 'Classes', 'Private', 'Public')
    {
        $Files = Get-ChildItem $Region -ErrorAction Ignore
        if (-not $Files)
        {
            continue
        }

        $ImportStatement = $RootModuleContent.Where({$_ -match "Get-ChildItem .*[\\/]$Region[\\/].*\. \`$_"})
        if (-not $ImportStatement)
        {
            continue
        }
        $ImportLine = $RootModuleContent.IndexOf($ImportStatement)

        $RegionContent = $Files |
            ForEach-Object {
                [string[]]$_Content = Get-Content $_.FullName

                $UsingStatements += $_Content.Where({$_ -match '^\s*function'}, 'Until')

                $_Content.Where({$_ -match '^\s*function'}, 'SkipUntil') | Out-String
            }

        $RootModuleContent[$ImportLine] = (
            "#region $Region",
            $RegionContent.Trim(),
            "#endregion $Region"
        ) | Out-String
    }

    $UsingStatements = @($UsingStatements) -match '^\s*using ' |
        ForEach-Object Trim |
        Sort-Object -Unique

    if ($UsingStatements)
    {
        $RootModuleContent = $UsingStatements, "", $RootModuleContent | Write-Output
    }

    $RootModuleContent | Out-File $BuiltRootModulePath -Encoding utf8NoBOM
}

# Synopsis: Import latest version of module from build folder
task Import Build, {
    Import-Module "$BuildRoot/Build/Victor" -Force -Global -ErrorAction Stop
}

task Test Import, {
    Invoke-Pester
}

task Publish Build, {
    $UnversionedBase = "Build/Victor"
    $VersionedBase = Get-Module $UnversionedBase -ListAvailable | ForEach-Object ModuleBase
    Get-ChildItem $VersionedBase | Copy-Item -Destination $UnversionedBase
    remove $VersionedBase
    Publish-PSResource -Verbose -Path $UnversionedBase -DestinationPath Build -Repository PSGallery -ApiKey $PSGalleryApiKey
}

task . PSSA, Test
