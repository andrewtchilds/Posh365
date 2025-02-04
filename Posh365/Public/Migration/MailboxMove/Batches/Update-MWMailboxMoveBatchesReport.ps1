function Update-MWMailboxMoveBatchesReport {
    <#
    .SYNOPSIS
    Updates Batches.xlsx with most recent data

    .DESCRIPTION
    Updates Batches.xlsx with most recent data

    .PARAMETER SharePointURL
    Sharepoint url ex. https://fabrikam.sharepoint.com/sites/Contoso

    .PARAMETER ExcelFile
    Excel file found in "Shared Documents" of SharePoint site specified in SharePointURL
    ex. "Batchex.xlsx"

    .PARAMETER NewCsvFile
    Path to csv of mailboxes. Typically EXO_Mailboxes.csv when you run Get-365Info
    This would be a new Csv of existing mailboxes that you want to update with BatchNames from the current excel on the SharePoint Team Site

    .PARAMETER Tenant
    This is the tenant domain - where you are migrating to.
    Example if tenant is contoso.mail.onmicrosoft.com use: Contoso

    .EXAMPLE
    This uses batches.xlsx stored in the teams "General" folder.
    Update-MWMailboxMoveBatchesReport -SharePointURL 'https://fabrikam.sharepoint.com/sites/365migration' -ExcelFile 'General\batches.xlsx' -NewCsvFile "C:\Scripts\Batches.csv" -Tenant contoso -ReportPath C:\Scripts

    .NOTES
    General notes
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $SharePointURL,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ExcelFile,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Tenant,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $NewCsvFile,

        [Parameter(Mandatory)]
        [string]
        $ReportPath
    )
    end {
        if ($Tenant -notmatch '.mail.onmicrosoft.com') {
            $Tenant = '{0}.mail.onmicrosoft.com' -f $Tenant
        }
        New-Item -ItemType Directory -Path $ReportPath -ErrorAction SilentlyContinue
        $SharePointSplat = @{
            SharePointURL = $SharePointURL
            ExcelFile     = $ExcelFile
            Tenant        = $Tenant
        }
        $CurrentHash = @{ }
        $CurrentList = Import-SharePointExcel @SharePointSplat
        foreach ($Current in $CurrentList) {
            $CurrentHash.Add($Current.UserPrincipalName, @{
                    'Migrate'             = $Current.Migrate
                    'DeploymentPro'       = $Current.DeploymentPro
                    'Notes'               = $Current.Notes
                    'CustomTargetAddress' = $Current.CustomTargetAddress
                }
            )
        }

        $Future = Import-Csv $NewCsvFile | Select-Object @(
            'DisplayName'
            @{
                Name       = 'Migrate'
                Expression = { $CurrentHash.$($_.UserPrincipalName).Migrate }
            }
            @{
                Name       = 'DeploymentPro'
                Expression = { $CurrentHash.$($_.UserPrincipalName).DeploymentPro }
            }
            'DirSyncEnabled'
            @{
                Name       = 'CustomTargetAddress'
                Expression = { $CurrentHash.$($_.UserPrincipalName).CustomTargetAddress }
            }
            'RecipientTypeDetails'
            'ArchiveStatus'
            'OrganizationalUnit(CN)'
            'SourcePrimary'
            'SourceTenantAddress'
            'TargetTenantAddress'
            'TargetPrimary'
            'FirstName'
            'LastName'
            'UserPrincipalName'
            'OnPremisesSecurityIdentifier'
            'DistinguishedName'
            'MailboxGB'
            'ArchiveGB'
            'DeletedGB'
            'TotalGB'
            @{
                Name       = 'Notes'
                Expression = { $CurrentHash.$($_.UserPrincipalName).Notes }
            }
        )
        $ExcelSplat = @{
            Path                    = (Join-Path $ReportPath 'Batches.xlsx')
            TableStyle              = 'Medium2'
            FreezeTopRowFirstColumn = $true
            AutoSize                = $true
            BoldTopRow              = $true
            ClearSheet              = $true
            WorksheetName           = 'Batches'
            ErrorAction             = 'SilentlyContinue'
        }
        $Future | Sort-Object @(
            @{
                Expression = "DisplayName"
                Descending = $false
            }
        ) | Export-Excel @ExcelSplat
    }
}
