# PowerShell-Administrering-Active-Directory

These scripts simplifies managing Active Directory on Windows Server 2016.

If you have questions:

-join('68656E72696A6F684070726F746F6E6D61696C2E636F6D' -split '(?<=\G.{2})',23|%{[char][int]"0x$_"})


Note to myself:
Sjekk om en AD feature er installert.
$srv=Get-WindowsFeature *ise*
$srv.Installed

Listing bios: Get-WmiObject -Class Win32_BIOS -ComputerName .
Finne ut om pc er 64 eller 32 bit: Get-WmiObject -Class Win32_ComputerSystem -ComputerName . | Select-Object -Property SystemType
Liste pc manufacturer og modell: Get-WmiObject -Class Win32_ComputerSystem
