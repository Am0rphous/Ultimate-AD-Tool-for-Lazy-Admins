# PowerShell-Administrering-Active-Directory

These scripts simplifies managing Active Directory on Windows Server 2016.

Note to myself:
- Sjekk om en AD feature er installert.
- $srv=Get-WindowsFeature *ise*
- $srv.Installed
- Listing bios: Get-WmiObject -Class Win32_BIOS -ComputerName .
- Finne ut om pc er 64 eller 32 bit: Get-WmiObject -Class Win32_ComputerSystem -ComputerName . | Select-Object -Property SystemType
- Liste pc manufacturer og modell: Get-WmiObject -Class Win32_ComputerSystem
- feil i script når man velger å gå tilbake (option 18) i Bruker-menyen
- Sjekk om Windows maskin krever restart, dersom restart, gå til meny 2/domene-administrasjon og velg restart.
- Ny meny-alternativ: Generelt / sikkerhet
  - Sjekk om automatiske oppdateringer er satt til "automatisk". Gi mulighet for å sette til automatisk.
