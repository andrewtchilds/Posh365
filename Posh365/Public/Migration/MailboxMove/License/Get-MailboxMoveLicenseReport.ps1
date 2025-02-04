function Get-MailboxMoveLicenseReport {
    param (
        [Parameter(Mandatory)]
        [string]
        $Path
    )
    end {

        Get-CloudLicense -Path $Path
        $ColumnList = (Get-Content (Join-Path $Path 365_Licenses.csv) | ForEach-Object { $_.split(',').count } | Sort-Object -Descending)[0]
        Import-Csv -Path (Join-Path $Path 365_Licenses.csv) -Header (1..$ColumnList | ForEach-Object { "Column$_" }) |
        Export-Csv -Path (Join-Path $Path 365_LicenseReport.csv) -NoTypeInformation

        $Excel365Licenses = @{
            Path                    = (Join-Path $Path '365_LicenseReport.xlsx')
            TableStyle              = 'Medium2'
            FreezeTopRowFirstColumn = $true
            AutoSize                = $true
            BoldTopRow              = $false
            ClearSheet              = $true
            ErrorAction             = 'SilentlyContinue'
            WorksheetName           = '365_LicenseReport'
            ConditionalText         = $(
                New-ConditionalText DisplayName White Black
                New-ConditionalText UserPrincipalName White Black
                New-ConditionalText AccountSku White Black
            )
        }
        Import-Csv -Path (Join-Path $Path 365_LicenseReport.csv) | Export-Excel @Excel365Licenses
        Remove-Item -Path (Join-Path $Path 365_LicenseReport.csv)
        $ExcelPath = Join-Path $Path '365_LicenseReport.xlsx'
        Write-Host "Excel file located here: $ExcelPath"
    }
}
