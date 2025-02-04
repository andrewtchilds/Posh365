function Update-MailboxMoveBatchesReport {
    <#
    .SYNOPSIS
    Updates Batches.xlsx by pulling batch names from existing and pairing it with a new batches.csv
    Creates a new Batches.xlsx

    .DESCRIPTION
    Updates Batches.xlsx by pulling batch names from existing and pairing it with a new batches.csv
    Creates a new Batches.xlsx

    .PARAMETER SharePointURL
    Sharepoint url ex. https://fabrikam.sharepoint.com/sites/Contoso

    .PARAMETER ExcelFile
    Excel file found in "Shared Documents" of SharePoint site specified in SharePointURL
    ex. "Batchex.xlsx"
    Minimum headers required are: BatchName, UserPrincipalName

    .PARAMETER NewCsvFile
    Path to csv of mailboxes. Minimum headers required are: BatchName, UserPrincipalName
    This would be a new Csv of existing mailboxes that you want to update with BatchNames from the current excel on the SharePoint Team Site

    .PARAMETER Tenant
    This is the tenant domain - where you are migrating to.
    Example if tenant is contoso.mail.onmicrosoft.com use: Contoso

    .EXAMPLE
    Update-MailboxMoveBatchesReport -SharePointURL https://fabrikam.sharepoint.com/sites/Contoso -ExcelFile batches.xlsx -Tenant Contoso -NewCsvFile C:\Scripts\Batches.csv -ReportPath C:\Scripts\

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
        # Look at removing the where.{...}... I could just create the hashtable with everything as needs might change (diff parameters)
        $CurrentList = (Import-SharePointExcel @SharePointSplat).where{ $_.BatchName -or $_.IsMigrated -or $_.CompleteBatchDate -or $_.CompleteBatchTimePT }
        foreach ($Current in $CurrentList) {
            $CurrentHash.Add($Current.UserPrincipalName, @{
                    'BatchName'           = $Current.BatchName
                    'IsMigrated'          = $Current.IsMigrated
                    'CompleteBatchDate'   = $Current.CompleteBatchDate
                    'CompleteBatchTimePT' = $Current.CompleteBatchTimePT
                }
            )
        }
        # $SelectProps = ($FutureList[0].psobject.properties.name).where{ $_ -notmatch 'BatchName|IsMigrated|CompleteBatchDate|CompleteBatchTimePT' }
        $Future = Import-Csv $NewCsvFile | Select-Object @(
            @{
                Name       = 'BatchName'
                Expression = { $CurrentHash.$($_.UserPrincipalName).BatchName }
            }
            'DisplayName'
            'OrganizationalUnit'
            @{
                Name       = 'IsMigrated'
                Expression = { $CurrentHash.$($_.UserPrincipalName).IsMigrated }
            }
            @{
                Name       = 'CompleteBatchDate'
                Expression = { $CurrentHash.$($_.UserPrincipalName).CompleteBatchDate }
            }
            @{
                Name       = 'CompleteBatchTimePT'
                Expression = { $CurrentHash.$($_.UserPrincipalName).CompleteBatchTimePT }
            }
            'MailboxGB'
            'ArchiveGB'
            'DeletedGB'
            'TotalGB'
            'LastLogonTime'
            'ItemCount'
            'UserPrincipalName'
            'PrimarySmtpAddress'
            'AddressBookPolicy'
            'RetentionPolicy'
            'AccountDisabled'
            'Alias'
            'Database'
            'OU'
            'Office'
            'RecipientTypeDetails'
            'UMEnabled'
            'ForwardingAddress'
            'ForwardingRecipientType'
            'ForwardingSmtpAddress'
            'DeliverToMailboxAndForward'
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
                Expression = "BatchName"
                Descending = $true
            }
            @{
                Expression = "DisplayName"
                Descending = $false
            }
        ) | Export-Excel @ExcelSplat
    }
}
