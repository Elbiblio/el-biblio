param(
    [string]$OutputDir = (Join-Path $PSScriptRoot '..\certs'),
    [string]$CommonName = 'ElBiblio Distribution',
    [string]$Organization = 'El-Biblio',
    [string]$OrganizationalUnit = 'Mobile',
    [string]$City = 'Dover',
    [string]$State = 'Delaware',
    [string]$Country = 'US',
    [string]$Email = 'info@elbiblio.com',
    [int]$KeySize = 2048
)

function Resolve-OpenSsl {
    $candidates = @(
        'openssl',
        "${env:ProgramFiles}\Git\usr\bin\openssl.exe",
        "${env:ProgramFiles(x86)}\Git\usr\bin\openssl.exe",
        "C:\Program Files\OpenSSL-Win64\bin\openssl.exe",
        "C:\Program Files\OpenSSL-Win32\bin\openssl.exe"
    ) | Where-Object { $_ -and $_.Trim() -ne '' }

    foreach ($candidate in $candidates) {
        try {
            $resolved = (Get-Command $candidate -ErrorAction Stop).Source
            if ($resolved) {
                return $resolved
            }
        } catch {
            continue
        }
    }

    throw "OpenSSL executable not found. Install OpenSSL (or Git for Windows) and ensure it is in PATH."
}

$openssl = Resolve-OpenSsl

$OutputDir = Resolve-Path -Path (New-Item -ItemType Directory -Force -Path $OutputDir)
$keyPath = Join-Path $OutputDir 'elbiblio-dist.key'
$csrPath = Join-Path $OutputDir 'elbiblio-dist.csr'
$configPath = Join-Path $OutputDir 'csr.conf'

$subject = @{
    C = $Country
    ST = $State
    L = $City
    O = $Organization
    OU = $OrganizationalUnit
    CN = $CommonName
    emailAddress = $Email
}

$configContent = @"
[req]
prompt = no
encrypt_key = no
default_bits = $KeySize
default_md = sha256
distinguished_name = dn

[dn]
C = $($subject.C)
ST = $($subject.ST)
L = $($subject.L)
O = $($subject.O)
OU = $($subject.OU)
CN = $($subject.CN)
emailAddress = $($subject.emailAddress)
"@

Set-Content -Path $configPath -Value $configContent -Encoding UTF8

Write-Host "Using OpenSSL at: $openssl"
Write-Host "Generating private key: $keyPath"
& $openssl genrsa -out $keyPath $KeySize | Out-Null

Write-Host "Generating CSR: $csrPath"
& $openssl req -new -key $keyPath -out $csrPath -config $configPath | Out-Null

Write-Host "CSR generated at $csrPath"
Write-Host "Private key generated at $keyPath"
Write-Host 'Keep the private key secure and upload the CSR to Apple Developer portal.'
