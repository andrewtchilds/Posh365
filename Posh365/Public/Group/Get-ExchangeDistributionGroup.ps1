function Get-ExchangeDistributionGroup {
    <#
    .SYNOPSIS
    Export Office 365 Distribution Groups & Mail-Enabled Security Groups

    .DESCRIPTION
    Export Office 365 Distribution & Mail-Enabled Security Groups

    .PARAMETER ListofGroups
    Provide a text list of specific groups to report on.  Otherwise, all groups will be reported.

    .EXAMPLE
    Get-EXOGroup | Export-Csv c:\scripts\All365GroupExport.csv -notypeinformation -encoding UTF8

    .EXAMPLE
    Get-DistributionGroup -Filter "emailaddresses -like '*contoso.com*'" -ResultSize Unlimited | Select -ExpandProperty Name | Get-EXOGroup | Export-Csv c:\scripts\365GroupExport.csv -notypeinformation -encoding UTF8

    .EXAMPLE
    Get-Content "c:\scripts\groups.txt" | Get-EXOGroup | Export-Csv c:\scripts\365GroupExport.csv -notypeinformation -encoding UTF8

    Example of groups.txt
    #####################

    Group01
    Group02
    Group03
    Accounting Team

    #####################

    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [switch] $DetailedReport,

        [Parameter(ValueFromPipeline = $true, Mandatory = $false)]
        [string[]] $ListofGroups
    )
    Begin {
        if ($DetailedReport) {
            $Selectproperties = @(
                'Name', 'DisplayName', 'Alias', 'GroupType', 'Identity', 'PrimarySmtpAddress', 'RecipientType'
                'RecipientTypeDetails', 'WindowsEmailAddress', 'ArbitrationMailbox', 'CustomAttribute1'
                'CustomAttribute10', 'CustomAttribute11', 'CustomAttribute12', 'CustomAttribute13'
                'CustomAttribute14', 'CustomAttribute15', 'CustomAttribute2', 'CustomAttribute3'
                'CustomAttribute4', 'CustomAttribute5', 'CustomAttribute6', 'CustomAttribute7'
                'CustomAttribute8', 'CustomAttribute9', 'DistinguishedName', 'ExchangeVersion'
                'ExpansionServer', 'ExternalDirectoryObjectId', 'Id', 'LegacyExchangeDN'
                'MaxReceiveSize', 'MaxSendSize', 'MemberDepartRestriction', 'MemberJoinRestriction'
                'ObjectCategory', 'ObjectState', 'OrganizationalUnit', 'OrganizationId', 'OriginatingServer'
                'SamAccountName', 'SendModerationNotifications', 'SimpleDisplayName'
                'BypassNestedModerationEnabled', 'EmailAddressPolicyEnabled', 'HiddenFromAddressListsEnabled'
                'IsDirSynced', 'IsValid', 'MigrationToUnifiedGroupInProgress', 'ModerationEnabled'
                'ReportToManagerEnabled', 'ReportToOriginatorEnabled', 'RequireSenderAuthenticationEnabled'
                'SendOofMessageToOriginatorEnabled'
            )

            $CalculatedProps = @(
                @{n = "OU" ; e = {$_.DistinguishedName -replace '^.+?,(?=(OU|CN)=)'}},
                @{n = "AcceptMessagesOnlyFrom" ; e = {($_.AcceptMessagesOnlyFrom | Where-Object {$_ -ne $null}) -join "|" }},
                @{n = "AcceptMessagesOnlyFromDLMembers" ; e = {($_.AcceptMessagesOnlyFromDLMembers | Where-Object {$_ -ne $null}) -join "|" }},
                @{n = "AcceptMessagesOnlyFromSendersOrMembers" ; e = {($_.AcceptMessagesOnlyFromSendersOrMembers | Where-Object {$_ -ne $null}) -join "|" }},
                @{n = "AddressListMembership" ; e = {($_.AddressListMembership | Where-Object {$_ -ne $null}) -join "|" }},
                @{n = "AdministrativeUnits" ; e = {($_.AdministrativeUnits | Where-Object {$_ -ne $null}) -join "|" }},
                @{n = "BypassModerationFromSendersOrMembers" ; e = {($_.BypassModerationFromSendersOrMembers | Where-Object {$_ -ne $null}) -join "|" }},
                @{n = "GrantSendOnBehalfTo" ; e = {($_.GrantSendOnBehalfTo | Where-Object {$_ -ne $null}) -join "|" }},
                @{n = "ManagedBy" ; e = {($_.ManagedBy | Where-Object {$_ -ne $null}) -join "|" }},
                @{n = "ModeratedBy" ; e = {($_.ModeratedBy | Where-Object {$_ -ne $null}) -join "|" }},
                @{n = "RejectMessagesFrom" ; e = {($_.RejectMessagesFrom | Where-Object {$_ -ne $null}) -join "|" }},
                @{n = "RejectMessagesFromDLMembers" ; e = {($_.RejectMessagesFromDLMembers | Where-Object {$_ -ne $null}) -join "|" }},
                @{n = "RejectMessagesFromSendersOrMembers" ; e = {($_.RejectMessagesFromSendersOrMembers | Where-Object {$_ -ne $null}) -join "|" }},
                @{n = "ExtensionCustomAttribute1" ; e = {($_.ExtensionCustomAttribute1 | Where-Object {$_ -ne $null}) -join "|" }},
                @{n = "ExtensionCustomAttribute2" ; e = {($_.ExtensionCustomAttribute2 | Where-Object {$_ -ne $null}) -join "|" }},
                @{n = "ExtensionCustomAttribute3" ; e = {($_.ExtensionCustomAttribute3 | Where-Object {$_ -ne $null}) -join "|" }},
                @{n = "ExtensionCustomAttribute4" ; e = {($_.ExtensionCustomAttribute4 | Where-Object {$_ -ne $null}) -join "|" }},
                @{n = "ExtensionCustomAttribute5" ; e = {($_.ExtensionCustomAttribute5 | Where-Object {$_ -ne $null}) -join "|" }},
                @{n = "MailTipTranslations" ; e = {($_.MailTipTranslations | Where-Object {$_ -ne $null}) -join "|" }},
                @{n = "ObjectClass" ; e = {($_.ObjectClass | Where-Object {$_ -ne $null}) -join "|" }},
                @{n = "PoliciesExcluded" ; e = {($_.PoliciesExcluded | Where-Object {$_ -ne $null}) -join "|" }},
                @{n = "PoliciesIncluded" ; e = {($_.PoliciesIncluded | Where-Object {$_ -ne $null}) -join "|" }},
                @{n = "EmailAddresses" ; e = {($_.EmailAddresses | Where-Object {$_ -ne $null}) -join '|' }},
                @{n = "x500" ; e = {"x500:" + $_.LegacyExchangeDN}},
                @{n = "membersName" ; e = {($MemName | Where-Object {$null -ne $_}) -join "|"}},
                @{n = "membersSMTP" ; e = {($MemSmtp | Where-Object {$null -ne $_}) -join "|"}}
            )
        }
        else {
            $Selectproperties = @(
                'Name', 'DisplayName', 'Alias', 'GroupType', 'Identity', 'PrimarySmtpAddress', 'RecipientTypeDetails', 'WindowsEmailAddress'
            )

            $CalculatedProps = @(
                @{n = "OU" ; e = {$_.DistinguishedName -replace '^.+?,(?=(OU|CN)=)'}},
                @{n = "AcceptMessagesOnlyFromSendersOrMembers" ; e = {($_.AcceptMessagesOnlyFromSendersOrMembers | Where-Object {$_ -ne $null}) -join "|" }},
                @{n = "ManagedBy" ; e = {($_.ManagedBy | Where-Object {$_ -ne $null}) -join "|" }},
                @{n = "EmailAddresses" ; e = {($_.EmailAddresses | Where-Object {$_ -ne $null}) -join '|' }},
                @{n = "x500" ; e = {"x500:" + $_.LegacyExchangeDN}},
                @{n = "membersName" ; e = {($MemName | Where-Object {$null -ne $_}) -join "|"}},
                @{n = "membersSMTP" ; e = {($MemSmtp | Where-Object {$null -ne $_}) -join "|"}}
            )
        }
    }
    Process {
        if ($ListofGroups) {
            foreach ($CurGroup in $ListofGroups) {
                $Members = Get-DistributionGroupMember -Identity $CurGroup -ResultSize Unlimited | Select-Object name, primarysmtpaddress
                $MemName = $Members | Select -expandproperty Name
                $MemSmtp = $Members | Select -expandproperty PrimarySmtpAddress
                Get-DistributionGroup -identity $CurGroup | Select-Object ($Selectproperties + $CalculatedProps)
            }
        }
        else {
            $Groups = Get-DistributionGroup -ResultSize unlimited
            foreach ($CurGroup in $Groups) {
                $Members = Get-DistributionGroupMember -Identity $CurGroup.identity -ResultSize Unlimited | Select-Object name, primarysmtpaddress
                $MemName = $Members | Select -expandproperty Name
                $MemSmtp = $Members | Select -expandproperty PrimarySmtpAddress
                $Identity = $CurGroup.identity
                Get-DistributionGroup -identity $Identity | Select-Object ($Selectproperties + $CalculatedProps)
            }
        }
    }
    End {

    }
}