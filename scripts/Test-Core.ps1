$ErrorActionPreference = "Stop"

$swiftRoot = Join-Path $env:LOCALAPPDATA "Programs\Swift"
$sdkRoot = Join-Path $swiftRoot "Platforms\6.3.1\Windows.platform\Developer\SDKs\Windows.sdk"
$msvcBin = "C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools\VC\Tools\MSVC\14.50.35717\bin\Hostx64\x64"

$env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") +
    ";" +
    [Environment]::GetEnvironmentVariable("Path", "User") +
    ";" +
    $msvcBin

$env:SDKROOT = $sdkRoot
$env:SWIFTFLAGS = "-sdk `"$sdkRoot`" -resource-dir `"$sdkRoot\usr\lib\swift`""

swift test

