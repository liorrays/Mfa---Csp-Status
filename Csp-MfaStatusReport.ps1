if (Get-Module -ListAvailable -Name MSOnline) {
    Write-Host "MSOnline Already Installed" -BackgroundColor Black -ForegroundColor White
} #check if msonline installed , if not install
else {
    try {
        Install-Module -Name MSOnline -AllowClobber -Confirm:$False -Force  
    }
    catch [Exception] {
        $_.message 
        exit
    }
}


Write-Host "Please Connect With Your Csp Provider Account" -BackgroundColor Black -ForegroundColor White

Start-Sleep -Seconds 2

Connect-MsolService

Write-Host "Finding Azure Active Directory Accounts..." -BackgroundColor Black -ForegroundColor Yellow

$tenant = Get-MsolPartnerContract |Select TenantId , name

foreach($i in $tenant){

$Users = Get-MsolUser -All -TenantId $i.TenantId |Where {$_.UserType -ne "Guest" }

$CsvReport = [System.Collections.Generic.List[Object]]::new() 

Write-Host "$($Users.Count) Users Has Found At Company $($i.name)" -BackgroundColor Black -ForegroundColor Magenta

ForEach ($User in $Users) {
Write-Host "Working On ---> $($User.UserPrincipalName)" -BackgroundColor Black -ForegroundColor Green


    $MFAEnforced = $User.StrongAuthenticationRequirements.State
    $MFAPhone = $User.StrongAuthenticationUserDetails.PhoneNumber
    $DefaultMFAMethod = ($User.StrongAuthenticationMethods | ? { $_.IsDefault -eq "True" }).MethodType
    If (($MFAEnforced -eq "Enforced") -or ($MFAEnforced -eq "Enabled")) {
        Switch ($DefaultMFAMethod) {
            "OneWaySMS" { $MethodUsed = "SMS" }
            "TwoWayVoiceMobile" { $MethodUsed = "Phone Call Verification" }
            "PhoneAppOTP" { $MethodUsed = "Hardware Token Or Authenticator App" }
            "PhoneAppNotification" { $MethodUsed = "Authenticator App" }
        }
    }
    Else {
        $MFAEnforced = "Not Enabled"
        $MethodUsed = "MFA Is Not In Used" 
    }
  
    $ReportLine = [PSCustomObject] @{

        Company     = $i.Name
        User        = $User.UserPrincipalName
        Name        = $User.DisplayName
        MFAUsed     = $MFAEnforced
        MFAMethod   = $MethodUsed 
        PhoneNumber = $MFAPhone
        Disabled_User = $User.BlockCredential
    }
                 
    $CsvReport.Add($ReportLine) 
}

$CsvReport | Export-CSV -Path "$env:USERPROFILE\desktop\MfaStatusCSP.csv" -NoTypeInformation -Encoding UTF8 -Append
}

