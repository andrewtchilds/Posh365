function Invoke-GetMWMailboxMovePasses {
    [CmdletBinding()]
    Param
    (
        [Parameter(ValueFromPipeline)]
        $MailboxList
    )
    process {
        foreach ($Mailbox in $MailboxList) {
            Get-MW_MailboxMigration -MailboxId $Mailbox.Id | Select-Object @(
                @{
                    Name       = 'Source'
                    Expression = { $Mailbox.Source }
                }
                @{
                    Name       = 'Target'
                    Expression = { $Mailbox.Target }
                }
                'Type'
                'Status'
                @{
                    Name       = 'FolderFilter'
                    Expression = { $Mailbox.FolderFilter }
                }
                'ItemTypes'
                'StartDate'
                'CompleteDate'
                'FailureMessage'
            )
        }
    }
}
