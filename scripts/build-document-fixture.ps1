param(
    [string]$Sdk = "$env:LOCALAPPDATA/Android/Sdk",
    [string]$JavaHome = $env:JAVA_HOME,
    [string]$Output = "$PSScriptRoot/../.local/document-fixture"
)
$ErrorActionPreference = 'Stop'
if (-not $JavaHome) { throw 'Specify a JDK using -JavaHome.' }
$root = Split-Path $PSScriptRoot -Parent
$tools = Join-Path $Sdk 'build-tools/36.0.0'
$androidJar = Join-Path $Sdk 'platforms/android-36/android.jar'
$classes = Join-Path $Output 'classes'
$dex = Join-Path $Output 'dex'
New-Item -ItemType Directory -Force $classes,$dex | Out-Null
$unsigned = Join-Path $Output 'unsigned.apk'
$apk = Join-Path $Output 'documents-fixture.apk'
$key = Join-Path $Output 'fixture.keystore'
$previousJava = $env:JAVA_HOME
$env:JAVA_HOME = $JavaHome
try {
    & "$JavaHome/bin/javac.exe" -encoding UTF-8 -source 8 -target 8 -classpath $androidJar -d $classes "$root/test/android_fixture/DocumentsFixture.java"
    if ($LASTEXITCODE) { throw 'Fixture Java compilation failed.' }
    $classFiles = @(Get-ChildItem -LiteralPath $classes -Recurse -Filter '*.class' | ForEach-Object FullName)
    & "$tools/d8.bat" --min-api 28 --lib $androidJar --output $dex @classFiles
    if ($LASTEXITCODE) { throw 'Fixture dex compilation failed.' }
    & "$tools/aapt2.exe" link --manifest "$root/test/android_fixture/AndroidManifest.xml" -I $androidJar -o $unsigned
    if ($LASTEXITCODE) { throw 'Fixture packaging failed.' }
    & "$JavaHome/bin/jar.exe" uf $unsigned -C $dex classes.dex
    if ($LASTEXITCODE) { throw 'Fixture dex packaging failed.' }
    & "$tools/zipalign.exe" -f 4 $unsigned $apk
    if ($LASTEXITCODE) { throw 'Fixture alignment failed.' }
    if (-not (Test-Path -LiteralPath $key)) {
        # Public test credentials, separate from the application's release key.
        & "$JavaHome/bin/keytool.exe" -genkeypair -keystore $key -storepass android -keypass android -alias fixture -keyalg RSA -validity 1000 -dname 'CN=CuteLauncher test fixture' -noprompt
        if ($LASTEXITCODE) { throw 'Fixture key generation failed.' }
    }
    & "$tools/apksigner.bat" sign --ks $key --ks-pass pass:android --key-pass pass:android $apk
    if ($LASTEXITCODE) { throw 'Fixture signing failed.' }
    Write-Output $apk
} finally {
    if ($null -eq $previousJava) { Remove-Item Env:JAVA_HOME -ErrorAction SilentlyContinue }
    else { $env:JAVA_HOME = $previousJava }
}
