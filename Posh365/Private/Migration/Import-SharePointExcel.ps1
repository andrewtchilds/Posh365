function Import-SharePointExcel {
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

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $WorksheetName,

        [Parameter()]
        [switch]
        $NoBatch,

        [Parameter()]
        [switch]
        $NoConfirmation
    )
    end {

        Connect-SharePointPNP -Url $SharePointURL
        $TrimmedExcelFile = [regex]::matches($ExcelFile, "[^\/]*$")[0].Value
        $ExcelURL = "Shared Documents/{0}" -f $ExcelFile
        $TempExcel = '{0}_{1}' -f $Tenant, $TrimmedExcelFile
        $TempExcelPath = Join-Path -Path $ENV:TEMP $TempExcel

        Get-PnPFile -Url $ExcelURL -Path $Env:TEMP -Filename $TempExcel -AsFile -Force

        $ExcelSplat = @{
            Path = $TempExcelPath
        }
        if ($WorksheetName) {
            $ExcelSplat.Add('WorksheetName' , $WorksheetName)
        }
        Import-Excel @ExcelSplat
    }
}

