function Select-Options {
    param ()
    Select-ADConnectServer
    Select-DomainController
    Select-ExchangeServer
    Select-TargetAddressSuffix
    Select-DisplayNameFormat
    Select-SamAccountNameCharacters
    Select-SamAccountNameOrder
    Select-SamAccountNameNumberOfFirstNameCharacters
    Select-SamAccountNameNumberOfLastNameCharacters
    Select-TargetAddressSuffix
}
    