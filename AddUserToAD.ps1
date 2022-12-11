<#
    Author:         n4t5ru
    Email:          hello@nasru.me
    Version:        2.0
    Created:        11/DEC/2022
    ScriptName:     AddUserToAD
    Description:    Adds user to Local AD and Azure AD using the user input details
#> 

# Import required Modules
Import-Module -Name ActiveDirectory
Import-Module -Name AzureAD

# Notice for user regarding the Usernames
Write-Host "Important Notice. Please note that Username Will be created using the values entered as follows: " -ForegroundColor Red
Write-Host "Username will be stored as {FIRSTNAME.LASTNAME} This will be used by the Staff to login." -ForegroundColor Red

Start-Sleep -s 3

# Admin inputs required for the user details
$firstname = Read-Host -Prompt "Enter First name "
$lastname = Read-Host -Prompt "Enter Last Name "
$initials = Read-Host -Prompt "Does user have Initials / Middle Name [Y or N] "

# Checks if the user has a middle name / initials
if ($initials -eq "Y"){
    $middlename = Read-Host -Prompt "Enter Middle Name "
}

# Admin inputs for the extra details of the user
$designation = Read-Host -Prompt "Enter Designation "
$department = Read-Host -Prompt "Enter Department "
$mobile = Read-Host -Prompt "Mobile Number "

# Variables that need to be merged or needs extra static parameters
$username = $firstname+'.'+$lastname
$displayname = $firstname+' '+$lastname
$emailname = $username+'@<Domain>.<TLD>' # The String should be that domain of your company 
$companyname = "<Company Name>"

#$Root = (Get-ADOrganizationalUnit -Filter {(name -like $ou)}).distinguishedName


Write-Host 'DisplayName: ' $displayname
#Function which adds the user to normal/inhouse hosted Active directory
function LocalADUserCreation {

    if ($initials -eq "Y"){
        New-ADUser -Name $username -AccountPassword (Read-Host -AsSecureString "AccountPassword") `
            -Givenname $firstname `
            -Initials $middlename `
            -Surname $lastname `
            -Title $designation `
            -EmailAddress $emailname `
            -DisplayName $displayname `
            -Department $department `
            -SamAccountName $username `
            -UserPrincipalName $username `
            -Path 'DC=SDFC DC=LAN' `
            -ChangePasswordAtLogon $true `
            -Enabled $true
    }
    else {
        New-ADUser -Name $username -AccountPassword (Read-Host -AsSecureString "AccountPassword") `
            -Givenname $firstname `
            -Surname $lastname `
            -Title $designation `
            -EmailAddress $emailname `
            -DisplayName $displayname `
            -Department $department `
            -SamAccountName $username `
            -UserPrincipalName $username `
            -Path 'DC=SDFC DC=LAN' `
            -ChangePasswordAtLogon $true `
            -Enabled $true
    }
}

#Function which adds the user to Azure AD
function AzureUserCreation{
    
    #Will automatically progress if an administrator is logged in
    $credentials = Get-Credential

    Connect-AzureAD -Credential $credentials

    $PasswordProfile = New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordProfile
    $PasswordProfile.Password = "Welcome123"
    $PasswordProfile.ForceChangePasswordNextLogin

    New-AzureADUser -DisplayName $displayname `
        -GivenName $firstname `
        -Surname $lastname `
        -JobTitle $designation `
        -Department $department `
        -Mobile $mobile `
        -CompanyName $companyname `
        -PasswordProfile $PasswordProfile `
        -UserPrincipalName $emailname `
        -AccountEnabled $true `
        -MailNickName $username

    Connect-MgGraph -Credential $credentials

    Set-AzureADUserLicense -ObjectId $emailname `
        -AssignedLicenses 'O365_BUSINESS_PREMIUM'
}

# Option to add user to Inhouse AD, AzureAD or Both
$addTo = Read-Host -Prompt "Add User to [I] - InhouseAD [A] - AzureAD [B] - Both: "

if ($addTo -eq 'I'){
    LocalADUserCreation
}
if ($addTo -eq 'A'){
    AzureUserCreation
}
if ($addTo -eq 'B') {
    LocalADUserCreation
    AzureUserCreation
}