# Set the Google Auth parameters. Fill in your RefreshToken, ClientID, and ClientSecret
$params = @{
    Uri = 'https://accounts.google.com/o/oauth2/token'
    Body = @(
        "refresh_token=1//04o70qMtIzHgPCgYIARAAGAQSNwF-L9IryhKNV765opR5EUbmhWhLnLHUCSf1gUxRBw5GQgmsTo7tyz8Vu-l_gHnljYB01n53nks", # Replace $RefreshToken with your refresh token
        "client_id=737896359637-e38t9pq2cgnidibf04b6jrus9nall1rb.apps.googleusercontent.com",         # Replace $ClientID with your client ID
        "client_secret=3DtoKUe3mSOBDIs6f7rooIgn", # Replace $ClientSecret with your client secret
        "grant_type=refresh_token"
    ) -join '&'
    Method = 'Post'
    ContentType = 'application/x-www-form-urlencoded'
}
$accessToken = (Invoke-RestMethod @params).access_token

# Change this to the file you want to upload
$SourceFile = 'C:\Users\pwlog.txt'

# Get the source file contents and details, encode in base64
$sourceItem = Get-Item $sourceFile
$sourceBase64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($sourceItem.FullName))
$sourceMime = [System.Web.MimeMapping]::GetMimeMapping($sourceItem.FullName)

# If uploading to a Team Drive, set this to 'true'
$supportsTeamDrives = 'false'

# Set the file metadata
$uploadMetadata = @{
    originalFilename = $sourceItem.Name
    name = $sourceItem.Name
    description = $sourceItem.VersionInfo.FileDescription
    #parents = @('https://drive.google.com/drive/folders/1l_n9Vq2lI4dlMn_2uh7G7PEuDdyZrrh_') # Include to upload to a specific folder
    #teamDriveId = ‘teamDriveId’            # Include to upload to a specific teamdrive
}

# Set the upload body
$uploadBody = @"
--boundary
Content-Type: application/json; charset=UTF-8

$($uploadMetadata | ConvertTo-Json)

--boundary
Content-Transfer-Encoding: base64
Content-Type: $sourceMime

$sourceBase64
--boundary--
"@

# Set the upload headers
$uploadHeaders = @{
    "Authorization" = "Bearer $accessToken"
    "Content-Type" = 'multipart/related; boundary=boundary'
    "Content-Length" = $uploadBody.Length
}

# Perform the upload
$response = Invoke-RestMethod -Uri "https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart&supportsTeamDrives=$supportsTeamDrives" -Method Post -Headers $uploadHeaders -Body $uploadBody