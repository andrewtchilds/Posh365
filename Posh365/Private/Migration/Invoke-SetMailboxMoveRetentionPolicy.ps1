function Invoke-SetMailboxMoveRetentionPolicy {
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
                }
                $UserChoice = Import-SharePointExcelDecision @SharePointSplat | Where-Object { $_.RetentionPolicy }
            }
            'CSV' {
                $CSVSplat = @{
                    MailboxCSV = $MailboxCSV
                }
                $UserChoice = Import-MailboxCsvDecision @CSVSplat | Where-Object { $_.RetentionPolicy }
            }
        }
        if ($UserChoice -ne 'Quit' ) {
            foreach ($User in $UserChoice) {
                $SetSplat = @{
                    warningaction   = 'silentlycontinue'
                    ErrorAction     = 'Stop'
                    Identity        = $User.UserPrincipalName
                    RetentionPolicy = $User.RetentionPolicy
                }
                try {
                    Set-Mailbox @SetSplat
                    [PSCustomObject]@{
                        DisplayName     = $User.DisplayName
                        Result          = 'SUCCESS'
                        Identity        = $User.UserPrincipalName
                        RetentionPolicy = $User.RetentionPolicy
                        Log             = 'SUCCESS'
                        Action          = 'SET'
                    }
                }
                catch {
                    [PSCustomObject]@{
                        DisplayName     = $User.DisplayName
                        Result          = 'FAILED'
                        Identity        = $User.UserPrincipalName
                        RetentionPolicy = $User.RetentionPolicy
                        Log             = $_.Exception.Message
                        Action          = 'SET'
                    }
                }
            }
        }
    }
}
