# Create Privify website structure
$basePath = "C:\Users\visha\OneDrive\Documents\GitHub\Privify"

# Create directories
New-Item -ItemType Directory -Force -Path $basePath
New-Item -ItemType Directory -Force -Path "$basePath\images"
New-Item -ItemType Directory -Force -Path "$basePath\images\icons"

# Create empty HTML files
New-Item -ItemType File -Force -Path "$basePath\index.html"
New-Item -ItemType File -Force -Path "$basePath\privacy.html"
New-Item -ItemType File -Force -Path "$basePath\terms.html"
New-Item -ItemType File -Force -Path "$basePath\security.html"
New-Item -ItemType File -Force -Path "$basePath\contact.html"

# Create placeholder icon files (0 byte files for now)
$icons = @("google-icon.png", "facebook-icon.png", "linkedin-icon.png", "pinterest-icon.png", "x-icon.png", "amazon-icon.png")
foreach ($icon in $icons) {
    New-Item -ItemType File -Force -Path "$basePath\images\icons\$icon"
}

Write-Host "Folder structure created at: $basePath" -ForegroundColor Green
Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "1. Copy the HTML code into $basePath\index.html"
Write-Host "2. Add a favicon.ico file to $basePath"
Write-Host "3. Replace the placeholder icon files in $basePath\images\icons"