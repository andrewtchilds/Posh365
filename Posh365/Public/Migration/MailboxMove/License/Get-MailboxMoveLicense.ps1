function Get-MailboxMoveLicense {
    <#
    .SYNOPSIS
    Reports on a user or users Office 365 enabled licenses
    Either CSV or Excel file from SharePoint can be used
    Out-GridView is used for each user.
    Helpful for a maximum of 10-20 users as each user opens in their own window

    .DESCRIPTION
    Reports on a user or users Office 365 enabled licenses
    Either CSV or Excel file from SharePoint can be used
    Out-GridView is used for each user.
    Helpful for a maximum of 10-20 users as each user opens in their own window

    .PARAMETER SharePointURL
    Sharepoint url ex. https://fabrikam.sharepoint.com/sites/Contoso

    .PARAMETER ExcelFile
    Excel file found in "Shared Documents" of SharePoint site specified in SharePointURL
    ex. "Batchex.xlsx"
    Minimum headers required are: BatchName, UserPrincipalName

    .PARAMETER MailboxCSV
    Path to csv of mailboxes. Minimum headers required are: BatchName, UserPrincipalName

    .PARAMETER Tenant
    This is the tenant domain - where you are migrating to.
    Example if tenant is contoso.mail.onmicrosoft.com use contoso

    .EXAMPLE
    Get-MailboxMoveLicense -Tenant Contoso -MailboxCSV c:\scripts\batches.csv

    .EXAMPLE
    Get-MailboxMoveLicense -SharePointURL 'https://fabrikam.sharepoint.com/sites/Contoso' -ExcelFile 'Batches.xlsx' -Tenant Contoso

    .NOTES
    General notes
    #>

    [CmdletBinding(DefaultParameterSetName = 'SharePoint')]
    param (
        [Parameter(Mandatory, ParameterSetName = 'SharePoint')]
        [ValidateNotNullOrEmpty()]
        [string]
        $SharePointURL,

        [Parameter(Mandatory, ParameterSetName = 'SharePoint')]
        [ValidateNotNullOrEmpty()]
        [string]
        $ExcelFile,

        [Parameter(Mandatory, ParameterSetName = 'SharePoint')]
        [ValidateNotNullOrEmpty()]
        [string]
        $Tenant,

        [Parameter(Mandatory, ParameterSetName = 'CSV')]
        [ValidateNotNullOrEmpty()]
        [string]
        $MailboxCSV
    )
    end {
        if ($Tenant -notmatch '.mail.onmicrosoft.com') {
            $Tenant = '{0}.mail.onmicrosoft.com' -f $Tenant
        }
        switch ($PSCmdlet.ParameterSetName) {
            'SharePoint' {
                $SharePointSplat = @{
                    SharePointURL = $SharePointURL
                    ExcelFile     = $ExcelFile
                    Tenant        = $Tenant
                    NoBatch       = $true
                }
                $UserChoice = Import-SharePointExcelDecision @SharePointSplat
            }
            'CSV' {
                $CSVSplat = @{
                    MailboxCSV = $MailboxCSV
                    NoBatch    = $true
                }
                $UserChoice = Import-MailboxCsvDecision @CSVSplat
            }
        }
        if ($UserChoice -ne 'Quit' ) {
            ($UserChoice).UserPrincipalName | Set-CloudLicense -ReportUserLicensesEnabled
        }
    }
}
