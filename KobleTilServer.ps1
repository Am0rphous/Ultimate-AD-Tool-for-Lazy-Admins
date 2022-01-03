
<#
Tips til feilsøking:
    1. Sjekk at tjeneste kjører        : Get-Service winrm
    2. Hvis den ikke kjører            : (Get-Service winrm).Start()
    3. Gjør at den startes automatisk  : Set-Service winrm -Startuptype "Automatic"
    4. Kjør                            : winrm quickconfig
    5. Sjekk at server er i TrustedHost.

Viktig å sjekke at dette scriptet (KobleTilServer.ps1) ligger i samme mappe som scriptet det skal sende: 'Administering-ActiveDirectory.ps1'

#>

 
function KobleTil {
  
    #Endrer variablene nedenfor slik at de passer til der jeg har lagret script.
    #Jeg bruker dropbox slik at jeg får tilgang til scriptene på ulike maskiner
    CD C:\Users\henrik\Dropbox
    $PathPassord             = "C:\Users\User\Dropbox\KryptertPassordServer.txt" #Serverpassord, endres av bruker
    $PathActiveDirectoryMeny = "C:\Users\User\Dropbox\Administrering-ActiveDirectory.ps1"

    function FeilMelding {
        # `n gjør at det blir mellomrom til linja over.
        # `t gjør at det hoppes inn en tabulator-lengde fra venstre i terminal.
        # $_ viser feilmelding
        # Fore er forkortelse for ForegroundColor
        Write-Host "`n`t$_" -Fore Red
    }

    CLS #Fjerner tidligere kode for å presentere introen til menyen på en pen måte. 'CLS' er alias for 'Clear-Host'

    [string] $appNavn = "`n=========== Active Directory - Administrering - Version 1.0 ===========`n" #Meny-header
    Write-Host "$appNavn" -Fore Magenta #Skriver ut meny-header

    Write-Host "`n`tØnsker du å koble til en Remote server? ¯\_(ツ)_/¯`n`n" -Fore Yellow
#   [string]$svar = Read-Host -Prompt "`tJ (ja) eller N (nei)"
    $svar = "j" #For å slippe å skrive inn hver gang settes det en fast variabel.

    if ($svar -eq "j" -or $svar -eq "ja") {
        Do {
            Write-Host "`n================ Remote IP ================"               -Fore Magenta
           # [string]$RemoteIPadresse = Read-Host -Prompt "`n`tServernavn/IP" #Server som skal kobles til

           #For å slippe å skrive inn IP-adressen hver gang
             $RemoteIPadresse = "192.168.0.119"
           # $RemoteIPadresse = "192.168.0.129"
           # $RemoteIPadresse = "10.20.208.156"    #brukernavn: admin
           # $RemoteIPadresse = "192.168.0.111"    #brukernavn: client


                if ($RemoteIPadresse -eq "") {Write-Host "`nSkriv inn en IP-adresse" -Fore Red}
        } while($RemoteIPadresse -eq "") #Gjenta koden så lenge IP-adressen er tom
        
        Do {
           # $brukernavn = Read-Host -Prompt "`n`tDomene\Brukernavn" #Så spesifiseres domene\brukernavn
            
            #For å slippe å skrive inn brukernavn hver gang
            # $brukernavn = "administrator" 
            # $brukernavn = "underdomene1\administrator"
             $brukernavn = "fire\administrator"
            # $brukernavn = "klient"

                if ($brukernavn -eq "") {
                    Write-Host "`nSkriv inn brukernavn`n" -Fore Red 
                }
        } while ($brukernavn -eq "")

        #Sjekker om passord ligger lagret
        try {
            #Følgende kilde har blitt brukt som referanse i utarbeiding av kode nedenfor:
            # https://www.pdq.com/blog/secure-password-with-powershell-encrypting-credentials-part-1/

            $PassordEksisterer = Test-Path $PathPassord
                if ($PassordEksisterer -eq $false) {
                    Read-Host "Skriv inn passord til server $RemoteIPadresse" -AsSecureString |  ConvertFrom-SecureString | Out-File $PathPassord
                    
                    $pass = Get-Content $PathPassord | ConvertTo-SecureString
                    
                    $File = $PathPassord
                    
                    $MyCredential = New-Object -TypeName System.Management.Automation.PSCredential `
                        -ArgumentList $brukernavn, (Get-Content $File | ConvertTo-SecureString)
                }
                else {
                    $File = $PathPassord
                    $MyCredential=New-Object -TypeName System.Management.Automation.PSCredential `
                        -ArgumentList $brukernavn, (Get-Content $File | ConvertTo-SecureString)
                }
        } Catch { FeilMelding }

        $TrustedHosts = Get-WSManInstance -ResourceURI winrm/config/client | select -ExpandProperty TrustedHosts

            if ( $TrustedHosts -notcontains $RemoteIPadresse) { #Hvis TrustedHosts ikke inneholder IP'en må den legges til
                Set-Item WSMan:\localhost\Client\TrustedHosts $RemoteIPadresse -Force #Den remote IP'en legges til i TrustedHosts
                Write-Host "`nOppdaterte Trusted Hosts med IP $RemoteIPadresse`n" -Fore Green #Gir tiltbakemelding til bruker
                Restart-Service WinRM -Verbose #Restart WinRM tjenesten slik at endringer i TrustedHosts blir tatt i bruk.
            }
                                                      #Utfører sjekk om PSRemoting er enablet
        Try {                                         #Localhost blir alltid ansett som en 'TrustedHost'
            Enter-PSSession -ComputerName 127.0.0.1   #-ErrorAction SilentlyContinue   #Prøver å åpne sesjon mot lokal PC
            if ($?) { Exit-PSSession }                #Dersom det går er PS-remoting aktivert, og man avslutter sesjonen
            else { Enable-PSRemoting -Force }         #Hvis ikke PS-remoting er aktivert aktiveres den
        } Catch { FeilMelding }                       #Hvis noe går galt

        Write-Host "`nKobler til server $RemoteIPadresse og laster inn script`n" -Fore Green

        #Kommando som sender hele scriptet til IP'en som er spesifisert
        Try { Invoke-Command -FilePath $PathActiveDirectoryMeny -ComputerName $RemoteIPadresse -Credential $MyCredential }
        Catch { FeilMelding}

    }#Slut if $svar -eq "j"

    else { #Dersom bruker ikke ønsker å koble til en Remote server
        Write-Host "`n __________________ "
        Write-Host "< srsly admin, why? >"
        Write-Host " ------------------"
        Write-Host "        \   ^__^"
        Write-Host "         \  (oo)\_______"
        Write-Host "            (__)\       )\/\"
        Write-Host "                ||----w |"
        Write-Host "________________" -Fore Green -NoNewline
        Write-Host "||" -NoNewline
        Write-Host "_____" -Fore Green -NoNewline
        Write-Host "||" -NoNewline
        Write-Host "__`n" -Fore Green
        }

} #/Slutt KobleTil

KobleTil # Kjører funksjonen
