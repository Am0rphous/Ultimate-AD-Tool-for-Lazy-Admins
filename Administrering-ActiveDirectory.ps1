<######################################################################
Meny

v1.0    15. Februar 2017:    Scriptets menyoppbygging lages ved hjelp av Paul Westlake's "Multi Layered Menu Demonstration"
Kilde: https://quickclix.wordpress.com/2012/08/14/making-powershell-menus/ 

Scriptet forutsetter at stien i PowerShell er i samme mappe som scriptet ligger i.
Det vil si hvis scriptet ligger i mappa C:\Brukere\Admin\
og stien i PowerShell er satt til C:\pwsh\ vil man må feilmelding underveis.


Tips til funksjonalitet:
https://blogs.technet.microsoft.com/heyscriptingguy/2013/01/03/use-powershell-to-deploy-a-new-active-directory-forest/


Les om ad
https://msdn.microsoft.com/en-us/library/bb742424.aspx




Menyen er  bygd opp slik:

    [int] $menyAlternativ = 0

    while ( $menyAlternativ -lt 1 -or $menyAlternativ -gt 4 ){

        Write-host "1. alternativ 1"
        Write-host "2. alternativ 2"
        Write-host "3. alternativ 3"
        Write-host "4. alternativ 4"

    [Int]$menyAlternativ = read-host "Please enter an option 1 to 4..." }
    
    Switch ( $menyAlternativ ){

    #  1 { kode }
    #  2 { kode }
    #  3 { kode }

    #default { kode }

    #} #Slutt switch-setning
    #Kilde https://quickclix.wordpress.com/2012/08/14/making-powershell-menus/


######################################################################>

 function LastInnMeny {


    Import-Module ActiveDirectory -ErrorAction SilentlyContinue #Importerer modulen slik at funksjoner kan brukes lenger ned i scriptet
    Import-Module ADDSDeployment  -ErrorAction SilentlyContinue #Gir tilgang til en rekke kommandoer i henhold til installering av domnekontroller
    Import-Module ServerManager   -ErrorAction SilentlyContinue #Gir funksjonalitet slik at blant annet 'Add-WindowsFeature' cmdlet'ene kan brukes
    Import-Module GroupPolicy     -ErrorAction SilentlyContinue #Gir cmd'letes for gpo administrasjon
    #Ved å bruke '-ErrorAction SilentlyContinue' for man ikke error når man kjører scriptet på en Windows 10 klient.

    [string] $appNavn                = "`n=========== Active Directory - Administrering - Version 1.0 ===========`n" #Meny-header
	[int]    $AntallMenyAlternativer = 15 #Antall Meny Alternativer i hovedmenyen.
    [string] $feilmelding            = "`n`tVennligst velg et av alternativene som er tilgjengelige.`n" #Feilmelding som vises når bruker skriver noe som er annerledes enn tallet alternativene er representert som
    [int]    $VentSekunder           = 2 #Verdi som endrer antall sekunder (i hele script) en bruker ser en feilmelding.

    [int]    $Hovedmeny              = 0 #Hovedmeny   - Deklarerer variabel som int slik at det bare aksepteres runde tall fra bruker.
	[int]    $MenyVisAD              = 0 #Undermeny 1 - Vis/installer AD-tjenester
    [int]    $MenyPromDomene         = 0 #Undermeny 2 - Promotering av server til domenekontroller
    [int]    $MenyNavigeriAD         = 0 #Undermeny 3 - Naviger fritt i AD
    [int]    $MenyBruker             = 0 #Undermeny 4 - Bruker-administrasjon
    [int]    $MenyGrupper            = 0 #Undermeny 5 - Gruppe-dministrasjon
    [int]    $MenyGPO                = 0 #Undermeny 6 - GPO-administrasjon
    [int]    $MenyOU                 = 0 #Undermeny 7 - OU-administrasjon
    [int]    $MenyDomeneStruktur     = 0 #Undermeny 8 - Vis DomeneKontrollerStruktur
    [int]    $MenyBackup             = 0 #Undermeny 9 - Backup
    [int]    $MenyTestmiljo          = 0 #Undermeny 10 - Opprett ulike testmiljø på server
    [int]    $MenyRapport            = 0 #Undermeny 11 - Eksporter AD statistikk til rapport
    [int]    $MenyLogger             = 0 #Undermeny 13 - Logger

    # Melding ved installering av en tjeneste
    [string] $ErInstallert             = "`n`tTjenesten er allerede installert"
    [string] $Suksessfull_installering = "`n`tTjenesten ble suksessfullt installert"

    # Melding ved avinstallering av en tjeneste
    [string] $Suksessfull_AVinstallering = "`n`tTjenesten ble suksessfullt avinstallert"
	[string] $Allerede_Avinstallert      = "`n`tTjenesten er allerede avinstallert"

    [string]  $OperativSystem = (Get-WmiObject -class Win32_OperatingSystem).Caption
    [string]  $Hostname       = Hostname

    #Koden under for ordning av IP er hentet fra følgende kilde:
    #https://social.technet.microsoft.com/Forums/scriptcenter/en-US/11782ccd-67e5-4df9-864c-0ab54f13a66c/powershell-getting-ip-v4-address-on-a-multihomed-system?forum=ITCG
              $ip             = Get-WmiObject win32_networkadapterconfiguration -Filter "ipenabled=true"
    [string]  $ip             = $ip.ipaddress[0]

    #Henter navn på domene og legger det i en variabel
    [string] $script:domene = (Get-WmiObject win32_computersystem).Domain
       [int]      $AntallOU = (Get-ADOrganizationalUnit -Filter *).count
    
    #Teller antall domenekontrollere
    $AntallDomeneKontrollere = (Get-ADGroupMember 'Domain Controllers').Count

    #Følgende kode lager et sjekkpunkts-ikon
    #Kilde: http://community.idera.com/powershell/powertips/b/tips/posts/using-green-checkmarks-in-console-output
    $SjekkPunkt = @{
        Object = [Char]8730
        ForegroundColor = "Green"
    }
                            #Koden under er hentet fra https://gallery.technet.microsoft.com/scriptcenter/Organizational-Units-7b3ff0bc
    $AntallOU_Ubeskyttet = (Get-ADOrganizationalUnit -Filter * -Properties ProtectedFromAccidentalDeletion |
                            Where {$_.ProtectedFromAccidentalDeletion -eq $false}).count

#####################################################################################
#################### Funksjoner som brukes flere steder i script ####################
####################   legges her slik at de kan aksesseres og   ####################
####################       endres lenger ned i barnescopene      ####################

    function FeilMelding {
        # `n gjør at det blir mellomrom til linja over.
        # `t gjør at det hoppes inn en tabulator-lengde fra venstre i terminal.
        # $_ viser feilmelding
        # Fore er forkortelse for ForegroundColor
        Write-Host "`n`t$_" -Fore Red
    }

    function BleDetSuksess? {
        if ($?) {Write-Host "`n`tKommandoen ble utført suksessfullt" -Fore Green}
    }

    function SkrivNavn { #Funksjon der bruker MÅ skrive inn noe
        do {
            [string] $script:navn = Read-Host "`n`tNavn"
                 if ($script:navn -eq "") { Write-Host "`n`tFeltet kan ikke være tomt" -Fore Red }
        } while ($script:navn -eq "")
    }

    function skriv_gyldig_path_til_fil {
        do { #Skriv inn gyldig path til fil
            $script:path = ""
                Write-Host "`nSkriv inn stien der fila ligger. F.eks. 'c:\mappe\fil'`n" -Fore Cyan
                $script:path = Read-Host "`tSti"
                    if ($script:path -eq "") {
                        Write-Host "`n`tStien kan ikke være tom. Prøv på nytt!" -Fore Red
                        $EksistererPath = "false"
                    }
                    else {
                        $EksistererPath = Test-Path $script:path    
                    }
        } while ($EksistererPath -ne "true") #Utfør så lenge pathen ikke er gyldig

    }

    function HvorSkalFilaLagres? {
        
        Function OpprettFil {
            NI -Path "$Default" -type File -Force | Out-Null 
                if ($?) { #Dersom forrige kommando gikk suksessfullt:
                    Write-Host "`n`tFila '$Default' ble opprettet suksessfullt" -Fore Green
                    $script:EksistererPath = $true #Variabelen settes til True, slik at funksjonen avsluttes
                }
        }

        #Funksjon som tester sti, men også oppretter en fil.
        [string] $script:Default = "C:\ActiveDirectory.txt"
            do { #Skriv inn gyldig path der fila ønsker å bli lagret
                $script:path = ""
                Write-Host "`nSkriv inn stien og navn på fila der den skal lagres:`n" -ForegroundColor Cyan
                Write-Host "`tF.eks: " -NoNewline -Fore Cyan
                Write-Host "c:\mappe\fil.txt"
                Write-Host "`tDefault: " -NoNewline -Fore Cyan
                Write-Host "$Default`n"

                    $script:path = Read-Host "Sti" #Leser hva brukeren skriver inn
                        if ($script:path -eq "") { #Hvis variabelen er blank settes stien til default
                            Write-Host "`n`tFilsti settes til $Default" -Fore Yellow
                                if ((Test-Path $script:Default) -eq $true) {
                                    Write-Host "`nFant en fil med samme navn, skal fila overskrives?" -Fore Yellow
                                     ErDuHeltSikker?
                                        if ($script:valg -eq "j") { OpprettFil }
                                        else { 
                                            Read-Host "`nAvbryter operasjon. Trykk 'enter' for å gå til hovedmeny"
                                            LastInnMeny
                                        }
                                } else { OpprettFil }
                        } else {
                            try {
                                if ((Test-Path $script:path) -eq $true) {
                                    Write-Host "`nFant en fil med samme navn, skal fila overskrives?" -Fore Yellow
                                     ErDuHeltSikker?
                                        if ($valg -eq "j") { $Default = $script:path; OpprettFil }
                                        else {
                                            Read-Host "`nAvbryter operasjon. Trykk 'enter' for å gå til hovedmeny"
                                            LastInnMeny
                                        }
                                            
                                } else { $Default = $script:path; OpprettFil }
                            } catch { FeilMelding }
                        }
            } while ($EksistererPath -ne $true) #Utfør så lenge pathen til loggene ikke er gyldig
    }

    function Skriv-Gyldig-Path-i-AD {
        do {
            Write-Host "`tEksempel: " -NoNewline -Fore Cyan
            Write-Host "DC=domeneNavn,DC=com"

            $FinnesAD = Test-Path ad:
                if ($FinnesAD -eq $false) {
                    Write-Host "`n`tStien til Active Directory er ikke tilgjengelig"            -Fore Red
                    Write-Host "`tFullføring av kommandoen vil ikke kunne utføres suksessfullt" -Fore Red
                }

            [string]$script:path = Read-Host "`nSti (Kan være blankt)"
                if ($script:path -eq "") {
                    $script:EksistererPath = $true
                }
                else {
                    $script:path = "ad:$script:path"
                    $script:EksistererPath = Test-Path $script:path
                        if ($script:EksistererPath -eq $false) {
                            Write-Host "`n`tStien du valgte er ugyldig`n" -Fore Red
                        }
                }
        } while ($script:EksistererPath -ne $true) #Utføres så lenge pathen ikke er gyldig

        $script:path = $script:path -replace "ad:" #Fjerner 'ad:' slik at det som står igjene er en brukbar sti.

    }

    function ErDuHeltSikker? {
        do { #Bruker script slik at andre funksjoner som er i dypere scope, har mulighet til å endre
             #variabelen i scope lenger opp.
            [string]$script:valg = Read-Host "`tJ/N"
                if ($script:valg -eq "" -or 
                    $script:valg -ne "j" -and 
                    $script:valg -ne "n"
                ) { Write-Host "`n`tVennligst velg 'J' for ja eller 'N' for nei`n" -Fore Red }
        }
         while ($script:valg -ne "j" -and $script:valg -ne "n")
    }

    ############## Gruppe ##############

    function SkrivGruppeNavn {
        do {
            $script:gruppeNavn = Read-Host "`n`tGruppenavn"
                if ($script:gruppeNavn -eq "") {Write-Host "`n`tFeltet kan ikke være tomt" -Fore Red}
        } while ($script:gruppeNavn -eq "")
    }
        
    function FinnGruppe { 
        $script:GruppeFinnes = Get-ADGroup -Filter "Name -eq '$gruppeNavn'"
    }
    
    function FinnDistinguishedNameGruppe {
        $script:DistinguishedName = Get-ADGroup -Filter "name -like '$gruppeNavn'" | Select -Property DistinguishedName

        #Formaterer slik at den kan brukes som path
        $script:DistinguishedName = $script:DistinguishedName -replace "@{distinguishedname=" -replace "}"
    
    }

    ######## Organizational Unit ########

    function SkrivNavnOU { #Funksjon der bruker MÅ skrive inn noe
                do {
                    $script:navnOU = Read-Host "`nNavn Organizational Unit"
                        if ($script:navnOU -eq "") {Write-Host "`n`tFeltet kan ikke være tomt" -Fore Red}
                } while ($script:navnOU -eq "")
            } 

    function FinnOrganizationalUnit {
        $script:OU = Get-ADOrganizationalUnit -Filter "name -like '$script:navnOU'" | 
                     Select -Property Name,DistinguishedName
    }

    function FinnDistinguishedNameOU {
        #Finner alle OU'er med navn 'navn' og velger egenskapen 'DistinguishedName'
        $script:DistinguishedName = Get-ADOrganizationalUnit -Filter "name -like '$script:navnOU'" | 
        Select -Property DistinguishedName

        #Formaterer GUID'en slik at den kan brukes
        $script:DistinguishedName = $script:DistinguishedName -replace "@{distinguishedname=" -replace "}"
    }

    ################ GPO ################

    function HentDefaultPassordPolicy {
        try {
            Write-Host "`nStandard passord policy er følgende:" -Fore Cyan
            Get-ADDefaultDomainPasswordPolicy |
            Select-Object -ExcludeProperty PSComputerName,RunspaceId,objectGuid
        } catch { FeilMelding }
    }

    ############### Domene ###############

    Function HentDomeneEgenskap ($egenskap) {
        #Henter egenskap om domene
        Get-ADDomain | Select -ExpandProperty $egenskap
    }

#####################################################################################
#####################################################################################

    while ( $Hovedmeny -lt 1 -or $Hovedmeny -gt $AntallMenyAlternativer ) { #Så lenge tallet som skrives inn er under null eller over 13, repeteres kommandoen som viser start menyen.
		Clear-Host #For at brukergrensesnittet skal være pent fjernes tidligere utførte kommandoer
        #Menyen som vises først:
		Write-Host " $appNavn "                                               -Fore Magenta
        Write-Host "Server: "                                      -NoNewline -Fore Cyan
        Write-Host "$ip"                                           -NoNewline
        Write-Host " - "                                           -NoNewline -Fore Cyan
        Write-Host $Hostname -NoNewline
        Write-Host " - "                                           -NoNewline -Fore Cyan
        Write-Host "$OperativSystem`n"
        Write-Host "Domene: " -NoNewline -Fore Cyan
        Write-Host "$domene"

        Write-Host "`nDu står i: "                                   -NoNewline -Fore Cyan
        Write-Host "Hovedmeny`n"
        Write-Host "`t`tVennligst velg et av alternativene nedenfor`n"          -Fore Cyan
        Write-Host "`t`t`t1.  Vis / installer / avinstaller AD-tjenester`n"     -Fore Cyan
        Write-Host "`t`t`t2.  Domene-administrasjon`n"                          -Fore Cyan
		Write-Host "`t`t`t3.  Naviger fritt i AD`n"                             -Fore Cyan
		Write-Host "`t`t`t4.  Bruker-administrering`n"                          -Fore Cyan
        Write-Host "`t`t`t5.  Gruppe-administrasjon`n"                          -Fore Cyan
        Write-Host "`t`t`t6.  GPO-administrasjon`n"                             -Fore Cyan
        Write-Host "`t`t`t7.  OU-administrasjon`n"                              -Fore Cyan
        Write-Host "`t`t`t8.  Vis DomeneKontrollerStruktur`n"                   -Fore Cyan
        Write-Host "`t`t`t9.  Backup`n"                                         -Fore Cyan
        Write-Host "`t`t`t10. Opprett ulike testmiljø på server`n"              -Fore Cyan
        Write-Host "`t`t`t11. Eksporter AD statistikk til rapport`n"            -Fore Cyan
        Write-Host "`t`t`t12. Server info`n"                                    -Fore Cyan
        Write-Host "`t`t`t13. Logger`n"                                         -Fore Cyan
        Write-Host "`t`t`t14. Om`n"                                             -Fore Cyan
		Write-Host "`t`t`t15. Avslutt script`n"                                 -Fore Cyan		

		[int]$Hovedmeny = Read-Host "`t`t`tUtfør" #Henter respons fra bruker
		if ( $Hovedmeny -lt 1 -or $Hovedmeny -gt $AntallMenyAlternativer ){
			Write-Host $feilmelding -Fore Red; Sleep -Seconds $VentSekunder
		}
	}

	Switch ($Hovedmeny) {

		1  {#Menyalternativ 1 - 'Vis/installer AD-tjenester'
        
        #Pakker hele menyen i en funksjon, som gjør at jeg kan reloade den senere
        function VisInstallerAD { 

            #Gir brukeren mulig til å lese output før h*n må trykke 'enter'
            function prompt_VisInstallerAD { 
                Read-Host "`nTrykk 'enter' for gå tilbake"
                $MenyVisAD = 0
                VisInstallerAD
            }

            #Funksjon som laster inn menyen uten noen form for input fra bruker
            function Last_VisInstallerAD_Direkte {
                $MenyVisAD = 0
                VisInstallerAD
            }

            [int] $AntallMenyAlternativer = 12 #Antall alternativer i undermenyen
         [string] $sti = "Hovedmeny / Vis/installer/avinstaller AD-tjenester /"

         [string] $ADDS_beskrivelse  = "Inkluderer AD-Domain-Services, RSAT-AD-Tools, RSAT-AD-PowerShell, 
                    RSAT-ADDS, RSAT-AD-AdminCenter og RSAT-ADDS-Tools"

         [string] $ADFS_beskrivelse  = "Inkluderer ADFS-Federation pakken"

         [string] $ADLDS_beskrivelse = "Inkluderer ADLDS, Remote Server Administration Tools, 
                    AD module for PowerShell, AD DS og AD LSD Tools"

         [string] $ADRMS_beskrivelse = "Inkluderer ADRMS, ADRMS-Server, ADRMS-Identity, RSAT-ADRMS" #Pakkene som inkluderes i featuren ADRMS

         [string] $ADCSSbeskrivelse = "Inkluderer AD-Certificate, ADCS-Cert-Authority, ADCS-Enroll-Web-Pol,
                    ADCS-Enroll-Web-Svc, ADCS-Web-Enrollment, ADCS-Device-Enrollment, 
                    ADCS-Online-Cert, RSAT-ADCS, RSAT-ADCS-Mgmt"
                    
                    $t3 = "`t`t`t"
                    $t5 = "`t`t`t`t`t"
			while ( $MenyVisAD -lt 1 -or $MenyVisAD -gt $AntallMenyAlternativer ) {

				Clear-Host  # Fjerner forrige meny på skjerm for å gjøre presenteringen penere

				Write-Host " $appNavn "                                                    -Fore Magenta
                Write-Host "`tDu står i:"                                        -NoNewline -Fore Cyan
                Write-Host " $sti`n" 
				Write-Host "`t`tVelg mellom følgende administrative oppgaver`n"             -Fore Cyan
				
                Write-Host "$t3`1. List opp installerte AD-tjenester på server`n"           -Fore Cyan

				Write-Host "$t3`2. Installer AD Domain Services "                -NoNewline -Fore Cyan
                Write-Host "(krever restart)"                                               -Fore Yellow
				Write-Host "$t5$ADDS_beskrivelse`n"
                
                Write-Host "$t3`3. "                                             -NoNewline -Fore Cyan
                Write-Host "Avinstaller "                                        -NoNewline -Fore Red
                Write-Host "AD Domain Services "                                 -NoNewline -Fore Cyan
                Write-Host "(krever restart)`n"                                             -Fore Yellow

				Write-Host "$t3`4. Installer AD Federation Services "                       -Fore Cyan
                Write-Host "$t5$ADFS_beskrivelse`n"
                
                Write-Host "$t3`5. "                                             -NoNewline -Fore Cyan
                Write-Host "Avinstaller "                                        -NoNewline -Fore Red
                Write-Host "AD Federation Services`n"                                       -Fore Cyan

				Write-Host "$t3`6. Installer AD Lightweight Directory Services " -NoNewline -Fore Cyan
                Write-Host "(krever restart)"                                               -Fore Yellow
                Write-Host "$t5$ADLDS_beskrivelse`n"
                
                Write-Host "$t3`7. "                                             -NoNewline -Fore Cyan
                Write-Host "Avinstaller "                                        -NoNewline -Fore Red
                Write-Host "AD Lightweight Directory Services "                  -NoNewline -Fore Cyan
                Write-Host "(krever restart)`n"                                             -Fore Yellow

                Write-Host "$t3`8. Installer AD Rights Management Services "                -Fore Cyan
                Write-Host "$t5$ADRMS_beskrivelse`n"

                Write-Host "$t3`9. "                                             -NoNewline -Fore Cyan
                Write-Host "Avinstaller "                                        -NoNewline -Fore Red
                Write-Host "AD Rights Management Services "                      -NoNewline -Fore cyan
                Write-Host "(krever restart)`n"                                             -Fore Yellow

                Write-Host "$t3`10. Installer AD Certificate Services"                      -Fore Cyan
                Write-Host "$t5$ADCSSbeskrivelse`n"

                Write-Host "$t3`11. "                                            -NoNewline -Fore Cyan
                Write-Host "Avinstaller "                                        -NoNewline -Fore Red
                Write-Host "AD Certificate Services "                            -NoNewline -Fore cyan
                Write-Host "(krever restart)"                                               -Fore Yellow

                Write-Host "`n$t3`12. Gå tilbake`n"                                         -Fore Cyan

				[int]$MenyVisAD = Read-Host "`t`tUtfør alternativ"
				if( $MenyVisAD -lt 1 -or $MenyVisAD -gt $AntallMenyAlternativer ){ 
					Write-Host $feilmelding -Fore Red; Sleep -Seconds $VentSekunder
				}
			}

			Switch ($MenyVisAD) { #Alternativer undermeny 2

				1 { #List opp installerte AD-tjenester på server

                    Write-Host "`n`tFølgende AD-tjenester er installert på server:`n“ -Fore Cyan  

                    try { #Henter features som matcher med "AD" og som er installerte
                        $installerte_ad_features = Get-WindowsFeature | 
                        ? {$_.name -match “AD”} | ? {$_.installed -match “true”} | 
                        Select -ExpandProperty name
                    } 
                    catch { FeilMelding}
                    
                        if ($installerte_ad_features -eq $null) { #Hvis variabelen er tom er ingenting installert
                            Write-Host "`tIngen Active Directory tjenester ble funnet." -Fore Red
                            prompt_VisInstallerAD #Funksjon som laster inn menyen på nytt, slik at brukere ikke trenger å gå helt tilbake til start
                         }
                         else {
                            #Kjører hele koden på nytt for å generere liste med AD tjenester
                            #Dersom koden hentes med èn variabel blir listen presentert på en linje med komma mellom hver tjeneste, noe som gjør presentasjonen stygg.
                            #Get-WindowsFeature | ? {$_.name -match “AD”} | ? {$_.installed -match “true”} | Select -ExpandProperty name
                            $installerte_ad_features
                            prompt_VisInstallerAD
                        }
                 } #List opp installerte AD-tjenester på server
                 
				2 { #Installer AD Domain Services
                    Write-Host "`n`tPrøver å installere Active Directory Domain Services.`n" -Fore Yellow
                    $sjekk = Get-WindowsFeature -Name AD-Domain-Services
                        if ($sjekk.Installed -ne "true") { #Sjekker om tjenesten allerede er installert
                            Write-Host "Helt sikker på du ønsker å installere AD Domain Services? J/N" -Fore Yellow
                            ErDuHeltSikker? #Funksjon som retunerer 'j' eller 'n'
                            Write-Host "" #Lager et mellomrom mellom svaret og output   
                                if ($valg -eq "j") {
                                    try {
                                        Install-WindowsFeature -Verbose -Name "AD-Domain-Services" -IncludeAllSubFeature -IncludeManagementTools
                                            if ($?) { #Dersom siste kommando ble utført uten problemer blir denne verdien 'true'
                                                Write-Host $Suksessfull_installering -Fore Green
                                                prompt_VisInstallerAD
                                            }
                                    } Catch { FeilMelding }

                                } #Hvis valget er noe annet enn ja
                                else { Last_VisInstallerAD_Direkte }
                        } #Hvis det finnes en installasjon fra før. 
                        else { Write-Host $ErInstallert -Fore Green; prompt_VisInstallerAD } #Trykk 'enter' for å gå tilbake
                        
				} #Installer AD Domain Services

				3 { #Avinstaller AD Domain Services
                    Write-Host "`n`tDu har valgt å prøve å avinstallere AD Domain Services`n“ -Fore Yellow
                    $sjekk1 = Get-WindowsFeature -Name AD-Domain-Services
                    $sjekk2 = Get-WindowsFeature -Name RSAT-AD-Tools
                    $sjekk3 = Get-WindowsFeature -Name RSAT-AD-PowerShell
                    $sjekk4 = Get-WindowsFeature -Name RSAT-ADDS
                    $sjekk5 = Get-WindowsFeature -Name RSAT-AD-AdminCenter
                    $sjekk6 = Get-WindowsFeature -Name RSAT-ADDS-Tools
                        if ( $sjekk1.Installed -eq "true" `
                         -or $sjekk2.Installed -eq "true" `
                         -or $sjekk3.Installed -eq "true" `
                            -or $sjekk4.Installed -eq "true" `
                            -or $sjekk5.Installed -eq "true" `
                            -or $sjekk6.Installed -eq "true" `
                        ) {
                            Write-Host "Helt sikker på du ønsker å avinstallere AD Domain Services? J/N" -Fore Yellow
                             ErDuHeltSikker? #Funksjon som retunerner 'j' eller 'n'
                             Write-Host ""   #Lager et mellomrom mellom svaret J/N og output.
                                if ($valg -eq "j") {
                                    try {
                                        Remove-WindowsFeature -Verbose AD-Domain-Services,RSAT-AD-Tools,RSAT-AD-PowerShell,RSAT-ADDS,RSAT-AD-AdminCenter,RSAT-ADDS-Tools
                                            if ($?) { Write-Host $Suksessfull_AVinstallering -Fore Green }
                                    } catch { FeilMelding }
                                } #Går tilbake til hovedmenyen momentant
                                else { Last_VisInstallerAD_Direkte }
                        } #Dersom tjenestene er installerte fra før får bruker beskjed.
                        else { Write-Host $Allerede_Avinstallert -Fore Green }

                    prompt_VisInstallerAD

                 } #Avinstaller AD Domain Services

				4 { #Installer AD Federation Services
                    Write-Host "`n`tPrøver å installere AD Federation Services`n“ -Fore Yellow
                    $sjekk = Get-WindowsFeature -Name ADFS-Federation
                        if ($sjekk.Installed -ne "true") {
                            Write-Host "Helt sikker på du ønsker å installere AD Federation Services? J/N" -Fore Yellow
                            ErDuHeltSikker? #Funksjon som retunerner 'j' eller 'n'
                            Write-Host ""   #Lager et mellomrom mellom svaret J/N og output.
                                if ($valg -eq "j") {
                                    try {
                                        Install-WindowsFeature -Verbose -Name "ADFS-Federation"
                                        if ($?) { #Sjekker om installeringen gikk fint
                                            Write-Host $Suksessfull_installering -Fore Green
                                        }
                                    } catch { FeilMelding }
                                } #Hvis valget er noe annet enn ja
                                else { Last_VisInstallerAD_Direkte }
                        } #Hvis tjenesten allerede er installert
                        else { Write-Host $ErInstallert -Fore Green }

                    prompt_VisInstallerAD

                 } #Installer AD Federation Services

				5 { #Avinstaller AD Federation Services
                    Write-Host "`n`tDu har valgt å prøve å avinstallere AD Federation Services`n“ -Fore Yellow
                    $sjekk = Get-WindowsFeature -Name ADFS-Federation 
                        if ($sjekk.Installed -eq "true") {
                            Write-Host "Helt sikker på du ønsker å avinstallere AD Federation Services? J/N" -Fore Yellow
                            ErDuHeltSikker? #Funksjon som retunerner 'j' eller 'n'
                                if ($valg -eq "j") {
                                    try {
                                        Remove-WindowsFeature -Verbose "ADFS-Federation"
                                        if ($?) {
                                            Write-Host $Suksessfull_AVinstallering -Fore Green
                                        }
                                    } catch { FeilMelding }
                                }
                                else { Last_VisInstallerAD_Direkte }
                        }
                        else { Write-Host $Allerede_Avinstallert -Fore Green }

                    prompt_VisInstallerAD
                 } #Avinstaller AD Federation Services

				6 { #Installer AD Lightweight Directory Services
                    Write-Host "`n`tPrøver å installere AD Lightweight Directory Services`n“ -Fore Yellow
                    $sjekk = Get-WindowsFeature -Name ADLDS
                        if ($sjekk.Installed -ne "true") {
                            Write-Host "Helt sikker på du ønsker å installere AD Lightweight Directory Services? J/N" -Fore Yellow
                            ErDuHeltSikker?
                                if ($valg -eq "j") {
                                    try {
                                        Install-WindowsFeature -Verbose -Name "ADLDS"
                                            if ($?) { 
                                                Write-Host $Suksessfull_installering -Fore Green
                                            }
                                    } catch { FeilMelding }
                                } #Hvis bruker ikke ønsker å avinstallere lastes menyen inn med en gang
                                else { Last_VisInstallerAD_Direkte }
                        } #Hvis tjenesten er installert får bruker beskjed
                        else { Write-Host $ErInstallert -Fore Green }

                     prompt_VisInstallerAD

                 } #Installer AD Lightweight Directory Services

                7 { #Avinstaller AD Lightweight Directory Services
                    Write-Host "`n`tDu har valgt å prøve å avinstallere AD Lightweight Directory Services`n“ -Fore Yellow
                    $sjekk1 = Get-WindowsFeature -Name ADLDS
                    $sjekk2 = Get-WindowsFeature -Name RSAT-AD-Tools
                    $sjekk3 = Get-WindowsFeature -Name RSAT-AD-Powershell
                        if ($sjekk1.Installed -eq "true" -or $sjekk2.Installed -eq "true" -or $sjekk3.Installed -eq "true") {
                            Write-Host "Helt sikker på du ønsker å avinstallere Lightweight Directory Services? J/N" -Fore Yellow
                            ErDuHeltSikker?
                                if ($valg -eq "j") {
                                    try {
                                        Remove-WindowsFeature -Verbose ADLDS,RSAT-AD-Tools,RSAT-AD-Powershell
                                            if ($?) {
                                                Write-Host $Suksessfull_AVinstallering -Fore Green
                                            }
                                    } catch { FeilMelding }
                                }
                                else { Last_VisInstallerAD_Direkte }
                        }
                        else { Write-Host $Allerede_Avinstallert -Fore Green }

                    prompt_VisInstallerAD
                 } #Avinstaller AD Lightweight Directory Services

                8 { #Installer AD Rights Management Services
                    Write-Host "`n`tPrøver å installere AD Rights Management Services`n“ -Fore Yellow
                    $sjekk = Get-WindowsFeature -Name ADRMS
                        if ($sjekk.Installed -ne "true") {
                            Write-Host "Helt sikker på du ønsker å installere AD Rights Management Services? J/N" -Fore Yellow
                            ErDuHeltSikker?
                                if ($valg -eq "j") {
                                    try {
                                        Install-WindowsFeature -Verbose -Name "ADRMS" -IncludeManagementTools -IncludeAllSubFeature
                                            if ($?) { 
                                                Write-Host $Suksessfull_installering -Fore Green
                                            }
                                    } catch { FeilMelding }
                                } #Hvis bruker ikke ønsker å installere likevel lastes menyen på nytt
                                else { Last_VisInstallerAD_Direkte }
                        }
                        else { Write-Host $ErInstallert -Fore Green }

                     prompt_VisInstallerAD
                 } ##Installer AD Rights Management Services

                9 { #Avinstaller AD Rights Management Services
                    Write-Host "`n`tDu har valgt å prøve å avinstallere AD Rights Management Services`n“ -Fore Yellow
                    $sjekk1 = Get-WindowsFeature -Name ADRMS
                    $sjekk2 = Get-WindowsFeature -Name RSAT-ADRMS
                        if ($sjekk1.Installed -eq "true" -or $sjekk2.Installed -eq "true") {
                            Write-Host "Helt sikker på du ønsker å avinstallere AD Rights Management Services? J/N" -Fore Yellow
                            ErDuHeltSikker?
                                if ($valg -eq "j") {
                                    try {
                                        Remove-WindowsFeature -Verbose ADRMS,RSAT-ADRMS
                                            if ($?) {
                                                Write-Host $Suksessfull_AVinstallering -Fore Green
                                            }
                                    } Catch { FeilMelding }
                                }
                                else { Last_VisInstallerAD_Direkte }
                        }
                        else { Write-Host $Allerede_Avinstallert -Fore Green }

                    prompt_VisInstallerAD
                 } #Avinstaller AD Rights Management Services

                10 { #Installer AD Certificate Services
                    Write-Host "`n`tPrøver å installere AD Certificate Services (AD CS)`n“ -fore Yellow
                    $sjekk = Get-WindowsFeature -Name AD-Certificate
                        if ($sjekk.Installed -ne "true") {
                            Write-Host "Helt sikker på du ønsker å installere AD Certificate Services (AD CS)? J/N" -Fore Yellow
                            ErDuHeltSikker?
                                if ($valg -eq "j") {
                                    try {
                                        Add-WindowsFeature -Verbose "AD-Certificate" -IncludeManagementTools -IncludeAllSubFeature
                                            if ($?) {
                                                Write-Host $Suksessfull_installering -Fore Green
                                            }
                                    } catch { FeilMelding }
                                } #Hvis bruker ikke ønsker å installere lastes menyen inn på nytt
                                else { Last_VisInstallerAD_Direkte }
                        }
                        else { Write-Host $ErInstallert -Fore Green }

                     prompt_VisInstallerAD
                 } #Installer AD Certificate Services

                11 { #Avinstaller AD Certificate Services

                 # Inkluderer AD-Certificate, ADCS-Cert-Authority, ADCS-Enroll-Web-Pol, ADCS-Enroll-Web-Svc, ADCS-Web-Enrollment
                 # ADCS-Device-Enrollment, ADCS-Online-Cert, RSAT-ADCS, RSAT-ADCS-Mgmt

                    Write-Host "`n`tDu har valgt å prøve å avinstallere AD Certificate Services (AD CS) Certification Authority (CA)`n“ -Fore Yellow
                    $sjekk1 = Get-WindowsFeature -Name AD-Certificate
                    $sjekk2 = Get-WindowsFeature -Name RSAT-ADCS
                    $sjekk3 = Get-WindowsFeature -Name RSAT-ADCS-Mgmt
                        if ($sjekk1.Installed -eq "true" -or $sjekk2.Installed -eq "true" -or $sjekk3.Installed -eq "true") {
                            Write-Host "Helt sikker på du ønsker å avinstallere AD Certificate Services (AD CS) Certification Authority (CA)? J/N" -Fore Yellow
                            ErDuHeltSikker?
                                if ($valg -eq "j") {
                                    try {
                                        Remove-WindowsFeature -Verbose AD-Certificate,RSAT-ADCS,RSAT-ADCS-Mgmt
                                            if ($?) {
                                                Write-Host $Suksessfull_AVinstallering -Fore Green
                                            }
                                    } catch {FeilMelding }
                                } #Dersom bruker ikke ønsker å avinstallere alikevel
                                else { Last_VisInstallerAD_Direkte }

                        } #Dersom det ikke er installert:
                        else { Write-Host $Allerede_Avinstallert -Fore Green }

                    prompt_VisInstallerAD
                 } #Avinstaller AD Certificate Services

                12 { LastInnMeny } #Går tilbake / laster inn hovedmeny

             } #Slutt MenyVisAD     
        } #Slutt funksjon VisInstallerAD

        VisInstallerAD # Kaller på funksjonen for å kjøre den

           } #Slutt menyalternativ 1 - Vis/installer AD-tjenester

        2  { #Menyalternativ 2 - 'Domene-administrasjon'

            #Ekstra hjelp og oversikt over feilmeldinger ved AD DS Deployment kan finnes på følgende link:
            #https://docs.microsoft.com/en-us/windows-server/identity/ad-ds/deploy/troubleshooting-domain-controller-deployment

            function prompt_MenyPromotering {              # Gir brukeren mulig til å lese output før h*n må trykke 'enter'
                Read-Host "`nTrykk 'enter' for gå tilbake" # Gir brukeren mulighet til å lese feilmelding på skjerm
                $MenyPromDomene = 0
                DomeneMeny
            }

            function Reload_MenyPromotering { # Laster inn meny uten intput fra bruker
                $MenyPromDomene = 0           # Setter variabelen til 0 slik at ingen av casene er valgt
                DomeneMeny                    # Kaller på hele menyen
            }

            function finnes_domain_services? () {
                try {
                    #Prøver å hente AD-Domain-Services tjenesten
                    $sjekk = Get-WindowsFeature -Name AD-Domain-Services

                    #Sjekker om tjenesten ikke er installert
                    if ($sjekk.Installed -ne "true") { Write-Host "`n`tAD-Domain-Services er ikke installert" -Fore Red }

                } Catch { FeilMelding }

            } #/Slutt finnes_domain_services

            function SkrivDomeneNavn {
                do { 
                    $script:domeneNavn = Read-Host -Prompt "`nDomene navn"
                        if ($script:domeneNavn -eq "") { Write-Host "`n`tSkriv inn et domenenavn" -Fore Red }
                } while ($script:domeneNavn -eq "")
            }

            function SkrivBrukernavnDomene {
                do { 
                    $script:brukernavn = Read-Host -Prompt "`nBrukernavn til domene server"
                        if ($script:brukernavn -eq "") { Write-Host "`n`tSkriv inn et brukernavn" -Fore Red }
                } while ($script:brukernavn -eq "")
            }

            function InstallerDNS? {
                do {
                    $script:installerDNS = Read-Host “`nInstaller DNS? (default er 'J') J/N"
                        if ($script:installerDNS -eq "") { $script:installerDNS = "j" }
                } while ($script:installerDNS -ne "j" -and $script:installerDNS -ne "n")

                #Endrer variabel slik at variabelen inneholder 'True' eller 'False'
                if ($script:installerDNS -eq "j") { $script:installerDNS = $true }
                else { $script:installerDNS = $false }
            }

            function SkrivDatabasePath {
                do {
                    $script:databasePath = Read-Host -Prompt “`nPath til domenedatabase (default er '%SYSTEMROOT%\NTDS')"
                        if ($script:databasePath -eq "") { 
                        $script:databasePath = "%SYSTEMROOT%\NTDS"
                        $script:EksistererPath = "true"
                    } else { $script:EksistererPath = Test-Path $databasePath }
                } while ($script:EksistererPath -ne "true") #Utfør så lenge pathen til domene DB'en ikke er gyldig
            }

            function SkrivLoggPath {
                do {
                    $script:logPath = Read-Host -Prompt “`nPath til domene loggfiler (default er '%SYSTEMROOT%\NTDS')"
                        if ($script:logPath -eq "") {
                            $script:logPath = "%SYSTEMROOT%\NTDS"
                            $script:EksistererPath = "true"
                    } else { $script:EksistererPath = Test-Path $logPath }
                } while ($script:EksistererPath -ne "true") #Utfør så lenge pathen til loggene ikke er gyldig
            }

            function SkrivSysLogPath {
                do {
                    $script:sysvolPath = Read-Host -Prompt “`nPath til Sysvol data (default er '%SYSTEMROOT%\SYSVOL')"
                        if ($script:sysvolPath -eq "") {
                            $script:sysvolPath = "%SYSTEMROOT%\SYSVOL"
                            $script:EksistererPath = "true"
                        } else { $script:EksistererPath = Test-Path $sysvolPath }
                } while ($script:EksistererPath -ne "true") #Utfør så lenge pathen til loggene ikke er gyldig
            }

            function RestarteServer? {
                do {
                    $script:reboot = Read-Host -Prompt “`nRestarte server med en gang? (default er 'N') J/N"
                        if ($script:reboot -eq "") { $script:reboot = "n" }
                } while ($script:reboot -ne "j" -and $script:reboot -ne "n")

                #Endrer variabel slik at variabelen inneholder 'True' eller 'False'
                if ($script:reboot -eq "j") { $script:reboot =$false }
                else { $script:reboot = $true }

                #Parameteret 'NoRebootOnCompletion' brukes. Dersom den er satt til 'true'
                #restartes ikke server. Dersom den er false, restartes server.
            }

        function DomeneMeny {

        [int]    $AntallMenyAlternativer = 9 #Antall alternativer i undermeny
        [string] $sti                    = "Hovedmeny / domene-administrasjon /"
        [string] $t                      = "`t`t`t`t" #For hver 't' lages det et tab mellomrom
        [string] $t3                     = "`t`t`t"   #Gir 3 tab mellomrom
        [string] $hostname               = Hostname
        [string] $KreverRestart          = "$t`Krever restart av server for å fullføre installasjon`n"

			while ( $MenyPromDomene -lt 1 -or $MenyPromDomene -gt $AntallMenyAlternativer ) {
				Clear-Host
				Write-Host " $appNavn "              -Fore Magenta
                Write-Host "`tDu står i:" -NoNewline -Fore Cyan
                Write-Host " $sti"
				
                finnes_domain_services?
                
                Write-Host "`n`t`tVelg mellom følgende administrative oppgaver`n"                 -Fore Cyan

				Write-Host "$t3`1. Meld server inn i domene"                                     -Fore Cyan
                    Write-Host "$t`Krever restart av server for at endringer skal tre i kraft`n" -Fore Yellow
                    
                Write-Host "$t3`2. " -NoNewline -Fore Cyan; Write-Host "Meld server " -NoNewline -Fore Cyan
                Write-Host "ut"      -NoNewline -Fore Red;  Write-Host " av domene"              -Fore Cyan
                    Write-Host $KreverRestart -Fore Yellow

                Write-Host "$t3`3. Installer ny domene forest"                         -Fore Cyan
				    Write-Host "$t`Domenenavn: "                            -NoNewline -Fore Cyan; Write-Host "(Krever input fra bruker)"
                    Write-Host "$t`Domainmode: "                            -NoNewline -Fore Cyan; Write-Host "(default 'Win2016')" 
                    Write-Host "$t`ForestMode: "                            -NoNewline -Fore Cyan; Write-Host "(default 'Win2016')"
                    Write-Host "$t`Installering av DNS: "                   -NoNewline -Fore Cyan; Write-Host "(default 'ja')"
                    Write-Host "$t`Path til domene database: "              -NoNewline -Fore Cyan; Write-Host "(default '%SYSTEMROOT%\NTDS')" 
                    Write-Host "$t`LogPath: "                               -NoNewline -Fore Cyan; Write-Host "(default '%SYSTEMROOT%\NTDS')"
                    Write-Host "$t`SysvolPath: "                            -NoNewline -Fore Cyan; Write-Host "(default '%SYSTEMROOT%\SYSVOL')"
                    Write-Host "$t`Automatisk restart etter installering: " -NoNewline -Fore Cyan; Write-Host @SjekkPunkt
                    Write-Host $KreverRestart -Fore Yellow

                Write-Host "$t3`4. Installer et underdomene i et domene"               -Fore cyan
                    Write-Host "$t`Navn forelderdomene: "                   -NoNewline -Fore Cyan; Write-Host "(Krever input fra bruker)"
			        Write-Host "$t`Navn barnedomene: "                      -NoNewline -Fore Cyan; Write-Host "(Krever input fra bruker)"
                    Write-Host "$t`Path til domene database: "              -NoNewline -Fore Cyan; Write-Host "(default '%SYSTEMROOT%\NTDS')"
                    Write-Host "$t`Installering av DNS: "                   -NoNewline -Fore Cyan; Write-Host "(default 'ja')"
                    Write-Host "$t`LogPath: "                               -NoNewline -Fore Cyan; Write-Host "(default '%SYSTEMROOT%\NTDS')"
                    Write-Host "$t`SysvolPath: "                            -NoNewline -Fore Cyan; Write-Host "(default '%SYSTEMROOT%\SYSVOL')"
                    Write-Host "$t`Automatisk restart etter installering: " -NoNewline -Fore Cyan; Write-Host "(default 'nei)"
                    Write-Host $KreverRestart                                          -Fore Yellow

                Write-Host "$t3`5. Installer en ekstra domenekontroller i et domene"   -Fore cyan
                    Write-Host "$t`Domenenavn: "                            -NoNewline -Fore Cyan; Write-Host "(Krever input fra bruker)"
                    Write-Host "$t`Installering av DNS: "                   -NoNewline -Fore Cyan; Write-Host "(default 'ja')"
                    Write-Host "$t`Path til domene database: "              -NoNewline -Fore Cyan; Write-Host "(default '%SYSTEMROOT%\NTDS')"
                    Write-Host "$t`LogPath: "                               -NoNewline -Fore Cyan; Write-Host "(default '%SYSTEMROOT%\NTDS')"
                    Write-Host "$t`SysvolPath: "                            -NoNewline -Fore Cyan; Write-Host "(default '%SYSTEMROOT%\SYSVOL')"
                    Write-Host "$t`Automatisk restart etter installering: " -NoNewline -Fore Cyan; Write-Host @SjekkPunkt
                    Write-Host $KreverRestart                                          -Fore Yellow

                Write-Host "$t3`6. Degrader / avinstaller domenekontroller"            -Fore Cyan
                    Write-Host "$t`Lokal admin passord:       "             -NoNewline -Fore Cyan; Write-Host "(Krever input)"
                    Write-Host "$t`Force removal:             "             -NoNewline -Fore Cyan; Write-Host @SjekkPunkt
                    Write-Host "$t`Automatisk restart:        "             -NoNewline -Fore Cyan; Write-Host @SjekkPunkt
                    Write-Host "$t`DemoteOperationMasterRole: "             -NoNewline -Fore Cyan; Write-Host @SjekkPunkt
                    Write-Host "$t`(Dette betyr at hvis det oppdages en master rolle
                på DC tvinges fremdeles nedgraderingen)"
                    Write-Host "`n$t`Logger for feilsøking:     "                      -Fore Cyan
                    Write-Host "$t`t - %systemroot%\debug\dcpromo.log"
                    Write-Host "$t`t - %systemroot%\debug\dcpromoui.log"

                Write-Host "`n$t3`7. List ut alle domenekontrollere i domene"          -Fore Cyan
                Write-Host "`n$t3`8. Restart server"                                   -Fore Cyan
                Write-Host "`n$t3`9. Tilbake`n"                                        -Fore Cyan

				[int]$MenyPromDomene = Read-Host "`t`tUtfør alternativ"

				if( $MenyPromDomene -lt 1 -or $MenyPromDomene -gt $AntallMenyAlternativer ){
					Write-Host $feilmelding -ForegroundColor Red ;start-Sleep -Seconds $VentSekunder
				}
			}

			Switch ($MenyPromDomene ) {

                1 { #Meld server inn i et domene
                    
                    Write-Host "`nEr du helt sikker på at du ønsker å melde denne serveren inn i et domene? J/N" -Fore Cyan
                    ErDuHeltSikker?

                        if ($valg -eq "j") {
                            Write-Host "`nSkriv domene navn:" -Fore Cyan
                            SkrivNavn
                            SkrivBrukernavnDomene

                            #Koden under splitter domenenavnet. Slik at f.eks. 'testing.local' blir til 'local'
                            #'%' er alias for Foreach-Object
                            # Kilde: http://stackoverflow.com/questions/28351275/remove-string-after-specific-character-from-list-using-powershell
                            $SplitDomeneNavn = $navn | % {$_ -replace '(.+?)\..+','$1'} #Fjerner alt bak punktum. 
                            $BrukernavnRemoteDomene =  "$SplitDomeneNavn\$brukernavn" #Slår sammen første del av domenenavn sammen med brukernavn

                            Write-Host "`nPrøver å legge til '$hostname' i domenet '$script:navn'`n" -Fore Yellow

                                #Kode som legger server til domene
                                Add-Computer -DomainName $navn -Credential $BrukernavnRemoteDomene -Verbose 
                                    if ($?) { #Hvis kommandoen gikk fint ønsker kanskje bruker å RS maskin med en gang?

                                        Write-Host "`n`tInnmeldingen gikk suksessfullt" -Fore Green
                                        Write-Host "`nRestarte server med en gang? J/N"

                                         ErDuHeltSikker? #Bruker må velge 'j' eller 'n'

                                            if ($valg -eq "j") {
                                                Write-Host "`nServer restartes`n" -Fore Yellow
                                                Restart-Computer -Force -Credential (Get-Credential) #Restarter server umiddelbart
                                            } else { Reload_MenyPromotering } #Eller går tilbake til menyen
                                    } else {
                                        Write-Host "`nNoe gikk galt med innmelding til domenet" -Fore Red
                                        prompt_MenyPromotering
                                        FeilMelding
                                    }        
                        #Hvis bruker ikke ønsker å fortsette med innmeldingen
                        } else { Reload_MenyPromotering } #Laster inn menyen på nytt

                } #/1 - Meld server inn i et domene

                2 { #Meld server ut av domene
                        Write-Host "`nnEr du helt sikker på at du ønsker melde server ut av domene? J/N" -Fore Cyan 
                        ErDuHeltSikker?
                        Write-Host "" #Lager mellomrom mellom linjene

                            if ($valg -eq "j") {

                                Write-Host "Skriv inn brukernavn og passord til domeneserver`n" -Fore Yellow
                                Remove-Computer –WorkgroupName "WORKGROUP" -UnjoinDomaincredential (Get-Credential) -Verbose

                                if ($?) { #Hvis kommandoen gikk fint ønsker kanskje bruker å RS maskin med en gang
                                    Write-Host "`nRestarte server med en gang? J/N"
                                        ErDuHeltSikker? #Bruker må velge 'j' eller 'n'

                                            if ($valg -eq "j") {
                                                Write-Host "`nServer restartes`n" -Fore Yellow
                                                Restart-Computer -Force -Credential (Get-Credential) #Restarter server umiddelbart
                                            } else { Reload_MenyPromotering } #Eller går tilbake til menyen
                                }
                                else { #Hvis det ikke gikk fint vises en feilmelding i tillegg til denne:
                                    Write-Host "`nNoe gikk galt med utmeldingen fra domenet" -Fore Red
                                    Write-Host "Hvis dette er en domenekontroller, har den blitt degradert?" -Fore Red
                                    prompt_MenyPromotering
                                }
                            }
                            else {Reload_MenyPromotering}
                } #/2 - Meld server ut av domene

				3 { # Installer ny domene forest
                    Write-Host "`nEr du helt sikker på at du ønsker å opprette ny forest? J/N" -Fore Cyan
                        ErDuHeltSikker? #Funksjon som retunerer 'j' eller 'n'.

                        if ($valg -eq "j") { #Koden under er hentet fra link: https://www.youtube.com/watch?v=Ds47YmoBqNs

                            function gi_forest_verdier {

                                Write-Host "`nVed å ikke skrive noe settes noen av verdiene til default." -Fore Cyan

                                Write-Host "`nSkriv inn domene navn:" -Fore Cyan
                                SkrivNavn #Funksjon der bruker må skrive et navn.

                                do { #Bruker må velge domainmode
                                    Write-Host "`nSpesifiser domenefunksjon`n"   -Fore Cyan 
                                    Write-Host "`tW. Server 2003    " -NoNewline -Fore Cyan; Write-Host "2"
                                    Write-Host "`tW. Server 2008    " -NoNewline -Fore Cyan; Write-Host "3"
                                    Write-Host "`tW. Server 2008 R2 " -NoNewline -Fore Cyan; Write-Host "4"
                                    Write-Host "`tW. Server 2012    " -NoNewline -Fore Cyan; Write-Host "5"
                                    Write-Host "`tW. Server 2012 R2 " -NoNewline -Fore Cyan; Write-Host "6"
                                    Write-Host "`tW. Server 2016    " -NoNewline -Fore Cyan; Write-Host "7`n" -Fore Green #Default

                                    $domainMode = Read-Host -Prompt “Domainmode? (default er '7')"

                                        if ($domainMode -eq "") { $domainMode = "7" }

                                } while ( #Kjører til et av valgene nedenfor blir valgt
                                    $domainMode -ne "2" -and `
                                    $domainMode -ne "3" -and `
                                    $domainMode -ne "4" -and `
                                    $domainMode -ne "5" -and `
                                    $domainMode -ne "6" -and `
                                    $domainMode -ne "7"
                                  )

                                do { # Forestmode
                                    Write-Host "`nSpesifiser Forest funksjon`n" -Fore Cyan 
                                    Write-Host "`tW. Server 2003    " -NoNewline -Fore Cyan; Write-Host "2"
                                    Write-Host "`tW. Server 2008    " -NoNewline -Fore Cyan; Write-Host "3"
                                    Write-Host "`tW. Server 2008 R2 " -NoNewline -Fore Cyan; Write-Host "4"
                                    Write-Host "`tW. Server 2012    " -NoNewline -Fore Cyan; Write-Host "5"
                                    Write-Host "`tW. Server 2012 R2 " -NoNewline -Fore Cyan; Write-Host "6"
                                    Write-Host "`tW. Server 2016    " -NoNewline -Fore Cyan; Write-Host "7`n" -Fore Green

                                    $forestMode = Read-Host -Prompt “Forest mode? (default er '7')"

                                    if ($forestMode -eq "") { $forestMode = "7" }

                                } while ( #Kjører til et av valgene nedenfor blir valgt
                                    $forestMode -ne "2" -and `
                                    $forestMode -ne "3" -and `
                                    $forestMode -ne "4" -and `
                                    $forestMode -ne "5" -and `
                                    $forestMode -ne "6" -and `
                                    $forestMode -ne "7"
                                  )

                                InstallerDNS?
                                SkrivDatabasePath
                                SkrivLoggPath
                                SkrivSysLogPath

                                Write-Host ""
				                Write-Host "$t`Domenenavn: "                 -NoNewline -Fore Cyan; Write-Host $navn
                                Write-Host "$t`DomainMode: "                 -NoNewline -Fore Cyan; Write-Host $domainMode
                                Write-Host "$t`ForestMode: "                 -NoNewline -Fore Cyan; Write-Host $forestMode
                                Write-Host "$t`Installering av DNS: "        -NoNewline -Fore Cyan; Write-Host $installerDNS
                                Write-Host "$t`DatabasePath: "               -NoNewline -Fore Cyan; Write-Host $databasePath
                                Write-Host "$t`LogPath: "                    -NoNewline -Fore Cyan; Write-Host $logPath
                                Write-Host "$t`SysvolPath: "                 -NoNewline -Fore Cyan; Write-Host $sysvolPath
                                Write-Host "$t`Restart etter installering: " -NoNewline -Fore Cyan; Write-Host "Ja"

                                Write-Host "`nEr innstillingene korrekte? J/N" -Fore Yellow
                                    ErDuHeltSikker?

                                if ($valg -eq "j") {

                                    Write-Host "`t`nPrøver å utføre installering`n" -Fore Yellow
                                        try {
                                            $sjekk = Get-WindowsFeature -Name AD-Domain-Services
                                                if ($sjekk.Installed -eq "true") { # Hvis tjenesten er installert fortsetter installasjonen

                                                    #Utfører installasjon
                                                    Install-ADDSForest           `
                                                    -DomainName $navn            `
                                                    -DomainMode $domainMode      `
                                                    -ForestMode $forestMode      `
                                                    -InstallDns:$installerDNS    `
                                                    -DatabasePath $databasePath  `
                                                    -LogPath $logPath            `
                                                    -SysvolPath $sysvolPath      `
                                                    -NoRebootOnCompletion:$false `
                                                    -Confirm:$false              `
                                                    -Verbose

                                                    #Server restartes med en gang, så det er ikke
                                                    #vits i å sjekke om kommando ble utført suksessfult

                                                } else { Write-Host "`n`tAD-Domain-Services er ikke installert på server`n" -Fore Red }

                                        } Catch {
                                            Write-Host "`n`tObs, noe gikk galt " -NoNewline -Fore Red; Write-Host "¯\_(ツ)_/¯"
                                            FeilMelding
                                        }

                                 prompt_MenyPromotering

                            } #Hvis innstillingene ikke er korrekte får bruker presentert valgene på nytt

                            else { gi_forest_verdier }

                            } #Slutt funksjon gi_forest_verdier

                            gi_forest_verdier #Kjører koden ovenfor
                            prompt_MenyPromotering

                            } ##Hvis bruker ikke ønsker å fortsette med installering

                        else { Reload_MenyPromotering } #Laster inn menyen på nytt

                    } #/3 - Installer ny domene forest

				4 { # Installer et underdomene i et domene

                    Write-Host "`nEr du helt sikker på at du ønsker å opprette et nytt underdomene? J/N" -Fore Yellow
                      ErDuHeltSikker?

                         if ($valg -eq "j") {

                          function gi_domenekontroller_verdier {
                            Write-Host "`nVed å ikke skrive noe settes verdiene til default." -ForegroundColor Cyan

                            #Skriv inn navn på forelderedomene
                            do { 
                                $foreldreDomene = Read-Host -Prompt “`nNavn på foreldredomene"
                                    if ($foreldreDomene -eq "") { Write-Host "`n`tSkriv inn navn på foreldredomene" -ForegroundColor Red } 
                            } while ($foreldreDomene -eq "") #Det må skrives inn et domenenavn

                            #Skriv inn navn på barnedomene
                            do { 
                                $barneDomene = Read-Host -Prompt “`nNavn på barnedomene som skal opprettes"
                                    if ($barneDomene -eq "") { Write-Host "`n`tSkriv inn navn på barnedomene" -ForegroundColor Red } 
                            } while ($barneDomene -eq "") #Det må skrives inn et navn

                            SkrivDatabasePath #Skriv inn sti der databasen skal lagres
                            InstallerDNS?     #Ønsker bruker å installere DNS?
                            SkrivLoggPath     #Skriv inn sti der loggene skal lagres
                            SkrivSysLogPath   #Skriv inn sti der SysLog skal lagres
                            RestarteServer?   #Vil bruker restarte server?

                                #Viser oppsummering
                                Write-Host "`nOppsummering over valg spesifisert`n"           -Fore Cyan
				                Write-Host "$t`Foreldredomene: "                   -NoNewline -Fore Cyan; Write-Host $foreldreDomene
                                Write-Host "$t`Barnedomene: "                      -NoNewline -Fore Cyan; Write-Host $barneDomene
                                Write-Host "$t`DatabasePath: "                     -NoNewline -Fore Cyan; Write-Host $databasePath
                                Write-Host "$t`Installering av DNS: "              -NoNewline -Fore Cyan; Write-Host $installerDNS
                                Write-Host "$t`LogPath: "                          -NoNewline -Fore Cyan; Write-Host $logPath
                                Write-Host "$t`SysvolPath: "                       -NoNewline -Fore Cyan; Write-Host $sysvolPath
                                Write-Host "$t`Ingen restart etter installering: " -NoNewline -Fore Cyan; Write-Host $reboot

                                Write-Host "`nEr innstillingene korrekte? J/N"                -Fore Yellow
                                    ErDuHeltSikker?

                            if ($valg -eq "j") {

                                Write-Host "`t`nPrøver å utføre installering`n" -Fore Yellow
                                try {
                                    $sjekk = Get-WindowsFeature -Name AD-Domain-Services
                                        if ($sjekk.Installed -eq "true") { # Hvis tjenesten er installert fortsetter installasjonen

                                            Write-Host "`nGyldig autentisering til $foreldreDomene kreves`n" -Fore Cyan
                                                Install-ADDSDomain                `
                                                -Credential (Get-Credential)      `
                                                -NewDomainName $barneDomene       `
                                                -ParentDomainName $foreldreDomene `
                                                -InstallDns:$installerDNS         `
                                                -DatabasePath $databasePath       `
                                                -LogPath $logPath                 `
                                                -SysvolPath $sysvolPath           `
                                                -NoRebootOnCompletion:$reboot     `
                                                -Verbose                          `
                                                -Confirm:$false

                                        } else { Write-Host "`n`tAD-Domain-Services er ikke installert på server`n" -Fore Red }

                                } Catch {
                                    Write-Host "`n`tObs, noe gikk galt " -NoNewline -Fore Red; Write-Host "¯\_(ツ)_/¯"
                                    FeilMelding
                                }

                               prompt_MenyPromotering

                            #Hvis innstillingene ikke er korrekte får bruker presentert valgene på nytt
                            } else { gi_domenekontroller_verdier }

                         }#/ slutt funksjon 'gi_domenekontroller_verdier'

                          gi_domenekontroller_verdier # Gjør at all kode ovenfor blir kjørt

                          prompt_MenyPromotering      # Brukeren får spørsmår om å trykke 'enter' for å gå tilbake til menyen

                         } #Hvis bruker ikke ønsker å fortsette med installering av domenekontroller

                        else { Reload_MenyPromotering } #Laster inn menyen på nytt med en gang
                                   
                } #/4 - Installer et underdomene i et domene

                5 { # Installer en ekstra domenekontroller i et domene
                    Write-Host "`nEr du helt sikker på at du ønsker å legge til en ekstra domenekontroller? J/N" -Fore Yellow
                        ErDuHeltSikker?

                        if ($valg -eq "j") {

                        function gi_ADDSDomainController_verdier {

                            Write-Host "`nSkriv inn domene navn:" -Fore Cyan
                                SkrivNavn #Funksjon der bruker må skrive et navn.

                            InstallerDNS?
                            SkrivDatabasePath
                            SkrivLoggPath
                            SkrivSysLogPath

                            Write-Host "`nOversikt over valg som er spesifisert:`n" -Fore Cyan
				            Write-Host "$t`Domenenavn: "                 -NoNewline -Fore Cyan; Write-Host $navn
                            Write-Host "$t`Installering av DNS: "        -NoNewline -Fore Cyan; Write-Host $installerDNS
                            Write-Host "$t`DatabasePath: "               -NoNewline -Fore Cyan; Write-Host $databasePath
                            Write-Host "$t`LogPath: "                    -NoNewline -Fore Cyan; Write-Host $logPath
                            Write-Host "$t`SysvolPath: "                 -NoNewline -Fore Cyan; Write-Host $sysvolPath
                            Write-Host "$t`Restart etter installering: " -NoNewline -Fore Cyan; Write-Host "Ja"

                            Write-Host "`nEr innstillingene korrekte? J/N" -Fore Yellow
                                ErDuHeltSikker? #Bruker må velge 'j' eller 'n'

                            if ($valg -eq "j") {
                                Write-Host "`t`nPrøver å utføre installering" -Fore Yellow
                                    try {
                                        Write-Host "`nSpesifiser pålogginsinfo til $navn`n" -Fore Yellow

                                        Install-ADDSDomainController  `
                                        -DomainName $navn             `
                                        -Credential (Get-Credential)  `
                                        -InstallDns:$installerDNS     `
                                        -DatabasePath $databasePath   `
                                        -LogPath $logPath             `
                                        -SysvolPath $sysvolPath       `
                                        -NoRebootOnCompletion:$false  `
                                        -Verbose                      `
                                        -Confirm:$false   

                                    } #/try prøver installering
                                    catch {
                                        Write-Host "`n`tObs, noe gikk galt " -NoNewline -ForegroundColor Red
                                        Write-Host "¯\_(ツ)_/¯`n"
                                        FeilMelding
                                    }
                            } else { gi_ADDSDomainController_verdier } #Hvis innstillingene ikke er korrekte

                        }#/funksjon gi_ADDSDomainController_verdier
                        gi_ADDSDomainController_verdier #Kaller på funksjonen

                        }#/Bruker vil ikke legge til ekstra DC
                        else { Reload_MenyPromotering } #Går tilbake til menyen

                } #/5 - Installer en ekstra domenekontroller i et domene

                6 { # Degrader/avinstaller domenekontroller

                #Ekstra tips for degradering kan finnes på følgende link:
                # https://docs.microsoft.com/en-us/windows-server/identity/ad-ds/deploy/demoting-domain-controllers-and-domains--level-200-

                    Write-Host "`nEr du helt sikker på at du ønsker å degradere domenekontroller? J/N" -Fore Yellow
                        ErDuHeltSikker?

                            if ($valg -eq "j") {
                                Write-Host "`nPrøver å degradere domenekontroller" -Fore Red
                                Write-Host "`nSkriv inn brukernavn og passord til server`n" -Fore Yellow
                                
                                Try {
                                    Uninstall-AddsDomainController `
                                    -Credential (Get-Credential)   `
                                    -localadministratorpassword (read-host -prompt "Skriv inn nytt passord for lokal administrator:" -assecurestring) `
                                    -DemoteOperationMasterRole:$true `
                                    -ForceRemoval                    `
                                    -NoRebootOnCompletion:$false     `
                                    -Confirm:$false

                                } Catch { FeilMelding }

                                prompt_MenyPromotering

                            } else { Reload_MenyPromotering }
                } #/6 - Degrader/avinstaller domenekontroller

				7 { #List ut alle domenekontrollere i domene
                    Try {
                        #Koden for å hente domenekontrollere er hentet fra følgende kilde:
                        #http://use-powershell.blogspot.no/2013/04/find-all-domain-controllers-in-domain.html
                        $DomeneKontrollere = Get-ADGroupMember "Domain Controllers"
                            if ($DomeneKontrollere) {
                                Write-Host "`nFant følgende domenekontrollere:" -Fore Green
                                $DomeneKontrollere
                            }
                            else { Write-Host "`n`tFant ingen domene kontrollere" -Fore Yellow }
                    } Catch { FeilMelding }

                    prompt_MenyPromotering

                } #/7 - List ut alle domenekontrollere i domene

                8 { #Restart server
                    Write-Host "`nEr du helt sikker på du ønsker å restarte server? J/N" -Fore Yellow
                        ErDuHeltSikker?
                        Write-Host "" #Lager mellom mellom svar ig outout på skjerm

                            if ($valg -eq "j") { 
                                Restart-Computer -Credential (Get-Credential) -Force #Restarter server umiddelbart
                            } 
                            else { Reload_MenyPromotering } #Går tilbake til meny
                } #/8 - Restart server

                9 { LastInnMeny } #/9 -Tilbake

            } #Slutt switch

        } #Slutt funksjon DomeneMeny
        
        DomeneMeny #Laster inn menyen
        
        } #Slutt menyalternativ 2 - Domene-administrasjon

		3  { #Menyalternativ 3 - 'Naviger fritt i AD'  
            
            #I funksjonene nedenfor brukes parameteret '-ErrorAction SilentlyContinue'
            # som gjør at dersom det oppstår feil i utføring av kommando så 
            #vil det ikke vises feilmelding på skjermen til bruker.


            function prompt_naviger_i_AD_meny {
                Read-Host "`n`tTrykk 'enter' for å gå tilbake"
                
                #Kaller på funksjon som resetter variabelen '$alternativ' og
                #kaller på selve meny funksjon.
                Naviger_i_AD
            }

            function testStiOgNavigerInn {

                #Tester om bruker kan navigere i det alternativet h*n har valgt.
                $TestPath1 = Test-Path $alternativ -ErrorAction SilentlyContinue
                    if ( $TestPath1 -eq $true ) { 
                        CD $alternativ
                    #    Read-Host "shiet"
                        Break
                    }
                
                #Dersom det ikke gikk med den første må stien formateres for å sjekke
                #om det er mulig å navigere i en annen del av stien.
                #Funksjonen skreller bort en del av stien som er f.eks. 'ou=test,dc=domene,dc=no'
                #stien blir da 'ou=test'

                #Formaterer bort domenenavnet. Splitter stien i to for det som 
                #er bak kommaet. F.eks. stien 'cn=2,ou=1' blir da som følger:
                # '$Del1' blir 'cn=2' 
                # '$Del2' blir 'ou=1'
                $Del1,$Del2 = $domene.split('.') 

                #Fjerner ',dc=domeneNavn' og ',dc=domene' slik at det står igjen en container/ou/gruppe
                #som f.eks. er slik: 'ou=navn'
                $StiAlternativ2 = $alternativ -replace ",dc=$Del1" -replace ",dc=$Del2"
                                  
                #Tester så denne lille stien om den er gyldig. Dersom den er gyldig
                #betyr det at vi kan navigere til den. Lagrer resultatet i en variabel
                $script:TestPath2 = Test-Path $StiAlternativ2 -ErrorAction SilentlyContinue

                    #Dersom stien er gyldig navigerer bruker inn
                    if ($script:TestPath2 -eq $true) { CD $StiAlternativ2; Break }

                #Splitter stien på nytt dersom bruker har navigert dypere inn i AD
                $script:Del1,$Del2 = $StiAlternativ2.split(',') 
                
                #Tester om denne stien er gyldig og lagrer den i en variabel
                $script:TestPath3 = Test-Path $script:Del1 -ErrorAction SilentlyContinue
                    
                    #Dersom stien er gyldig navigerer bruker inn
                    if ($script:TestPath3 -eq $true) { CD $script:Del1; Break }
            }

            function Naviger_i_AD {
                [string] $sti       = "Hovedmeny / Naviger fritt i AD /"
                [string] $script:AD = "AD:"

			    while ( $MenyNavigeriAD -lt 1 -or $MenyNavigeriAD -gt $AntallMenyAlternativer ) {

                Set-Location $script:AD #Navigerer til Active Directory

				Clear-Host #Fjerner tidligere output på skjerm
				Write-Host " $appNavn "                             -Fore Magenta
                Write-Host "`tDu står i:"                -NoNewline -Fore Cyan
                Write-Host " $sti`n" 
				Write-Host "`t`tNaviger fritt i Active Directory`n" -Fore Cyan

                if ((Test-Path $script:AD) -eq $false) {
                    Write-Host "`tFant ikke sti til AD. (Har server konfigurerte AD tjenester?)`n" -Fore Red
                    Read-Host "Trykk 'enter' for å tilbake"
                    LastInnMeny #Uansett hva brukeren skriver inn og trykker 'enter' går bruker tilbake til hovedmenyen
                } else {
                    function List_AD_valg {

                        $pwd = pwd #Lagrer stien bruker står i
                        Write-Host "`t`tGjeldende sti: " -NoNewline -Fore Cyan; Write-Host "$pwd`n"

                        $AntallMenyAlternativer = (Get-ChildItem).Count #Teller antall elementer
                        $teller = 1 # teller som skal telle de ulike alternativene

                        #Dersom det ER elementer i stien man står i:
                        if ((Get-ChildItem $AD) -ne $null) {
                            
                            #Så skal det for hvert eneste alternativ utføres:
                            Foreach ($alternativ in Get-ChildItem $AD) { #For hvert eneste alternativ i AD mappa
                            
                                #Hente objektklasse fra hvert alternativ
                                $ObjectClass = Get-ADObject -Identity $alternativ | Select -ExpandProperty ObjectClass
                            
                                Write-Host "`t`t$teller. " -NoNewline
                                Write-Host "$alternativ"   -NoNewline -Fore Cyan
                                Write-Host " ($ObjectClass)"
    
                                $teller++ #Øke teller med en slik at script går til neste alternativ

                            }#Slutt foreach

                        #Hvis script ikke finner noen elementer presenteres en feilmelding
                        } else { Write-Host "`t`t`tDet finnes ingen elementer her ¯\_(ツ)_/¯" -Fore Yellow }

                        #Telleren økes med 1, derfor trenger ike 'startPathNr' økes med 1
                        $startPathNr = $teller   #Brukes for å resette pathen man står i
                        $nrTilbake   = $teller+1 #Tilbakeknappen må være det største tallet.

                        Write-Host "`n`t`t$startPathNr. " -NoNewline; Write-Host "Naviger en sti tilbake`n"   -Fore Cyan
                        Write-Host "`t`t$nrTilbake. "     -NoNewline; Write-Host "Gå tilbake til hovedmeny`n" -Fore Cyan

                        #henter respons fra bruker
                        [int]$MenyNavigeriAD = Read-Host "`t`tUtfør alternativ"

                            if ($MenyNavigeriAD -lt 1 -or $MenyNavigeriAD -gt $nrTilbake) {
                                Write-Host $feilmelding -Fore Red; Sleep -Seconds $VentSekunder
                            }
                            else {
                                
                                #Sjekker først om bruker vil gå tilbake eller navigere en mappe opp
                                if ($MenyNavigeriAD -eq $nrTilbake)   { LastInnMeny }
                                if ($MenyNavigeriAD -eq $startPathNr) { cd.. } #Navigerer en mappe opp
                                
                                #Dersom tallet ikke matcher med tilbakeknapp eller en mappe tilbake:
                                if ($MenyNavigeriAD -ne $nrTilbake -or
                                    $MenyNavigeriAD -ne $startPathNr) {
                                    
                                    $Nummer = 1

                                        #For hvert eneste alternativ i mappa man står i
                                        foreach ($alternativ in Get-ChildItem $pwd) { 
                                            
                                            #Dersom telleren matcher med det innskrevne tallet:
                                            if ($MenyNavigeriAD -eq $Nummer) {

                                                 #Tester sti, dersom den den 
                                                 testStiOgNavigerInn
                                            }
                                            
                                            $Nummer++ #Øker teller med 1

                                        } #Slutt foreach

                                } #Slutt If

                            }#Slutt else

                    } #/List_AD_valg

                }#/else

                List_AD_valg #Funksjon som lister innhold i AD

			} #/else

        } #/ funksjon Naviger_i_AD
        
            Naviger_i_AD #Kaller på funksjonen

		} #Slutt menyalternativ 3 - Naviger fritt i AD

        4  { #Menyalternativ 4 - 'Brukeradministrasjon'

            function Prompt_brukerAdministrasjon { #funksjon som gir bruker mulighet til å trykk enter for menyen lastes inn på nytt
                Read-Host "`nTrykk 'enter' for å gå tilbake"
                $MenyBruker = 0
                brukeradministrasjon
            }

            function Reload_brukerAdministrasjon {
                $MenyBruker = 0
                brukeradministrasjon
            }

            function SkrivFornavn {
                do {
                    [string]$script:fornavn = Read-Host "`nFornavn"
                    $script:fornavn = $script:fornavn.ToLower() #Konverterer alt til små bokstaver
                    if ($script:fornavn -eq "") {
                        Write-Host "`n`tFornavnet kan ikke være blankt" -Fore Red
                    }
                    if ($script:fornavn -ne "" -and $script:fornavn.Length -lt 2) {
                        Write-Host "`n`tFornavnet kan ikke være kortere enn to bokstaver" -Fore Red
                    }
                    
                 } while ($script:fornavn.Length -lt 2) #Utføres så lenge fornavnet er tomt eller mindre enn to bokstaver
            } #/SkrivFornavn

            function SkrivEtternavn {
                 do {
                    [string]$script:etternavn = Read-Host "`nEtternavn"
                    $script:etternavn = $script:etternavn.ToLower() #Konverterer alt til små bokstaver
                    if ($script:etternavn -eq "") {
                        Write-Host "`n`tEtternavnet kan ikke være blankt" -Fore Red
                    }
                    if ($script:etternavn -ne "" -and $script:etternavn.Length -lt 2) {
                        Write-Host "`n`tEtternavnet kan ikke være kortere enn to bokstaver" -Fore Red
                    }
                 } while ($script:etternavn.Length -lt 2) #Utføres så lenge etternavnet er tomt eller mindre enn to bokstaver
            } #/SkrivEtternavn

            function FinnInitialerNavn ($fornavn, $etternavn) {
                $InFornavn = $fornavn.Substring(0,1)     #Fjerner alt bak den første bokstaven
                $InEtternavn = $etternavn.Substring(0,1) #Fjerner alt bak den første bokstaven
                $Initialer = "$InFornavn$InEtternavn"    #Smelter sammen de to variabelene
                $script:Initialer = $Initialer.ToUpper() #Konverterer alt til store bokstaver
                #return $Initialer
            }

            function SkrivBrukerNavn {
                do {
                    [string]$script:brukernavn = Read-Host "`nBrukernavn"
                    if ($script:brukernavn -eq "") {
                        Write-Host "`n`tBrukernavnet kan ikke være blankt" -Fore Red
                    }
                 } while ($script:brukernavn -eq "") #Utføres så lenge variabel er tom
            } #/SkrivBrukerNavn

            function FulltNavn {
                $script:fulltNavn = "$fornavn $etternavn"
            } #/FulltNavn

            function FormaterBrukernavn {
                #Parametre som forventes å mottas
                param($fornavn,$etternavn)

                #Beholder de 5 første bokstavene i navnet
                $fornavn = $fornavn.substring(0, [System.Math]::Min(5, $fornavn.Length))

                #Beholder de 5 første bokstavene i etternavnet
                $etternavn = $etternavn.substring(0, [System.Math]::Min(5, $etternavn.Length))

                #Smelter sammen fornavn og etternavn til førsteutkast av brukernavnet
                
                #Fjerner alle mellomrom i navnet hvis det er noen
                $fulltNavn = "$fornavn$etternavn" 

                #Fjerner alle mellomrom
                $brukernavn = $fulltNavn -replace(' ','') 
                
                #Erstatter Æ, Ø, Å med bokstavene E, O og A
                $brukernavn = $brukernavn -replace('æ','e') -replace('ø','o') -replace('å','a')
                
                #Retunerer det ferdige brukernavnet
                return $brukernavn #| Out-Null
            } #/FormaterBrukernavn

            function GenererUniktBrukernavn {
                    
                #Sender fornavn og etternavn til funksjonen for å generere et brukernavn
                $script:brukernavn = FormaterBrukernavn $fornavn $etternavn

                FinnBrukerNavn #Søker etter brukernavn og lagrer resultat i en variabel

                #Dersom brukernavn finnes må det opprettes et nytt og unikt et.
                    if ($BrukerFinnes) { 
                        Write-Host "`n`tBrukernavnet '$script:brukernavn' som ble generert finnes fra før" -Fore Yellow
                        $AntallTegn = $script:brukernavn.Length #Regner ut antall tegn i brukernavnet
                        $teller = 1
                            do {
                                #Sørger for at brukernavnet får et tall bak, og ikke to tall.
                                #F.eks. at det blir "navn1" og "navn2" i stedet for "navn12".
                                $script:brukernavn = $script:brukernavn.substring(0, [System.Math]::Min($AntallTegn, $script:brukernavn.Length))

                                #Setter telleren bak brukernavn
                                $script:brukernavn = $script:brukernavn + $teller #Setter brukernavn pluss tallet 1.

                                #Søker etter om det nye brukernavnet eksisterer.
                                FinnBrukerNavn

                                $teller++ #Øker telleren med 1.

                            } while ($BrukerFinnes -ne $null) #UTføres helt til det lages et unikt brukernavn

                          #Gir litt feedback til bruker
                          Write-Host "`tEndrer brukernavn til '$script:brukernavn'" -Fore Yellow

                        }#Gir feedback til brukeren om brukernavnet som er generert
                        else { Write-Host "`nBrukernavn: " -NoNewline -Fore Cyan; Write-Host "$script:brukernavn" }
    }

            function GenererUniktForNavn {
                    
                    $teller = 1
                        do {
                            #Regner ut antall bokstaver i fornavnet
                            $Lengde = $fornavn.Length
                            $fornavn = $fornavn.substring(0, [System.Math]::Min($Lengde,$Lengde))

                            #Koden ovenfor fjerner alle tall/bokstaver som er lengre enn antall
                            #bokstaver/tall i fornavnet.

                            #Setter fornavn pluss tallet 1.
                            $fornavn = $fornavn + $teller #Fornavn blir f.eks. "navn1"

                            #Hvis navnet ikke sletter antall bokstaver/tall bak fornavnet blir
                            #fornavnet slik: 'fornavn123456' i stedet for 'fornavn6'

                            #Søker etter om det finnes en bruker med fornavn og etternavnet i AD
                            FinnBrukerVia-Fornavn-Etternavn
                            
                            $teller++ #Øker telleren med 1.

                            #Utføres så lenge brukernavnet finnes
                        } while ($brukerFornavnEtternavn -ne $null)

                        Write-Host "`tEndrer derfor fornavnet til '$fornavn'" -Fore Yellow #Gir tilbakemelding til bruker
                        $fulltNavn = "$fornavn $etternavn" #oppdaterer fullt navn med det nye fornavnet
                    
                    #Gjør at variablen kan endres i andre scope. Dette må gjøres slik at andre
                    #funksjoner kan få tilgang til den endrede variabelen.
                    $script:fornavn = $fornavn 
            } #/GenererUniktForNavn

            function SkrivPassord {
                do {
                    $script:passord = Read-Host -AsSecureString "`nSkriv inn et passord på minst 7 tegn."
                    if ($passord -eq "") {
                        Write-Host "`nPassordet kan ikke være blankt`n" -Fore Red
                    }
                    if ($passord.Length -lt 7) {
                        Write-Host "`nPassordet kan ikke være mindre enn 7 tegn`n" -Fore Red
                    }
                 } while ($passord.Length -lt 7)
            } #/SkrivPassord
        
            function FinnBrukerNavn {
                try { 
                    $script:BrukerFinnes = Get-ADUser -Filter "SamAccountName -eq '$brukernavn'" |
                    FL -Property GivenName,Surname,Name,ObjectClass,SamAccountName,Enabled,DistinguishedName
                }
                catch {
                    FeilMelding #Viser eventuell feilmelding
                    Prompt_brukerAdministrasjon #Gir bruker mulighet til å trykke 'enter' for bruker går tilbake til menyen
                }
            } #/FinnBruker

            function FinnBrukerVia-Fornavn-Etternavn {
                try { $script:brukerFornavnEtternavn =  Get-ADUser -Filter "Name -Like '$fornavn $etternavn'" }
                catch {
                    FeilMelding #Viser eventuell feilmelding
                    Prompt_brukerAdministrasjon #Gir bruker mulighet til å trykke 'enter' for bruker går tilbake til menyen
                }   
            } #/Slutt funksjon

            function VisFunnetBruker {
                if ($BrukerFinnes) {
                    Write-Host "`n`tFant følgende bruker:" -Fore Green
                    $BrukerFinnes
                }
                else {
                    Write-Host "`n`tFant ingen bruker med navn '$brukernavn'" -Fore Yellow
                    Prompt_brukerAdministrasjon
                }
            } #/VisFunnetBruker

            function ValiderEpost ($epost) {
                ([bool] ($epost -as [Net.Mail.MailAddress])) #Kode hentet fra https://social.technet.microsoft.com/Forums/windowsserver/en-US/24afc144-6074-49b3-96ed-3a60fc1db1a6/simple-way-to-validate-an-email-address?forum=winserverpowershell
            } #/ValiderEpost

            function SkrivInnAntallDager {
                do { #Legger varabelen til script scope'et slik at den kan endres.
                    Write-Host "`nSkriv inn antall dager:" -Fore Cyan
                    $script:Antall = Read-Host "`tDager" #henter input fra bruker
                        if ($script:Antall -eq "") {Write-Host "`n`tVennligst skriv inn et tall." -Fore Red}
                } while ($script:Antall -eq "")
            } #/SkrivInnAntallDager
        
        #Funksjon for å vise undermenyen
        function brukeradministrasjon {

            [int] $AntallMenyAlternativer = 18 #Antall alternativer i undermeny 1
         [string] $sti = "Hovedmeny / Brukeradministrasjon /"
                  $t3  = "`t`t`t"
                  $t4  = "`t`t`t`t"       

			while ( $MenyBruker -lt 1 -or $MenyBruker -gt $AntallMenyAlternativer ) {
				Clear-Host
				Write-Host " $appNavn "                                          -Fore Magenta
                Write-Host "`tDu står i:"                             -NoNewline -Fore Cyan
                Write-Host " $sti`n"
				Write-Host "`t`tVelg mellom følgende administrative oppgaver`n"  -Fore Cyan

				Write-Host "$t3`1. Legg til brukere fra CSV-fil`n"               -Fore Cyan

				Write-Host "$t3`2. Legg til ny bruker"                           -Fore Cyan
                    Write-Host "$t4`Fornavn:   "                      -NoNewline -Fore Cyan; Write-Host "(kreves)"
                    Write-Host "$t4`Etternavn: "                      -NoNewline -Fore Cyan; Write-Host "(kreves)"
                    Write-Host "$t4`E-post:    "                      -NoNewline -Fore Cyan; Write-Host "(valgfritt)"
                    Write-Host "$t4`Passord:   "                      -NoNewline -Fore Cyan; Write-Host "(kreves)"
                    Write-Host "$t4`Endre passord ved første login: " -NoNewline -Fore Cyan; Write-Host "J/N"
                    Write-Host "$t4`Aktiver bruker: "                 -NoNewline -Fore Cyan; Write-Host "J/N"
                    Write-Host "$t4`Legg til i gruppe / OU: "         -NoNewline -Fore Cyan; Write-Host "(valgfritt)`n"

				Write-Host "$t3`3. Slett en bruker ved hjelp av brukernavn`n"    -Fore Cyan
                Write-Host "$t3`4. Lås opp bruker`n"                             -Fore Cyan
                Write-Host "$t3`5. List ut låste brukere`n"                      -Fore Cyan
                Write-Host "$t3`6. Aktiver / Deaktiver:"                         -Fore Cyan
                    Write-Host "$t4`- En bruker"
                    Write-Host "$t4`- En gruppe"
                    Write-Host "$t4`- En Organizational Unit`n"

                Write-Host "$t3`7. List ut alle aktiverte / deaktiverte brukere`n" -Fore Cyan
                Write-Host "$t3`8. List ut deaktiverte maskiner`n"                 -Fore Cyan
                Write-Host "$t3`9. List ut inaktive brukerkontoer`n"               -Fore Cyan
                
                Write-Host "$t3`10. Søk etter brukere ved hjelp av"                -Fore Cyan
                    Write-Host "$t4`- Fornavn"
                    Write-Host "$t4`- Etternavn"
                    Write-Host "$t4`- Fullt navn"
                    Write-Host "$t4`- Brukernavn"
                    Write-Host "$t4`- E-post`n"   

                Write-Host "$t3`11. Tilbakestill passord for bruker`n"                            -Fore Cyan
                Write-Host "$t3`12. Vis brukere som har konto som utløper i løpet av 'x' dager`n" -Fore Cyan
                Write-Host "$t3`13. Vis brukere har passord som utløper etter antall dager"       -Fore Cyan
                Write-Host "$t3`    spesifisert i standard passord policy på server`n"            -Fore Cyan
                Write-Host "$t3`14. Deaktiver alle brukere eldre enn 'x' dager`n"                 -Fore Cyan
                Write-Host "$t3`15. Legg til profil/logonscript til brukere i en gruppe/ou`n"     -Fore Cyan
                Write-Host "$t3`16. Vis hvilke grupper en bruker tilhører`n"                      -Fore Cyan
                Write-Host "$t3`17. Vis historie for gruppemedlemsskap for en bruker`n"           -Fore Cyan

                Write-Host "$t3`18. Gå tilbake`n"                                                 -Fore Cyan
				[int]$MenyBruker = Read-Host "`t`tUtfør alternativ"
				if( $MenyBruker -lt 1 -or $MenyBruker -gt $AntallMenyAlternativer ){
					Write-Host $feilmelding -Fore Red; Sleep -Seconds $VentSekunder
				}
			}

			Switch ($MenyBruker) {

				1 { #Legg til brukere fra CSV-fil
                    #Bruker må spesifisere stien
                    Write-Host "`nHvor ligger CSV-fila?" -Fore Cyan
                    skriv_gyldig_path_til_fil # Kaller på funksjon som håndterer CSV-path

                try {
                    Import-Csv -Delimiter ";" -Header a,b,c,d -Path $path | # Select-Object a
                        ForEach-Object {
                            $fornavn       = $_.a
                            $etternavn     = $_.b
                            $script:navnOU = $_.c
                                FulltNavn #Lager fullt navn ut ifra fornavn og etternavn
                                FinnBrukerVia-Fornavn-Etternavn
                                GenererUniktForNavn
                                FinnDistinguishedNameOU #Finner OU ut ifra $navnou
                                    if ($script:DistinguishedName -eq $null) { #Dersom navnet på OU'et i CSV-fila ikke finnes i AD:
                                        Write-Host "Fant ingen OU med navn '$script:navnOU'" -Fore Red #Så vises en feilmelding
                                        Prompt_brukerAdministrasjon
                                    }
                                FinnInitialerNavn $fornavn $etternavn
                                FormaterBrukernavn $fornavn $etternavn | Out-Null #Hindrer funksjonen å vise brukernavnet på skjermen.
                                GenererUniktBrukernavn

                            $passord = $_.d | ConvertTo-SecureString -AsPlainText -Force #Konverterer passordet
                                try {
                                    New-ADUser                  `
                                    -Name $fulltNavn            `
                                    -GivenName $fornavn         `
                                    -Surname $etternavn         `
                                    -Initials $Initialer        `
                                    -SamAccountName $brukernavn `
                                    -DisplayName $brukernavn           `
                                    -UserPrincipalName $brukerNavn     `
                                    -AccountPassword $passord          `
                                    -Path $script:DistinguishedName
                                        if ($?) {Write-Host "`n`tBruker '$fornavn $etternavn' ble opprettet suksessfullt i OU '$script:navnOU'" -Fore Green }
                                 } catch { FeilMelding }
                        }
                    } catch { FeilMelding }

                #Bruker må trykke 'enter' for å gå tilbake til hovedmeny.
                #Dette gir bruker tid til å lese resultat av kommando.
                Prompt_brukerAdministrasjon 

                } #Legg til brukere fra CSV-fil

				2 { #Legg til ny bruker

                function skriv_inn_brukerInfo {
                    do {
                        Write-Host "`nFyll ut følgende:" -Fore Cyan
                        SkrivFornavn   #Bruker skriver inn fornavn
                        SkrivEtternavn #Bruker skriver inn etternavn
                        
                        FinnInitialerNavn $fornavn $etternavn #Genererer initialer fra fornavn og etternavn

                        #Funksjon som søker etter bruker med samme fornavn og etternavn.
                        #Funksjonen legger brukeren i en variabel
                        FinnBrukerVia-Fornavn-Etternavn

                            #Sjekk om brukeren eksisterer. Hvis det finnes en bruker med samme fornavn
                            #og etternavn må fornavnet endres. AD kan ikke ha to brukere med samme fornavn
                            #og etternavn.
                            if ($brukerFornavnEtternavn) { 
                                Write-Host "`n`tBrukeren '$fornavn $etternavn' finnes fra før" -Fore Yellow
                                GenererUniktForNavn
                                $fornavn = $fornavn
                            }

                        FulltNavn      #Genererer fullt navn ut ifra hva som ble skrevet i 'fornavn' og 'etternavn'

                        #Funksjon som søker etter brukernavn og genererer et unikt brukernavn.
                        Write-Host "`nGenererer et unikt brukernavn." -Fore Cyan
                            GenererUniktBrukernavn

                        #Lar brukeren få mulighet til å skrive inn epost
                        do { 
                            [string]$epost = Read-Host "`nE-post" 
                                if ($epost -eq "") { $gyldig = $true} #Hvis den er blank kan bruker få lov å gå videre
                                else { #Hvis feltet ikke er blankt valideres den innskrevne eposten.
                                    $gyldig = validerEpost $epost
                                        if ($gyldig -eq $false) { #Dersom den er ugyldig får bruker feilmelding.
                                            Write-Host "`n`tUgyldig e-post adresse" -Fore Red
                                        }
                                }
                        } while ( $gyldig -ne $true )
                    
                        #Endre passord ved første innlogging?
                        Write-Host "`nEndre passord ved første innlogging? J/N" -Fore Cyan
                            ErDuHeltSikker? #Funksjon som krever 'j' eller 'n'
                                #Utfører sjekk om hva som ble valgt.
                                if ($valg -eq "j") { $endrePassordVedLogin = $true }
                                else { $endrePassordVedLogin = $false }

                        #Enable bruker med en gang?
                        Write-Host "`nAktiver bruker? J/N" -Fore Cyan
                            ErDuHeltSikker? #Funksjon som krever 'j' eller 'n'
                                #Utfører sjekk om hva som ble valgt og endrer variablenavn slik at den kan brukes senere
                                if ($valg -eq "j") { $enabledOrDisabled = $true }
                                else { $enabledOrDisabled = $false }

                        Write-Host "" #Gir et mellomrom i outputen slik at det skal se penere ut.
                        SkrivPassord  #Funksjon som krever et passord på minimum 7 tegn.

                        Write-Host "`nLegge til brukeren i OU / gruppe? J/N" -Fore Cyan
                            ErDuHeltSikker? #Funksjon som krever 'j' eller 'n'

                        #Hvis ja må det spesifiseres gruppe eller OU.
                            if ($valg -eq "j") {
                        do { #Spørr brukeren hva h*n ønsker å legge brukeren i
                            Write-Host "`nHva ønsker du å legge brukeren i?`n" -Fore Cyan
                            Write-Host "`t1. " -NoNewline; Write-Host "Gruppe" -Fore Cyan
                            Write-Host "`t2. " -NoNewline; Write-Host "Organizational Unit" -Fore Cyan
                            $type = Read-Host "`nType"
                                if ( $type -ne "1" -and $type -ne "2" ) { 
                                    Write-Host "`n`tVennligst velg mellom '1' og '2'" -Fore Red
                                }
                        #Utføres så lenge det ikke velges 1 eller 2.
                        } while ( $type -ne "1" -and $type -ne "2" )


                        #Dersom det velges 1, altså gruppe:
                        if ($type -eq "1") {
                        $type = "Gruppe" #Variabel som skal brukes i oversikten
                            do { 
                                Write-Host "`nSkriv inn gruppenavn:" -Fore Cyan
                                SkrivGruppeNavn #Skriv inn gruppenavn
                                FinnGruppe      #Søker etter gruppe og legger gruppa i en variabel
                                    if ($GruppeFinnes) { #Sjekk om variabelen er tom / om den inneholder en gruppe
                                        Write-Host "`nFølgende gruppe ble funnet:`n" -Fore Cyan
                                        $GruppeFinnes #Viser gruppa som er i variabelen
                                        Write-Host "`nEr dette korrekt gruppe? J/N" -Fore Yellow
                                            ErDuHeltSikker? #Funksjon som retunerer 'j' eller 'n'
                                    }
                                    else { 
                                        Write-Host "`n`tFant ikke gruppe med navn '$gruppeNavn'`n" -Fore Yellow
                                        Read-Host "Trykk 'enter' for å prøve på nytt"
                                        $valg = "n" #Valg settes til 'n' slik at bruker må skrive inn navn på gruppe på nytt.
                                    }

                            } while ($valg -eq "n") #Utføres så lenge brukeren velger "n" for nei.

                          $Gruppe_eller_OU = $gruppeNavn
                        }
                        else { #Dersom det ikke ble valgt 1 må valget være 2
                            $type = "Organizational Unit" #Variabel som skal brukes i oversikten
                            
                          do {
                            $valg = "" #Må resette valg siden variabelen kan endres lenger ned.
                            #Hvis den ikke endres blir variabelverdien 'n' noe som looper slik at
                            #bruker på skrive inn navn på OU i det uendelige.
                           
                             SkrivNavnOU #Bruker spesifiserer navn på OU
                             FinnOrganizationalUnit #Funksjon som søker etter OU
                                if ($OU) { #Dersom OU'et eksisterer
                                    Write-Host "`nFølgende Organizational Unit ble funnet:`n" -Fore Cyan
                                    $OU #Vises OU'et
                                        FinnDistinguishedNameOU ##Ordner GUID for valgt OU
                                        Write-Host "Er dette korrekt Organizational Unit? J/N" -Fore Yellow
                                            ErDuHeltSikker? #Funksjon som retunerer 'j' eller 'n'
                                }
                                else { 
                                    Write-Host "`n`tFant ikke Organizational Unit med navn '$navnOU'`n" -Fore Yellow
                                    Read-Host "Trykk 'enter' for å prøve på nytt"
                                    $valg = "n"
                                    }
                             } while ($valg -eq "n")

                          $Gruppe_eller_OU = $navnOU
                        }
                    }
                            else { $type = "" }

                            #Lager en oppsummering med informasjonen som er valgt.
                            Write-Host "`nOversikt over informasjon som er valgt til brukeren:`n" -ForegroundColor Cyan
                            Write-Host "`tFornavn:        "                      -NoNewline -Fore Cyan; Write-Host $fornavn
                            Write-Host "`tEtternavn:      "                      -NoNewline -Fore Cyan; Write-Host $etternavn
                            Write-Host "`tInitialer:      "                      -NoNewline -Fore Cyan; Write-Host $Initialer
                            Write-Host "`tFullt navn:     "                      -NoNewline -Fore Cyan; Write-Host $fulltNavn
                            Write-Host "`tBrukernavn:     "                      -NoNewline -Fore Cyan; Write-Host $brukerNavn
                            Write-Host "`tE-post:         "                      -NoNewline -Fore Cyan; Write-Host $epost   
                            Write-Host "`tPassord:        "                      -NoNewline -Fore Cyan; Write-Host "********"
                            Write-Host "`tAktiver bruker: "                      -NoNewline -Fore Cyan; Write-Host $enabledOrDisabled
                            Write-Host "`tEndre passord ved første innlogging: " -NoNewline -Fore Cyan; Write-Host $endrePassordVedLogin
                            Write-Host "`tLegg brukeren til i OU/gruppe:       " -NoNewline -Fore Cyan; Write-Host $type
                            Write-Host "`t$type "                                -NoNewline -Fore Cyan; Write-Host $Gruppe_eller_OU
                            Write-Host "`nEr innstillingene korrekte? J/N"

                            ErDuHeltSikker? #Funksjon som retunerer 'j' eller 'n'

                #Dersom bruker velger 'n' får bruker mulighet til å fylle inn verdiene på nytt
                #Utføres så lenge bruker ikke er fornøyd med informasjonen som h*n har skrevet.
                } while ($script:valg -eq "n") 
                    
                    if ($valg -eq "j") {
                        try {
                           
                            function BleBrukerOpprettet? {
                                if ($?) { Write-Host "`n`tBrukeren '$fulltNavn' ble opprettet suksessfullt" -Fore Green }
                            }
                            function BleBrukerLagtiGruppe? {
                                if ($?) { Write-Host "`tBrukeren '$fulltNavn' ble lagt i gruppa '$gruppeNavn' suksessfullt" -Fore Green }
                            }
                            function BleBrukerOpprettetiOrganizationalUnit? {
                                if ($?) {
                                    Write-Host "`n`tBrukeren '$fulltNavn' ble opprettet suksessfullt" -Fore Green
                                    Write-Host "`tBrukeren ble også lagt til i OU: $DistinguishedName" -Fore Green }
                            }

                            #Dersom epost er skrevet inn og bruker IKKE skal legges til gruppe eller OU:
                            if ($epost -ne "" -and $type -eq "") {
                            New-ADUser `
                            -Name $fulltNavn -DisplayName $brukernavn -GivenName $fornavn -Initials $Initialer `
                            -Surname $etternavn -UserPrincipalName $brukerNavn -SamAccountName $brukerNavn     `
                            -AccountPassword $passord -Enabled $enabledOrDisabled -ChangePasswordAtLogon $endrePassordVedLogin `
                            -EmailAddress $epost
                            BleBrukerOpprettet? #Sjekker om bruker ble opprettet

                            }

                            #Dersom epost IKKE er skrevet inn og bruker IKKE skal legges til gruppe eller OU:
                            if ($epost -eq "" -and $type -eq "") {
                            New-ADUser `
                            -Name $fulltNavn -DisplayName $brukernavn -GivenName $fornavn -Initials $Initialer `
                            -Surname $etternavn -UserPrincipalName $brukerNavn -SamAccountName $brukerNavn     `
                            -AccountPassword $passord -Enabled $enabledOrDisabled -ChangePasswordAtLogon $endrePassordVedLogin
                            
                            BleBrukerOpprettet? #Sjekker om bruker ble opprettet

                            }

                            #Dersom epost IKKE er skrevet inn og bruker SKAL legges til gruppe:
                            if ($epost -eq "" -and $type -eq "Gruppe") {
                            New-ADUser `
                            -Name $fulltNavn -DisplayName $brukernavn -GivenName $fornavn -Initials $Initialer `
                            -Surname $etternavn -UserPrincipalName $brukerNavn -SamAccountName $brukerNavn     `
                            -AccountPassword $passord -Enabled $enabledOrDisabled -ChangePasswordAtLogon $endrePassordVedLogin
                            
                            BleBrukerOpprettet? #Sjekker om bruker ble opprettet
                            Add-ADGroupMember $GruppeFinnes -Members $brukernavn #Legger den nye brukeren til i gruppa
                            BleBrukerLagtiGruppe? #Sjekker om bruker ble lagt til i gruppe

                            }

                            #Dersom epost er skrevet inn og bruker SKAL legges til gruppe:
                            if ($epost -ne "" -and $type -eq "Gruppe") {
                            New-ADUser `
                            -Name $fulltNavn -DisplayName $brukernavn -GivenName $fornavn -Initials $Initialer `
                            -Surname $etternavn -UserPrincipalName $brukerNavn  -SamAccountName $brukerNavn `
                            -AccountPassword $passord -Enabled $enabledOrDisabled -ChangePasswordAtLogon $endrePassordVedLogin `
                            -EmailAddress $epost

                            BleBrukerOpprettet? #Sjekker om bruker ble opprettet
                            Add-ADGroupMember $GruppeFinnes -Members $brukernavn #Legger den nye brukeren til i gruppa
                            BleBrukerLagtiGruppe? #Sjekker om bruker ble lagt til i gruppe

                            }
                            
                            #Dersom epost IKKE er skrevet inn og bruker SKAL legges til OU:
                            if ($epost -eq "" -and $type -eq "Organizational Unit") {
                            New-ADUser `
                            -Name $fulltNavn -DisplayName $brukernavn -GivenName $fornavn -Initials $Initialer `
                            -Surname $etternavn -UserPrincipalName $brukerNavn  -SamAccountName $brukerNavn `
                            -AccountPassword $passord -Enabled $enabledOrDisabled -ChangePasswordAtLogon $endrePassordVedLogin `
                            -Path $DistinguishedName

                            BleBrukerOpprettetiOrganizationalUnit?

                            }

                            #Dersom epost er skrevet inn og bruker SKAL legges til OU:
                            if ($epost -ne "" -and $type -eq "Organizational Unit") {
                            New-ADUser                                   `
                            -Name $fulltNavn -DisplayName $brukernavn -GivenName $fornavn -Initials $Initialer `
                            -Surname $etternavn -UserPrincipalName $brukerNavn  -SamAccountName $brukerNavn `
                            -AccountPassword $passord -Enabled $enabledOrDisabled -ChangePasswordAtLogon $endrePassordVedLogin `
                            -Path $DistinguishedName -EmailAddress $epost

                            BleBrukerOpprettetiOrganizationalUnit?

                            }

                        } catch { FeilMelding }

                        }
                        else { skriv_inn_brukerInfo }
                    
                }#/ skriv_inn_brukerInfo

                skriv_inn_brukerInfo #Kjører funksjon
                Prompt_brukerAdministrasjon #Trykk 'enter' for å gå tilbake. Bruker får tid til å lese input

                } #Legg til ny bruker

				3 { #Slett en bruker ved hjelp av brukernavn
                    SkrivBrukerNavn
                    FinnBrukerNavn #Funksjonen inneholder en 'Try' slik at ved eventuelle feil avbrytes det, og bruker får mulighet til å gå tilbake til meny
                    VisFunnetBruker
                        Write-Host "Er du helt sikker på at du ønsker å slette brukeren? J/N`n" -Fore Yellow
                        ErDuHeltSikker?
                    
                        if ($valg -eq "j") {
                            $BrukerGUID = Get-ADUser -Filter "SamAccountName -like '$brukernavn'" | Select-Object -Property ObjectGUID
                            $BrukerGUID = $BrukerGUID -replace "@{ObjectGUID=" -replace "}" #Formaterer GUID'en slik at den kan brukes
                            Write-Host "" #Gir et mellomrom mellom setningen "er du helt sikker.." og verbose output fra kommandoen.
                                Remove-ADUser -Identity $BrukerGUID -Verbose -Confirm:$false
                                    if ($?) { Write-Host "`n`tBrukeren '$brukernavn' ble slettet suksessfullt" -Fore Green }
                        }
                        else { Reload_brukerAdministrasjon }
                    Prompt_brukerAdministrasjon

                } #Slett en bruker ved hjelp av brukernavn

                4 { #Lås opp bruker
                    do { 
                        Write-Host "`nSkriv inn brukernavn på brukeren" -Fore Cyan
                         SkrivBrukerNavn
                         FinnBrukerNavn #Funksjonen inneholder en 'Try' slik at ved eventuelle feil avbrytes det, og bruker får mulighet til å gå tilbake til meny
                         VisFunnetBruker
                            Write-Host "Er dette korrekt bruker? J/N`n"
                            ErDuHeltSikker? #Bruker må velge "j" eller "n"

                    } while ($valg -ne "j") #Utfører følgende så lenge bruker velger at brukernavn er galt
                    try {    
                        Unlock-ADAccount -Identity $brukernavn #Låser opp brukerkonto
                        if ($?) {
                            Write-Host "`n`tBrukeren '$brukernavn' ble låst opp suksessfullt" -Fore Green
                        }
                    }
                    catch { FeilMelding } #Viser feilmelding

                  Prompt_brukerAdministrasjon #Går tilbake til menyen

                } #Lås opp / lås en bruker

                5 { #List ut låste brukere
                    try {#Søker etter alle kontoer som er låst ute og viser dem sortert
                        $Brukere = Search-ADAccount -LockedOut | Sort
                            if ($Brukere) {
                                Write-Host "`t`nFant følgende låste brukere:" -Fore Yellow
                                $Brukere
                            }
                            else { Write-Host "`n`tFant ingen låste brukere" -Fore Green }
                    
                    } Catch { FeilMelding }

                    Prompt_brukerAdministrasjon
                } #List ut låste brukere

                6 { # Aktiver / Deaktiver bruker/gruppe/OU
                                    #Spørr først hva bruker ønsker å gjøre: Aktivere eller deaktivere noe?
                    do {
                        Write-Host "`nHva ønsker du å gjøre:`n" -Fore Cyan
                        Write-Host "`t1. " -NoNewline; Write-Host "Aktiver"   -Fore Cyan
                        Write-Host "`t2. " -NoNewline; Write-Host "Deaktiver" -Fore Cyan
                        $type = Read-Host "`nValg"
                            if ( $type -ne "1" -and $type -ne "2" ) { 
                                Write-Host "`n`tVennligst velg mellom '1' og '2'" -Fore Red
                            }
                    } while ( $type -ne "1" -and $type -ne "2" )
                        
                        #Endrer type slik at den kan brukes i en setning for å vise hva bruker ønsker
                        if ($type -eq "1") { $type = "aktivere" }
                        else { $type = "deaktivere" }

                        #Spørr så hva brukeren ønsker å utføre handlingen på:
                        do {
                            Write-Host "`nHva ønsker du å $type`?`n"                            -Fore Cyan
                            Write-Host "`t1. " -NoNewline; Write-Host "En bruker"               -Fore Cyan
                            Write-Host "`t2. " -NoNewline; Write-Host "En gruppe"               -Fore Cyan
                            Write-Host "`t3. " -NoNewline; Write-Host "En Organizational Unit " -Fore Cyan

                            $valg = Read-Host "`nAlternativ" #Leser brukeres valg av alternativ

                                if ($valg -ne "1" -and #Hvis alternativet ikke er et av
                                    $valg -ne "2" -and #disse får brukeren en feilmld.
                                    $valg -ne "3"
                                   ) { Write-Host "`n`tVennligst velg et av alternativene" -Fore Red }

                        } while ($valg -ne "1" -and #Utføres så lenge et av alternativene
                                 $valg -ne "2" -and #ikke er valgt.
                                 $valg -ne "3"
                                )

                        #Sjekker om bruker ønsker å utføre handling på en bruker
                        if ($valg -eq "1") {
                            do {
                                Write-Host "`nSkriv inn brukernavn på brukeren" -Fore Cyan
                                    do {
                                        SkrivBrukerNavn #Funksjon som lagrer det innskrevne brukernavnet
                                        FinnBrukerNavn  #Finner brukernavn basert på navnet skrevet i funksjonen ovenfor
                                            if ($BrukerFinnes) {
                                                Write-Host "`n`tFant følgende bruker:" -Fore Green
                                                $BrukerFinnes
                                            } else { Write-Host "`n`tFant ingen brukere med brukernavnet '$brukernavn'" -Fore Yellow }
                                    } while ($BrukerFinnes -eq $null)

                                        Write-Host "Er dette korrekt bruker? J/N`n" -Fore Yellow
                                        ErDuHeltSikker? #Bruker må velge "j" eller "n"
                            } while ($script:valg -ne "j")

                            #Dersom bruker har valgt å aktivere en konto
                            if ($type -eq "aktivere") {
                                Write-Host "`nEr du helt sikker på at du ønsker og aktivere brukeren '$brukernavn'?`n" -Fore Yellow
                                ErDuHeltSikker? #Bruker må velge "j" eller "n"

                                    if ($script:valg -eq "j") { #Dersom det er svart 'j' for ja:
                                        Enable-ADAccount -Identity $brukernavn #Utfører aktivering av konto på valgt brukernavn

                                            #Gir tilbakemelding på om forrige kommando ble utført suksessfullt.
                                            if ($?) { Write-Host "`n`tBrukeren '$brukernavn' ble aktivert" -Fore Green }

                                    } #Dersom det velges 'n' for nei:
                                    else { Reload_brukerAdministrasjon } #Reloader brukermenyen
                            } 
                            else { #Dersom bruker IKKE ønsker å aktivere en konto, men heller deaktivere en:
                                Write-Host "`nEr du helt sikker på at du ønsker og deaktivere brukeren '$brukernavn'?`n" -Fore Yellow
                                ErDuHeltSikker? #Bruker må velge "j" eller "n"

                                    if ($script:valg -eq "j") {
                                        Disable-ADAccount -Identity $brukernavn #Utfører DEaktivering av konto på valgt brukernavn
                                            if ($?) { Write-Host "`n`tBrukeren '$brukernavn' ble deaktivert" -Fore Green }
                                    }
                                    else { Reload_brukerAdministrasjon } #Går tilbake til brukermenyen
                            }
                        }#/Slutt kode for håntering dersom bruker er valgt

                        #Sjekker om bruker ønsker å utføre handling på en gruppe
                        if ($valg -eq "2") {
                            do {
                                Write-Host "`nHvilken gruppe ønsker du å $type`?" -Fore Cyan
                                    do {
                                        SkrivGruppeNavn #Bruker må skrive navn på gruppa
                                        FinnGruppe #Funksjon som søker etter gruppa og lagrer den i en variabel
                                            if ($GruppeFinnes) { #Sjekker om det eksisterer noe i variabelen
                                                $GruppeFinnes #Viser gruppa, hvis variabelen ikke er tom
                                            } else { Write-Host "Fant ingen gruppe med navn '$gruppeNavn'" -Fore Yellow }
                                    } while ($GruppeFinnes -eq $null) #Utføres så lenge funksjonen ikke finner en gruppe
                                        
                                        Write-Host "Er dette korrekt bruker? J/N`n" -Fore Yellow
                                        ErDuHeltSikker? #Bruker må velge "j" eller "n"
                            } while ($script:valg -ne "j")
                            
                                FinnDistinguishedNameGruppe #Henter distingusihedname som skal brukes til path senere

                                Write-Host "" #Lager mellomrom mellom svaret til bruker og output på skjerm.

                                Function DeaktiverBrukereiGruppe {
                                    #Henter alle gruppemedlemmer fra pathen DistinguishedName
                                    Get-ADGroupMember -Identity $DistinguishedName |
                                        ForEach-Object {
                                            $bruker = $_.SamAccountName
                                            Get-ADUser -Identity $bruker | Disable-ADAccount
                                                if ($?) { Write-Host "Bruker '$bruker' ble deaktivert" -Fore Green }
                                        }
                                }

                                #Må ha to ulike funksjoner i stedet for en funksjon som tar parameter.
                                #Det går ikke å legge til en variabel som første parameter etter piping
                                #Det vil si at 'kode | $variabel' ikke er tillat
                                #men derimot   'kode | -parameter' er tillat
                                Function AktiverBrukereiGruppe {
                                    #Henter alle gruppemedlemmer fra pathen DistinguishedName
                                    Get-ADGroupMember -Identity $DistinguishedName |
                                        ForEach-Object {
                                            $bruker = $_.SamAccountName
                                            Get-ADUser -Identity $bruker | Enable-ADAccount #Aktiverer konto
                                                if ($?) { Write-Host "Bruker '$bruker' ble aktivert" -Fore Green }
                                        }
                                }

                                #Utfører aktivering eller deaktiver alt ettersom hva som ble valgt
                                if ($type -eq "deaktivere") {
                                    DeaktiverBrukereiGruppe
                                }
                                else { 
                                    AktiverBrukereiGruppe
                                }
                        }#/Slutt kode for håntering dersom gruppe er valgt

                        #Sjekker om bruker ønsker å utføre handling på et OU
                        if ($valg -eq "3") {
                            do {
                                Write-Host "`nHvilken Organizational Unit ønsker du å $type`?" -Fore Cyan
                                do {
                                    SkrivNavnOU #Funksjon som lagrer det innskrevne OU'et
                                    FinnOrganizationalUnit #Finner OU basert på navnet skrevet i funksjonen ovenfor
                                        if ($script:OU) {
                                            $script:OU #Viser info om OU
                                        } else { Write-Host "`n`tFant ingen OU med navn '$navnOU'" -Fore Yellow }
                                    } while ($script:OU -eq $null)

                                        Write-Host "Er dette korrekt bruker? J/N`n" -Fore Yellow
                                        ErDuHeltSikker? #Bruker må velge "j" eller "n"

                            } while ($script:valg -ne "j")

                                Write-Host "" #Lager mellomrom mellom svar og output

                                FinnDistinguishedNameOU

                                #Funksjon for å aktivere brukere i OU
                                Function AktiverBrukereiOrganizationalUnit {
                                    $AlleBrukerne = Get-ADUser -Filter * -SearchBase $DistinguishedName
                                        Foreach ($bruker in $AlleBrukerne) {
                                            Get-ADUser -Identity $bruker | Enable-ADAccount
                                                if ($?) { Write-Host "Aktiverte $bruker" -Fore Green }
                                            }
                                }

                                #Funksjon for å DEaktivere brukere i OU
                                Function DeaktiverBrukereiOrganizationalUnit {
                                    $AlleBrukerne = Get-ADUser -Filter * -SearchBase $DistinguishedName
                                        Foreach ($bruker in $AlleBrukerne) {
                                            Get-ADUser -Identity $bruker | Disable-ADAccount
                                                if ($?) { Write-Host "Deaktiverte $bruker" -Fore Green }
                                            }
                                }
                                

                                #Utfører aktivering eller deaktiver alt ettersom hva som ble valgt
                                if ($type -eq "deaktivere") { DeaktiverBrukereiOrganizationalUnit } 
                                else { AktiverBrukereiOrganizationalUnit }

                        }#/Slutt kode for håntering dersom OU er valgt


                    Prompt_brukerAdministrasjon
                
                } #Aktiver / Deaktiver en bruker/gruppe/OU

                7 { # Vis alle aktiverte / deaktiverte brukere
                    do {
                        Write-Host "`nHvilken type ønsker du å vise:`n" -Fore Cyan
                        Write-Host "`t1. " -NoNewline; Write-Host "Aktiverte brukere" -Fore Cyan
                        Write-Host "`t2. " -NoNewline; Write-Host "Deaktiverte brukere" -Fore Cyan

                        $valg = Read-Host "`nType"
                            if ( $valg -ne "1" -and $valg -ne "2" ) { 
                                Write-Host "`n`tVennligst velg mellom '1' og '2'" -Fore Red
                            }
                    } while ($valg -ne "1" -and $valg -ne "2")
                    
                     try {
                        if ($valg -eq "1") {

                            #Lagrer alle brukere sortert etter navn i en variabel.
                            #'FT er alias for 'Format'Table' og 'Sort' for 'Sort-Object'
                            $AktiverteBrukere = Get-ADUser -Filter {enabled -eq $true} | Sort | 
                            Select Name,SamAccountName,UserPrincipalName,DistinguishedName | FT

                            if ($AktiverteBrukere) { #Utfører en sjekk om det finnes noe i variabelen
                                Write-Host "`n`tFant følgende brukere:" -Fore Green
                                $AktiverteBrukere
                            }
                            else { Write-Host "`n`tFant ingen aktiverte brukere" -Fore Yellow }
                         }
                         else {
                            #Lagrer brukerne sortert etter navn i en variabel.
                            $deaktiverteBrukere = Search-ADAccount -AccountDisabled -UsersOnly | Sort |
                            Select Name,SamAccountName,UserPrincipalName,DistinguishedName | 
                            FT 

                            if ($deaktiverteBrukere) { #Utfører en sjekk om det finnes noe i variabelen
                                Write-Host "`n`tFant følgende brukere:" -Fore Green
                                $deaktiverteBrukere
                            }
                            else { Write-Host "`n`tFant ingen deaktiverte brukere" -Fore Yellow }
                         }
                     } catch { FeilMelding} #Viser feilmelding

                    Prompt_brukerAdministrasjon

                } #List ut alle aktiverte / deaktiverte brukere

                8 { # List ut alle deaktiverte maskiner
                    try { #Kode for å søke etter maskiner, formaterer eventuel output
                        $kontoer = Search-ADAccount -AccountDisabled -ComputersOnly | Sort |
                        FT Name,SamAccountName,ObjectClass
                            if ($kontoer) { #Dersom det finnes noe i variabelen betyr det at det finnes kontoer.
                                Write-Host "`nFølgende deaktiverte maskiner ble funnet:" -Fore Yellow
                                $kontoer #Viser maskinene
                            }
                            else { Write-Host "`n`tFant ingen deaktiverte maskiner" -Fore Green }
                    }
                    catch { FeilMelding } #Viser feilmelding

                  Prompt_brukerAdministrasjon #Går tilbake til meny

                } #List ut deaktiverte maskiner

                9 { # List ut alle brukerkontoer som er inaktive
                    try {#Lagrer inaktive kontoer i en variabel, sortert.
                        $inaktiveKontoer = Search-ADAccount -AccountInactive | Sort | 
                        FT Name,SamAccountName,ObjectClass

                        if ($inaktiveKontoer) {
                            Write-Host "`nFølgende brukerkontoer er inaktive:" -Fore Yellow
                            $inaktiveKontoer
                        }
                        else { Write-Host "`n`tFant ingen inaktive kontoer" -Fore Green }
                    }
                    catch { FeilMelding } #Viser eventuell feilmelding

                  Prompt_brukerAdministrasjon

                } #List ut inaktive brukerkontoer

                10 { # Søk etter brukere ved hjelp av
                    do {
                        Write-Host "`nHva ønsker du å bruke i søket?`n"        -Fore Cyan
                        Write-Host "`t1. " -NoNewline; Write-Host "Fornavn"    -Fore Cyan
                        Write-Host "`t2. " -NoNewline; Write-Host "Etternavn"  -Fore Cyan
                        Write-Host "`t3. " -NoNewline; Write-Host "Fullt navn" -Fore Cyan
                        Write-Host "`t4. " -NoNewline; Write-Host "Brukernavn" -Fore Cyan
                        Write-Host "`t5. " -NoNewline; Write-Host "E-post"     -Fore Cyan
                        
                        $valg = Read-Host "`nAlternativ" #Leser brukeres valg av alternativ

                            if ( $valg -ne "1" -and #Hvis alternativet ikke er likt et
                                 $valg -ne "2" -and #av disse får brukeren en feilmld.
                                 $valg -ne "3" -and
                                 $valg -ne "4" -and
                                 $valg -ne "5"
                               ) { Write-Host "`n`tVennligst velg et av alternativene" -Fore Red }

                    } while ( $valg -ne "1" -and #Utføres så lenge et av alternativene
                              $valg -ne "2" -and #ikke er valgt.
                              $valg -ne "3" -and
                              $valg -ne "4" -and
                              $valg -ne "5"
                            )

                    #For å minske kode brukes følgende funksjon for å hente hente spesifiserte egenskaper
                    #sortere dem i alfabetisk rekkefølge og formatere outputen.
                    function FantFolgendeBrukere {
                        Write-Host "`n`tFant følgende brukere:`n" -Fore Green
                        $bruker | Select Name,SamAccountName,UserPrincipalName,DistinguishedName | Sort | FT 
                    }

                    if ($valg -eq "1") { #Hvis 1 er valgt
                        SkrivFornavn
                        try {
                            $Bruker = Get-ADUser -Filter "GivenName -like '*$fornavn*'"

                                if ($bruker) {
                                    FantFolgendeBrukere
                                }
                                else { Write-Host "`n`tFant ingen brukere med fornavn '$fornavn'" -Fore Yellow }

                        } catch { FeilMelding } #Viser eventuell feilmelding
                    } #Fornavn

                    if ($valg -eq "2") { #Hvis 2 er valgt
                        SkrivEtternavn
                        try {
                            $bruker = Get-ADUser -Filter "surname -like '*$etternavn*'"

                            if ($bruker) {
                                FantFolgendeBrukere
                            }
                            else { Write-Host "`n`tFant ingen brukere med etternavn '$etternavn'" -Fore Yellow }

                        } catch { FeilMelding }
                    } #Etternavn

                    if ($valg -eq "3") { #Hvis 3 er valgt
                        SkrivFornavn
                        SkrivEtternavn

                        $fulltNavn = "$fornavn $etternavn"
                            try {
                                $bruker = Get-ADUser -Filter "Name -like '*$fulltNavn*'"

                                if ($bruker) {
                                    FantFolgendeBrukere
                                }
                                else { Write-Host "`n`tFant ingen brukere med navn '$fulltNavn'" -Fore Yellow }

                            } catch { WFeilMelding }
                    } #Fullt navn

                    if ($valg -eq "4") { #Hvis 4 er valgt
                        SkrivBrukerNavn
                            try {
                                $bruker = Get-ADUser -Filter "SamAccountName -like '*$brukernavn*'"

                                if ($bruker) {
                                    FantFolgendeBrukere
                                }
                                else { Write-Host "`n`tFant ingen brukere som matcher '$brukernavn'" -Fore Yellow }

                        } catch { FeilMelding }
                    } #/Brukernavn
                    
                    if ($valg -eq "5") { #Hvis5 er valgt
                        do {
                            $epost = Read-Host "`nE-post"
                                if ($epost -eq "") { Write-Host "`n`tE-posten kan ikke være blank" -Fore Red }

                        } while ( $epost -eq "")

                        try {
                            $bruker = Get-ADUser -Filter "EmailAddress -like '*$epost*'"
                            if ($bruker) {
                                FantFolgendeBrukere
                            }
                                else { Write-Host "`n`tFant ingen brukere med e-post som matcher '$epost'" -Fore Yellow }
                        } catch { FeilMelding }
                    } #/E-post

                    Prompt_brukerAdministrasjon

                } #Søk etter brukere ved hjelp av

                11 { # Tilbakestill passord for bruker
                    SkrivBrukerNavn
                    FinnBrukerNavn
                    VisFunnetBruker
                        Write-Host "Er du helt sikker på at du ønsker å tilbakestille passordet? J/N`n" -Fore Yellow
                        ErDuHeltSikker? #Bruker må velge "j" eller "n"

                    if ($valg -eq "j") {
                    Write-Host ""
                        Set-ADAccountPassword $brukernavn -NewPassword (Read-Host -AsSecureString "`nSkriv inn det nye passordet") –Reset
                            if ($?) {
                                Write-Host "`n`tPassordet ble tilbakestilt suksessfullt" -Fore Green
                                Prompt_brukerAdministrasjon
                            }
                    }
                    else { Reload_brukerAdministrasjon }

                } #Tilbakestill passord for bruker

                12 { # Vis brukere som har konto som utløper i løpet av 'x' dager
                    
                    SkrivInnAntallDager #Får bruker til å skrive inn et tall

                    #Legger til tallet slik at variabelen kan brukes som TimeSpan.
                    $AntallDager = $Antall+".00:00:00" 

                    try { #Søker etter alle brukere som har konto som utløper innen dager spesifisert.
                        $brukere = Search-ADAccount -AccountExpiring -TimeSpan $AntallDager | Sort | Select `
                        -Property AccountExpirationDate,SamAccountName,ObjectClass,DistinguishedName | FT 

                            if ($Brukere) { #Sjekker om det eksisterer noen brukere
                                Write-Host "`nFølgende brukere har konto som utløper i løpet av $Antall dager`n" -Fore Yellow
                                $Brukere

                            } else {Write-Host "`n`tFant ingen brukere med konto som utløper i løpet av $Antall dager" -Fore Green}
                    }
                    catch { FeilMelding }

                  Prompt_brukerAdministrasjon

                #Search-ADAccount -AccountExpiring -TimeSpan 6.00:00:00 | FT Name,ObjectClass -A
                } #Vis brukere som har konto som utløper om 'x' dager

                13 { #Vis brukere har passord som utløper etter x dager
			         #ut ifra standard passord policy
                    try {$AntallDager = (Get-ADDefaultDomainPasswordPolicy).MaxPasswordAge.Days} catch { FeilMelding }

                    HentDefaultPassordPolicy #Funksjon som viser den Defaulte passord policyen på server.

                    try {
                        Write-Host "Følgende brukere har passord som utløper om $AntallDager dager" -Fore Cyan
                        #Kode som henter alle brukere som har passord som utløper. Viser brukernavn og utløpsdato.
                        #Kode er hentet av leksjoner i faget PowerShell og skrevet av Stein Meisingseth v/ NTNU 
                        
                        Get-ADUser -filter {enabled -eq $true -and PasswordNeverExpires -eq $false} `
                        -Properties * | Sort | Select -Property "SamAccountName", @{name="Utløpsdato"`
                        ;Expression={$_.PasswordLastSet.AddDays($dager)}} |
                        where {$_.Utløpsdato -ne $null} | FT 
                    }
                    catch { FeilMelding } #Viser feilmelding om det kommer en.

                  Prompt_brukerAdministrasjon #Trykk 'enter' for å gå tilbake. Gir bruker tid til å lese output.
                } #Vis brukere har passord som utløper etter x dager ut ifra standard passord policy

                14 { #Deaktiver alle brukere eldre enn 'x' dager
                    SkrivInnAntallDager

                    do {
                        Write-Host "`nEr du helt sikker på at du ønsker å deaktivere alle brukere eldre enn $Antall dager?" -Fore Red
                        Write-Host "Dette kan deaktivere Administrator-kontoen og." -Fore Red
                        ErDuHeltSikker?
                    } while ($valg -ne "j" -and $valg -ne "n")

                    if ($valg -eq "j") {
                        try {
                            #Kilde: https://social.technet.microsoft.com/Forums/systemcenter/en-US/f72e883c-8792-4b64-88fb-31dbec232862/powershell-command-to-disable-user-account-older-then-90-days?forum=winserverDS
                            
                            #'?' er alias for 'Where-Object'
                            Get-ADUser -Filter '*' -Properties '*' | 
                            ? {$_.PasswordNeverExpires -eq 'False' -and `
                            $_.whenCreated -le (Get-Date -Date (Get-Date).AddDays(-$Antall))} | Disable-ADAccount
                                if ($?) {

                                    #Siden Administratorkontoen deaktiveres også, aktiveres den her.
                                    #Hvis den ikke aktiveres kan det IKKE opprettes session via PowerShell til Serveren.
                                    Get-ADUser -Filter "samaccountname -eq 'administrator'" | Enable-ADAccount

                                    Write-Host "`n`tKommandoen ble suksessfullt utført" -Fore Green

                                    #Søker og viser en oversikt over alle deaktiverte kontoer
                                    Search-ADAccount -AccountDisabled | Sort | Select -Property `
                                    DistinguishedName,ObjectClass,Enabled,SamAccountName | FT 
                                }
                        } catch { FeilMelding }
                    }
                    else { Reload_brukerAdministrasjon } #Laster inn menyen med en gang

                    Prompt_brukerAdministrasjon

                } #Deaktiver alle brukere eldre enn 'x' dager

                15 { #Legg til profil/logonscript til brukere i en gruppe

                #Referanse: https://blogs.technet.microsoft.com/heyscriptingguy/2013/08/14/use-powershell-to-change-sign-in-script-and-profile-path/

                    #Funksjon som viser filer i NETLOGON mappa på domenet
                    function VisInnholdNETLOGON {
                        Get-ChildItem -Path "\\$domene\NETLOGON\"
                    }

                    function SpesifiserGruppeOU {
                        do {
                            Write-Host "`nVelg hvem endringen skal gjelde for:`n"           -Fore Cyan
                            Write-Host "`t1. " -NoNewline; Write-Host "Gruppe"              -Fore Cyan
                            Write-Host "`t2. " -NoNewline; Write-Host "Organizational Unit" -Fore Cyan
                            #Oppretter en variabel med scope script slik at den kan endres av andre scope.
                            $script:GruppeOU = Read-Host "`nAlternativ" #Leser brukeres valg av alternativ
                                if ( $script:GruppeOU -ne "1" -and $script:GruppeOU -ne "2" ) 
                                    { Write-Host "`n`tVennligst velg et av alternativene"   -Fore Red }
                        #Utføres så lenge et av alternativene ikke er valgt.
                        } while ( $script:GruppeOU -ne "1" -and $script:GruppeOU -ne "2" )
                    }

                    function FinnDistinguishedName {
                    #Dersom bruker ønsker å legge til i en gruppe:
                        if ($GruppeOU -eq "1") {
                            do {
                                do {#Skriv inn gruppenavn
                                    SkrivGruppeNavn
                                    FinnGruppe #Søker etter gruppe og legger resultat i en variabel
                                        if ($GruppeFinnes) { #Dersom variabelen eksisterer finnes det en gruppe
                                            $GruppeFinnes
                                        } else { Write-Host "`nFant ikke gruppa '$gruppeNavn'" -Fore Yellow }
                                } while ($GruppeFinnes -eq $null)

                                Write-Host "`nEr dette rett gruppe? J/N" -Fore Cyan
                                ErDuHeltSikker? #Funksjon som retunerer 'j' for ja eller 'n' for nei
                                FinnDistinguishedNameGruppe #Finner distinugishedname på gruppe hvis den er korrekt
                            } while ($script:valg -ne "j") #Utføres så lenge bruker ikke velger 'j' for ja
                        }
                        else { #Dersom bruker ønsker å legge til script i OU:
                            do {
                                do { #Skriv inn navn på OU'et
                                    SkrivNavnOU
                                    FinnOrganizationalUnit #Søker etter OU'et
                                        if ($OU) {
                                            $OU
                                        } else { Write-Host "`nFant ikke OU'et '$navnOU'" -Fore Yellow }
                                } while ($OU -eq $null)

                                Write-Host "`nEr dette rett organizational unit? J/N" -Fore Cyan
                                ErDuHeltSikker? #Funksjon som retunerer 'j' for ja eller 'n' for nei
                                FinnDistinguishedNameOU
                            } while ($script:valg -ne "j") #Utføres så lenge bruker ikke skriver 'j'
                        }
                    } #/FinnDistinguishedName

                    #Funksjon som legger til Profil script til hver bruker i pathen spesifisert i DistinguishedName
                    function LeggTilProfilScriptiOU {
                        Get-ADUser -Filter * -SearchBase $DistinguishedName -Properties $properties |
                        ForEach-Object { #For hver eneste bruker i pathen som ligger i DistinguishedName:
                            # Koden under legger til brukernavn foran variabelen.
                            # Det kan hardkodes en sti som har brukernavn inni seg og.
                            # Det kan se f.eks slik ut: petter\\domene.no\netlogon\profil.ps1

                            #NY variabel = (path)                henter brukernavn
                            #$ProfilPath = “{0}$ProfilScript" -f $_.SamAccountName
                            # Så brukes $ProfilPath til å settes bak -ProfilePath kommandoen under
                            
                            #Kode som endrer profilepath til hver bruker:
                            Set-ADUser -Identity $_.SamAccountName -ProfilePath $ProfilScript
                            $bruker = $_.SamAccountName
                            Write-Host "Scriptprofil '$script:ProfilScript' ble lagt til brukernavn $bruker" -Fore Green
                        }
                    }

                    #Funksjon som legger til Logon script til hver bruker i pathen spesifisert i DistinguishedName
                    function LeggTilLogonScriptiOU {
                        Get-ADUser -Filter * -SearchBase $DistinguishedName -Properties $properties |
                        ForEach-Object { #For hver eneste bruker i pathen som ligger i DistinguishedName:
                            # Koden under legger til brukernavn foran variabelen.
                            # Det kan hardkodes en sti som har brukernavn inni seg og.
                            # Det kan se f.eks slik ut: petter\\domene.no\netlogon\netlogon.ps1

                            #NY variabel = sti                henter brukernavn
                            #$ScriptPath = “{0}$LogonPath" -f $_.SamAccountName
                            # Så brukes $ScriptPath til å settes bak -ScriptPath kommandoen under
                            
                            #Kode som endrer profilepath til hver bruker:
                            Set-ADUser -Identity $_.SamAccountName -ScriptPath $LogonPath
                            $bruker = $_.SamAccountName
                            Write-Host "LogonScript '$script:LogonPath' ble lagt til brukernavn $bruker" -Fore Green
                        }
                    }

                    #PowerShell finner ingen brukere i en gruppe dersom koden [Get-ADUser -Filter * -SearchBase 'navnGruppe'] kjøres.
                    #Dersom må det brukes to andre funksjoner
                    #Først hentes alle gruppemedlemmene fra valgt DistinguishedName
                    #før det for hvert objekt legges til path til brukernavn.

                    function LeggTilProfilScriptiGruppe {
                        Get-ADGroupMember -Identity $script:DistinguishedName |
                            ForEach-Object {
                                Set-ADUser -Identity $_.SamAccountName -ProfilePath $script:ProfilScript
                                $bruker = $_.SamAccountName
                                Write-Host "Scriptprofil '$script:ProfilScript' ble lagt til brukernavn $bruker" -Fore Green
                            }
                    }

                    function LeggTilLogonScriptiGruppe {
                        Get-ADGroupMember -Identity $script:DistinguishedName |
                            ForEach-Object {
                                Set-ADUser -Identity $_.SamAccountName -ScriptPath $script:LogonPath
                                $bruker = $_.SamAccountName
                                Write-Host "LogonScript '$script:LogonPath' ble lagt til brukernavn $bruker" -Fore Green
                            }
                    }

                    #Ønsker bruker å legge til profil/logon eller begge deler?
                    do {
                        Write-Host "`nHva ønsker du å legge til?`n"                    -Fore Cyan
                        Write-Host "`t1. " -NoNewline; Write-Host "Profil script"      -Fore Cyan
                        Write-Host "`t2. " -NoNewline; Write-Host "Logon script"       -Fore Cyan
                        Write-Host "`t3. " -NoNewline; Write-Host "Jatakk begge deler" -Fore Cyan
                        
                        $valg = Read-Host "`nAlternativ" #Leser brukeres valg av alternativ

                            if ( $valg -ne "1" -and #Hvis alternativet ikke er likt et
                                 $valg -ne "2" -and #av disse får brukeren en feilmld.
                                 $valg -ne "3"
                               ) { Write-Host "`n`tVennligst velg et av alternativene" -Fore Red }
                    #Utføres så lenge et av alternativene ikke er valgt.
                    } 
                    while (  $valg -ne "1" -and 
                             $valg -ne "2" -and
                             $valg -ne "3"
                          )
                    
                    #Dersom profilscript er valgt:
                    if ($valg -eq "1") {
                        $properties = “ProfilePath”
                        VisInnholdNETLOGON
                        skriv_gyldig_path_til_fil; $script:ProfilScript = $path #Må endre varabel navn
                        SpesifiserGruppeOU
                        FinnDistinguishedName
                            Write-Host "`nEr du helt sikker på at du ønsker å legge til profilscript?" -Fore Yellow
                            #Funksjon som retunerer j eller n. Legger til et mellomrom under linja.
                            ErDuHeltSikker?; Write-Host ""
                                if ($script:valg -eq "j") { #Dersom det ikke brukes script her blir ikke valget lest korrekt.
                                    if ($GruppeOU -eq "1") { #Dersom det er valgt gruppe:
                                        try { #koden får å legge til pathen i en gruppe er annerledes enn i et OU.
                                            LeggTilProfilScriptiGruppe
                                            BleDetSuksess? #sjekker om koden ble utført suksessfullt.
                                        } catch { FeilMelding } #Henter feilmelding
                                    } #Hvis det ikke er valgt en gruppe, må det være valgt et OU.
                                    else { 
                                        try {
                                            LeggTilProfilScriptiOU #Kode som legger til scriptpath i OU'er
                                            BleDetSuksess?
                                            FeedbackProfilScript #Gir til feedback til bruker 
                                        } catch { FeilMelding }
                                    }
                                    
                                }
                                else { Reload_brukerAdministrasjon }
                    }#/2

                    #Dersom logonscript er valgt:
                    if ($valg -eq "2") {
                        $properties = “ScriptPath”
                        VisInnholdNETLOGON
                        skriv_gyldig_path_til_fil; $script:LogonPath = $path #Må endre varabel navn
                        SpesifiserGruppeOU
                        FinnDistinguishedName
                            Write-Host "`nEr du helt sikker på at du ønsker å legge til Logon script" -Fore Yellow
                            #Funksjon som retunerer j eller n. Legger til et mellomrom under linja.
                            ErDuHeltSikker?; Write-Host ""
                                if ($script:valg -eq "j") { #Sjekker om bruker har valgt ja.
                                    if ($GruppeOU -eq "1") { #Dersom det er valgt gruppe:
                                        try { #koden får å legge til pathen i en gruppe er annerledes enn i et OU.
                                            LeggTilLogonScriptiGruppe
                                            BleDetSuksess? #sjekker om koden ble utført suksessfullt.
                                        } catch { FeilMelding } #Henter feilmelding
                                    } #Hvis det ikke er valgt en gruppe, må det være valgt et OU.
                                    else { 
                                        try {
                                            LeggTilLogonScriptiOU #Kode som legger til scriptpath i OU'er
                                            BleDetSuksess?
                                            FeedbackLogonScript #Gir til feedback til bruker 
                                        } catch { FeilMelding }
                                    }
                                } else { Reload_brukerAdministrasjon }
                    }#/2

                    #Dersom bruker ønsker å legge til profil og Logon script
                    if ($valg -eq "3") {
                        $properties = “ProfilePath”,”ScriptPath”
                        VisInnholdNETLOGON #Viser alle filene i stien \\domenenavn\NETLOGON\
                        Write-Host "`nHvor finnes " -NoNewline -Fore Cyan
                        Write-Host "profilscriptet" -NoNewline -Fore Yellow
                        Write-Host " ?" -Fore Cyan
                        skriv_gyldig_path_til_fil; $script:ProfilScript = $path #Må endre varabelnavn for å skille de to Pathene
                        Write-Host "`nHvor finnes " -NoNewline -Fore Cyan
                        Write-Host "logonscriptet"  -NoNewline -Fore Yellow
                        Write-Host " ?" -Fore Cyan
                        skriv_gyldig_path_til_fil; $script:LogonPath = $path #Må endre varabelnavn for å skille de to Pathene
                        
                        SpesifiserGruppeOU
                        FinnDistinguishedName
                            Write-Host "`nEr du helt sikker på at du ønsker å legge til profil og logonscript?" -Fore Yellow
                            #Funksjon som retunerer j eller n. Legger til et mellomrom under linja.
                            ErDuHeltSikker?; Write-Host ""
                                if ($script:valg -eq "j") {
                                    if ($GruppeOU -eq "1") { #Dersom det er valgt gruppe:
                                        try { #koden får å legge til pathen i en gruppe er annerledes enn i et OU.
                                            LeggTilProfilScriptiGruppe; Write-Host "" #Legger til mellomrom under
                                            LeggTilLogonScriptiGruppe
                                            BleDetSuksess?      #sjekker om koden ble utført suksessfullt.
                                        } catch { FeilMelding } #Henter feilmelding
                                    } 
                                    else { #Hvis det ikke er valgt en gruppe, må det være valgt et OU.
                                        try { #Kode som legger til scriptpath i OU'er
                                            LeggTilProfilScriptiOU; Write-Host "" #Legger til mellomrom under
                                            LeggTilLogonScriptiOU  #Kode som legger til scriptpath i OU'er
                                            BleDetSuksess?         #sjekker om koden ble utført suksessfullt.
                                        } catch { FeilMelding }
                                    }
                                } else { Reload_brukerAdministrasjon }
                    }#/3

                    Prompt_brukerAdministrasjon
                } #Legg til profil/logonscript til brukere i en gruppe/ou

                16 { # Vis hvilke grupper en bruker tilhører
                    SkrivBrukerNavn #Bruker skriver inn brukernavn
                    FinnBrukerNavn  #Det søkes etter brukeren, hvis den ikke finnes kommer det en feilmelding.
                    VisFunnetBruker #Viser brukeren
                        if ($BrukerFinnes) { #Hvis det eksisterer en bruker listes det ut hvilke grupper brukeren er medlem av.
                            Write-Host "Brukeren er medlem av følgende grupper:" -Fore Yellow
                            Get-ADPrincipalGroupMembership $brukernavn | Select-Object Name,GroupScope,GroupCategory | FT
                        }
                    Prompt_brukerAdministrasjon #Trykk 'enter' for å gå tilbake til meny
                } #Slutt 15 - Vis hvilke grupper en bruker tilhører

                17 { # Vis historie for gruppemedlemsskap for en bruker
                    SkrivBrukerNavn #Skriv inn brukernavnet som skal listes ut
                    FinnBrukerNavn
                    VisFunnetBruker

                    $brukerOBJ = Get-ADUser $brukernavn
                    if ($BrukerFinnes) {
                        Write-Host "Følgende grupper er registrerte på brukeren:" -Fore Yellow

                     #Kilde: https://www.youtube.com/watch?v=d90gD2xhrl4
                     #'?' er alias for 'Where-Object'
                        Get-ADUser $brukerOBJ.distinguishedname -Properties memberOf |
                        Select-Object -ExpandProperty memberof |
                        ForEach-Object {
                            Get-ADReplicationAttributeMetadata $_ -Server localhost -ShowAllLinkedValues |
                            ? {
                                $_.attributename -eq 'member' -and
                                $_.attributevalue -eq $brukerOBJ.distinguishedname
                            } | Select-Object #FirstOriginatingCreateTime, Object, AttributeValue
                        } | Sort FirstOriginatingCreateTime -Descending | FT -Property FirstOriginatingCreateTime, Object, AttributeValue
                    }
                    Prompt_brukerAdministrasjon #Trykk 'enter' for å gå tilbake til meny

                } #Slutt 16 - Vis historie for gruppemedlemsskap

                18 { LastInnMeny } #Laster inn hovedmeny
			}

        } #brukeradministrasjon

        brukeradministrasjon #Kaller på funksjonen

		} #Slutt menyalternativ 4 - Brukeradministrasjon

        5  { #Menyalternativ 5 - 'Gruppeadministrasjon'
        
        function prompt_meny_gruppe_admin() {
            Read-Host "`nTrykk 'enter' for å gå tilbake"
            $MenyGrupper = 0
            meny_gruppe_administrasjon
        }

        Function Reload_meny_gruppe_admin {
            $MenyGrupper = 0
            meny_gruppe_administrasjon
        }

        function VisFunnetGruppe() {
            if ($script:GruppeFinnes) {
                Write-Host "`n`tFant følgende gruppe:`n" -Fore Green
                $script:GruppeFinnes
            }
            else {
                Write-Host "`n`tFant ikke gruppe med navn '$script:gruppeNavn'" -Fore Yellow
                prompt_meny_gruppe_admin
                }
        }#/VisFunnetGruppe
        
        function Spesifiser_gruppeScope() {
            do {
                Write-Host "`nSpesifiser gruppe scope:`n" -Fore Cyan
                Write-Host "`t1. "             -NoNewline
                Write-Host "Lokal"                        -Fore Cyan
                Write-Host "`t2. "             -NoNewline
                Write-Host "Global"                       -Fore Cyan
                Write-Host "`t3. "             -NoNewline
                Write-Host "Universal"                    -Fore Cyan
                $script:gruppeScope = Read-Host "`nScope"
                    if ( $script:gruppeScope -ne "1" -and `
                         $script:gruppeScope -ne "2" -and `
                         $script:gruppeScope -ne "3" 
                         ) { 
                        Write-Host "`n`tUgyldig verdi"    -Fore Red
                        }
            } while ($script:gruppeScope -ne "1" -and $script:gruppeScope -ne "2" -and $script:gruppeScope -ne "3")

                if ($script:gruppeScope -eq "1") { $script:gruppeScope = "DomainLocal" }
                if ($script:gruppeScope -eq "2") { $script:gruppeScope = "Global"      }
                if ($script:gruppeScope -eq "3") { $script:gruppeScope = "Universal"   }
        }#/Spesifiser_gruppeScope

        function Spesifiser_gruppeKategori() {
            do {
                Write-Host "`nSpesifiser gruppekategori:`n" -Fore Cyan
                Write-Host "`t1. "             -NoNewline
                Write-Host "Security"                     -Fore Cyan
                Write-Host "`t2. "             -NoNewline
                Write-Host "Distribution"                 -Fore Cyan
                $script:gruppeKategori = Read-Host "`nGruppekategori"
                    if ( $script:gruppeKategori -ne "1" -and $script:gruppeKategori -ne "2" ) { 
                        Write-Host "`n`tUgyldig verdi" -Fore Red
                        }
            } while ($script:gruppeKategori -ne "1" -and $script:gruppeKategori -ne "2")

                if ($script:gruppeKategori -eq "1") { $script:gruppeKategori = "Security" }
                else { $script:gruppeKategori = "Distribution" }
        }#/Spesifiser_gruppeKategori

        function Search_AD_Group() {
            [string] $gruppeSti = Get-ADGroup -Filter "Name -eq '$gruppeNavn'" | Select-Object -Property DistinguishedName
            [string] $script:nyGruppeSti = $gruppeSti -replace "@{distinguishedname=" -replace "}"
            Write-Host "`n`tSti: " -NoNewline -Fore Green
            Write-Host "$script:nyGruppeSti"
        }


      function meny_gruppe_administrasjon {

            [int] $AntallMenyAlternativer = 11 #Antall alternativer i undermenyen
         [string] $sti                    = "Hovedmeny / Gruppeadministrasjon /"
         [string] $t                      =  "`t`t`t`t" #For hver '`t' lages det litt mellomrom

			while ( $MenyGrupper -lt 1 -or $MenyGrupper -gt $AntallMenyAlternativer ) {
				Clear-Host
				Write-Host " $appNavn "                                         -Fore Magenta
                Write-Host "`tDu står i:"                            -NoNewline -Fore Cyan
                Write-Host " $sti`n"
				Write-Host "`t`tVelg mellom følgende administrative oppgaver`n" -Fore Cyan
                Write-Host "`t`t`t1. Opprett en gruppe"                         -Fore Cyan
                    Write-Host "$t`Navn: "         -NoNewline -Fore Cyan; Write-Host "(Krever input)"
                    Write-Host "$t`Scope: "        -NoNewline -Fore Cyan; Write-Host "(Lokal"    -NoNewline
                    Write-Host ", "                -NoNewline -Fore Cyan; Write-Host "global"    -NoNewline
                    Write-Host " eller "           -NoNewline -Fore Cyan; Write-Host "universal)"
                    Write-Host "$t`Kategori: "     -NoNewline -Fore Cyan; Write-Host "(Security" -NoNewline
                    Write-Host " eller "           -NoNewline -Fore Cyan; Write-Host "Distribution)"
                    Write-Host "$t`Managed by: "   -NoNewline -Fore Cyan; Write-Host "(Kan være blankt)"
                    Write-Host "$t`Beskrivelse: "  -NoNewline -Fore Cyan; Write-Host "(Kan være blankt)"
                    Write-Host "$t`Sti: "          -NoNewline -Fore Cyan; Write-Host "(Default 'dc=domeneNavn,dc=com)`n"

                Write-Host "`t`t`t2. Slett gruppe`n"                               -Fore Cyan
                Write-Host "`t`t`t3. Søk om en gruppe eksisterer`n"                -Fore Cyan
                Write-Host "`t`t`t4. Skriv ut alle grupper i AD til en tekstfil"   -Fore Cyan
                    Write-Host "$t`Sti: "                               -NoNewline -Fore Cyan
                    Write-Host "C:\AD-Grupper.txt`n"
                Write-Host "`t`t`t5. List ut alle grupper som inneholder 'navn'`n" -Fore Cyan
                Write-Host "`t`t`t6. Flytt gruppe`n"                                    -Fore Cyan
                Write-Host "`t`t`t7. Endre en gruppe"                                  -Fore Cyan
                    Write-Host "$t`- Beskrivelse"
                    Write-Host "$t`- Kategori"
                    Write-Host "$t`- Scope`n"
                    #Write-Host $t"- SamAccountName`n" #Mulighet til å legge til funksjonalitet

                Write-Host "`t`t`t8. Vis alle brukere i en gruppe`n"                    -Fore Cyan
                
                Write-Host "`t`t`t9. Vis alle grupper med scope 'x'"                    -Fore Cyan
                    Write-Host "$t`Scope: "-NoNewline -Fore Cyan; Write-Host "(Lokal" -NoNewline
                    Write-Host ", "        -NoNewline -Fore Cyan; Write-Host "global" -NoNewline
                    Write-Host " eller "   -NoNewline -Fore Cyan; Write-Host "universal)`n"
                
                Write-Host "`t`t`t10. Finn tomme grupper`n"                             -Fore Cyan
                Write-Host "`t`t`t11. Tilbake"                                          -Fore Cyan

		    [int]$MenyGrupper = Read-Host "`n`t`t`tUtfør" #Henter respons fra bruker
                if ( $MenyGrupper -lt 1 -or $MenyGrupper -gt $AntallMenyAlternativer ){
                    Write-Host $feilmelding -Fore Red;Start-Sleep -Seconds $VentSekunder
		        }
            } #Slutt While

            Switch ($MenyGrupper){

				1 { #Oppretting av gruppe
                Write-Host "`nOppretting av gruppe" -Fore Cyan

                function OpprettLokalGruppe() {
                    Write-Host "`nVed å ikke skrive noe settes verdien til default" -Fore Yellow
                    Write-Host "der det ikke kreves bruker input."                  -Fore Yellow

                    do {
                        SkrivGruppeNavn
                        FinnGruppe
                            if ($script:GruppeFinnes) { 
                                Write-Host "`nGruppenavnet '$script:gruppeNavn' finnes fra før av. Skriv inn et nytt navn." -Fore Red
                            }
                    } while ($script:GruppeFinnes) #Utføres så lenge det fins en gruppeverdi

                    Spesifiser_gruppeScope         #Spesifiserer Lokal, global eller universal gruppe
                    Spesifiser_gruppeKategori      #Spesifiserer Security eller Distribution

                    do {
                        [int]$Eksisterer = "0"
                        Write-Host "`nSkriv inn navn på gruppe eller brukernavn til en bruker" -Fore Cyan
                        [string] $script:ManagedBy = Read-Host "`nManaged by? (Kan være blankt)" #Valgfritt
                            if ($script:ManagedBy -eq "") {$Eksisterer = "1"}
                            if ($script:ManagedBy -ne "") { #Dersom noe er skrevet inn må det søkes etter
                                $gruppe = Get-ADGroup -Filter "Name -eq '$script:ManagedBy'" | Sort #Søker etter gruppenavn
                                    if ($gruppe) {
                                        Write-Host "`n`tFant følgende gruppe:" -Fore Green
                                        $gruppe
                                        $Eksisterer = "1"
                                    }
                                $bruker = Get-ADUser -Filter "SamAccountName -like '$script:ManagedBy'" | Sort
                                    if ($bruker) {
                                        Write-Host "`n`tFant følgende bruker:" -Fore Green
                                        $bruker | FL -Property Name,UserPrincipalName,ObjectClass,Enabled,DistinguishedName
                                        $Eksisterer = "1"
                                    }
                                if ($Eksisterer -eq "0") {
                                    Write-Host "`n`tFant ingen grupper eller brukere med navnet '" -NoNewline -Fore Red
                                    Write-Host "$script:ManagedBy" -NoNewline
                                    Write-Host "'" -Fore Red
                                }
                            }
                    } while ($Eksisterer -eq "0")

                    [string] $script:Beskrivelse = Read-Host "`nGruppebeskrivelse (Kan være blankt)" #Valgfritt

                    Write-Host "`nSkriv inn sti der gruppa skal opprettes:`n" -Fore Cyan
                    Skriv-Gyldig-Path-i-AD #Funksjon der brukeren kan spesifisere sti i AD

                do {
                    Write-Host "`nOversikt over gruppe info:" -Fore Cyan
                    Write-Host "`n`tGruppenavn: " -NoNewline -Fore Cyan
                    Write-Host  $script:gruppeNavn
                    Write-Host "`tGruppescope: " -NoNewline -Fore Cyan
                    Write-Host  $script:gruppeScope
                    Write-Host "`tGruppekategori: " -NoNewline -Fore Cyan
                    Write-Host "$script:gruppeKategori"
                    Write-Host "`tManaged by: " -NoNewline -Fore Cyan
                    Write-Host  $script:ManagedBy
                    Write-Host "`tBeskrivelse " -NoNewline -Fore Cyan
                    Write-Host $script:Beskrivelse
                    Write-Host "`tSti til gruppe " -NoNewline -Fore Cyan
                    Write-Host  $script:path
                    Write-Host ""
                        $valg = Read-Host -Prompt "`nEr innstillingene korrekte? J/N"
                        Write-Host ""
                        if ($valg -eq "") {Write-Host "`tVennligst velg 'j' for 'ja', eller 'n' for 'nei" -Fore Red}
                } while ($valg -ne "j" -and $valg -ne "n")

                    if ($valg -eq "j") {

                    #Funksjon som sjekker om forrige kommando ble utført suksessfullt.
                    #Dersom den ble utført suksessfullt vises det en melding.
                    Function ResultatOpprettingGruppe {
                        if ($?) {
                            Write-Host "`tGruppa '$script:gruppeNavn' ble opprettet uten problemer" -Fore Green
                            Search_AD_Group #Søker etter gruppa og viser sti der den ble opprettet
                        }
                    }
                        # if 1
                        if ($script:ManagedBy   -eq "" -and `
                            $script:Beskrivelse -eq "" -and `
                            $script:path        -eq ""
                           ) {
                            try {
                                New-ADGroup                          `
                                -Name $script:gruppeNavn             `
                                -GroupScope $script:gruppeScope      `
                                -GroupCategory $script:gruppeKategori

                                ResultatOpprettingGruppe

                            } catch { FeilMelding } #Viser feilmelding

                          prompt_meny_gruppe_admin #Går tilbake til brukermeny
                        }#/if 1

                        # if 2
                        if ($script:ManagedBy   -eq "" -and `
                            $script:Beskrivelse -eq "" -and `
                            $script:path        -ne "" 
                           ) {
                            try {
                                New-ADGroup                           `
                                -Name $script:gruppeNavn              `
                                -GroupScope $script:gruppeScope       `
                                -GroupCategory $script:gruppeKategori `
                                -Path $script:path
                            
                                ResultatOpprettingGruppe

                            } catch { FeilMelding }

                          prompt_meny_gruppe_admin
                        }#/if 2

                        # if 3
                        if ($script:ManagedBy   -eq "" -and `
                            $script:Beskrivelse -ne "" -and `
                            $script:path        -ne ""
                           ) {
                            try {
                                New-ADGroup                           `
                                -Name $script:gruppeNavn              `
                                -GroupScope $script:gruppeScope       `
                                -GroupCategory $script:gruppeKategori `
                                -Path $script:path                    `
                                -Description $script:Beskrivelse
                            
                                ResultatOpprettingGruppe

                            } catch { FeilMelding }

                          prompt_meny_gruppe_admin
                        }#/if 3

                        # if 4
                        if ($script:Beskrivelse -eq "" -and `
                            $script:ManagedBy   -ne "" -and `
                            $script:Beskrivelse -ne "" -and `
                            $script:path        -ne ""
                           ) {
                            try {
                                New-ADGroup                           `
                                -Name $script:gruppeNavn              `
                                -GroupScope $script:gruppeScope       `
                                -GroupCategory $script:gruppeKategori `
                                -Path $script:path                    `
                                -ManagedBy $script:ManagedBy

                                ResultatOpprettingGruppe

                            } catch { FeilMelding }

                          prompt_meny_gruppe_admin
                        }#/if 4

                        # if 5
                        if ($script:Beskrivelse -eq "" -and `
                            $script:path        -eq "" -and `
                            $script:ManagedBy   -ne ""
                           ) {
                            try {
                                New-ADGroup                           `
                                -Name $script:gruppeNavn              `
                                -GroupScope $script:gruppeScope       `
                                -GroupCategory $script:gruppeKategori `
                                -ManagedBy $script:ManagedBy
                                
                                ResultatOpprettingGruppe

                            } catch { FeilMelding }

                          prompt_meny_gruppe_admin
                        }#/if 5

                        # if 6
                        if ($script:path        -eq "" -and `
                            $script:ManagedBy   -ne "" -and `
                            $script:Beskrivelse -ne ""
                           ) {
                            try {
                                New-ADGroup                           `
                                -Name $script:gruppeNavn              `
                                -GroupScope $script:gruppeScope       `
                                -GroupCategory $script:gruppeKategori `
                                -ManagedBy $script:ManagedBy          `
                                -Description $script:Beskrivelse
                                
                                ResultatOpprettingGruppe

                            } catch { FeilMelding }

                          prompt_meny_gruppe_admin
                        }#/if 6

                        # if 7
                        if ($script:path        -eq "" -and `
                            $script:ManagedBy   -eq "" -and `
                            $script:Beskrivelse -ne ""
                           ) {
                        try {
                            New-ADGroup                           `
                            -Name $script:gruppeNavn              `
                            -GroupScope $script:gruppeScope       `
                            -GroupCategory $script:gruppeKategori `
                            -Description $script:Beskrivelse
                            
                            ResultatOpprettingGruppe

                            } catch { FeilMelding }

                          prompt_meny_gruppe_admin
                        }#/if 7

                    }#/ if valg er ja

                    else { OpprettLokalGruppe }
                }

                    OpprettLokalGruppe
                    
                }#/ Slutt 1 - Oppretting av gruppe

                2 {#Slett en gruppe
                 SkrivGruppeNavn
                 FinnGruppe
                    if ($script:GruppeFinnes) {
                            Write-Host "`nFølgende gruppe ble funnet:`n" -Fore Cyan
                                $script:GruppeFinnes
                        
                            Write-Host "Er du sikker på at du ønsker å slette følgende gruppe? J/N" -Fore Yellow
                            ErDuHeltSikker? #Funksjon der bruker må velge "j" eller "n"

                                if ($valg -eq "j") { #Dersom bruker ønsker å slette gruppa:
                                    $GUID = Get-ADGroup -Filter "name -like '$script:gruppeNavn'" | Select-Object -Property ObjectGUID
                                    [string]$NyGUID = $GUID -replace "@{ObjectGUID=" -replace "}" #Formaterer GUID'en slik at den kan brukes i søk
                                    
                                        try {
                                            Remove-ADGroup -Identity "$NyGUID" -Confirm:$false #Fjerner gruppe ved bruk av GUID
                                                if ($?) {Write-Host "`n`tGruppen '$script:gruppeNavn' ble slettet suksessfullt" -Fore Green}
                                        } Catch { FeilMelding }
                          
                                  prompt_meny_gruppe_admin

                                } #Hvis bruker ikke ønsker å slette gruppa retuneres man tilbake til gruppe menyen med en gang
                                else { Reload_meny_gruppe_admin }
                            
                    } else { #Dersom variabelen GruppeNavn er tom finnes ikke gruppa
                        Write-Host "`n`tFant ikke gruppa '$script:gruppeNavn'" -Fore Yellow
                        prompt_meny_gruppe_admin
                }
                
                }#/ Slutt 2 - Slett en gruppe
                
                3 { # Søk om en gruppe eksisterer
                    SkrivGruppeNavn
                    FinnGruppe
                    VisFunnetGruppe
                    prompt_meny_gruppe_admin
                }#/ Slutt 3 - Søk om en gruppe eksisterer

                4 { #Skriv ut absolutt alle grupper i AD til en tekstfil

                    HvorSkalFilaLagres?

                    try {
                        Get-ADGroup -Filter * | Select -Property DistinguishedName,GroupCategory, `
                        GroupScope,Name,ObjectClass,SamAccountName,ObjectGUID | Out-File $script:path
                            if ( $?) {
                                Write-Host "`n`tKommandoen ble utført suksessfullt" -Fore Green
                                Write-Host "`n`tSti til fil: " -NoNewline -Fore Green
                                Write-Host $script:path
                            }
                            prompt_meny_gruppe_admin
                    }
                    catch {
                        Write-Host "`n`t$_`n" -Foreground red #Viser eventuell feilmelding
                        Write-Host "`n`tKommandoen " -NoNewline -Fore Red
                        Write-Host "'Get-ADGroup -Filter * | Out-File $script:path'" -NoNewline -Fore Yellow
                        Write-Host " kunne ikke kjøres" -Fore Red
                        Write-Host "`tEr du på en Windows Server?" -Fore Red
                        prompt_meny_gruppe_admin
                    }
                
                }#/ Slutt 4 - Skriv ut absolutt alle grupper i AD til en tekstfil

                5 { #List ut alle grupper som inneholder 'tekst'

                    SkrivGruppeNavn

                    try {
                        $grupper = Get-ADGroup -Filter "name -like '*$script:gruppeNavn*'" | FL -Property Name,DistinguishedName,GroupScope,GroupSecurity
                            if ($grupper) {
                                Write-Host "`n`tFant følgende grupper:`n" -Fore Green
                                $grupper
                            }
                            else {Write-Host "`n`tFant ingen grupper som inneholdte '$script:gruppeNavn'" -Fore Yellow}
                    }
                    catch { Write-Host "`n`t$_" -Foreground red } #Viser eventuell feilmelding
 
                  prompt_meny_gruppe_admin #Gir bruker mulighet til å trykke 'enter' for bruker går tilbake til meny

                }#/ Slutt 5 - List ut alle grupper som inneholder 'navn'

                6 { #Flytt gruppe
                    
                    function FlyttGruppe() {
                        Write-Host "`nFyll inn navnet på gruppa du ønsker å flytte" -Fore Yellow
                        SkrivGruppeNavn
                        FinnGruppe
                        VisFunnetGruppe
                    do {
                        $valg = Read-Host "Er dette korrekt gruppe? J/N"
                            if ($valg -eq "" -or $valg -ne "j" -and $valg -ne "n") {Write-Host "`n`tVennligst velg 'J' for ja eller 'N' for nei`n" -Fore Red}
                    } while ($valg -ne "j" -and $valg -ne "n") #Bruker må velge "j" eller "n"

                        if ($valg -eq "j") {
                            $GUID1 = Get-ADGroup -Filter "name -like '$script:gruppeNavn'" | Select-Object -Property ObjectGUID
                            [string]$NyGUID_gruppe = $GUID1 -replace "@{ObjectGUID=" -replace "}" #Formaterer GUID'en slik at den kan brukes senere
                            $gruppe1 = $script:gruppeNavn
                        }
                        else { FlyttGruppe }

                    do {
                        Write-Host "`nFyll inn navnet på Container du ønsker å flytte TIL" -Fore Yellow
                        do {
                            [string] $script:navnOU = Read-Host "`nNavn Organizational Unit"
                            if ($script:navnOU -eq "") {Write-Host "`n`tFeltet kan ikke være tomt" -Fore Red}
                        } while ($script:navnOU -eq "")

                        $script:OrganizationalUnit = Get-ADOrganizationalUnit -Filter "name -like '$script:navnOU'" | Select-Object -Property Name,DistinguishedName
                        if ($script:OrganizationalUnit) {
                            Write-Host "`nFølgende Organizational Unit ble funnet:`n" -Fore Cyan
                            $script:OrganizationalUnit
                            $script:FantGyldigOU = $true
                        }
                        else { 
                            Write-Host "`n`tFant ingen OU med navn '$script:navnOU'" -Fore Red
                            $script:FantGyldigOU = $false 
                        }
                    } while ($script:FantGyldigOU -eq $false)


                        do {
                            $valg = Read-Host "Er dette korrekt OU? J/N"
                            if ($valg -eq "") {Write-Host "`n`tVennligst velg 'J' for ja eller 'N' for nei`n" -Fore Red}
                        } while ($valg -ne "j" -and $valg -ne "n") #Bruker må velge "j" eller "n"
                    
                        if ($valg -eq "j") {
                            $GUID_OU = Get-ADOrganizationalUnit -Filter "name -like '$navnOU'" | Select-Object -Property ObjectGUID
                            [string]$NyGUID_OU = $GUID_OU -replace "@{ObjectGUID=" -replace "}" #Formaterer GUID'en slik at den kan brukes senere
                        }
                        else { FlyttGruppe }

                        Write-Host "`nPrøver å flytte gruppa " -NoNewline -Fore Yellow
                        Write-Host "'$script:gruppeNavn'" -NoNewline
                        Write-Host " til OU " -NoNewline -Fore Yellow
                        Write-Host "'$navnOU'`n"                    
                        
                        Move-ADObject "$NyGUID_gruppe" -TargetPath "$NyGUID_OU" -Verbose
                            if ($?) { Write-Host "`nSuksessfull flytting!" -Fore Green }

                      prompt_meny_gruppe_admin
                    }#/FlyttGruppe

                    FlyttGruppe

                }#/ Slutt 6 - Flytt gruppe

                7 { #Endre en gruppe

                    SkrivGruppeNavn
                    FinnGruppe
                        if ($script:GruppeFinnes) { #Dersom den finnes:
                        Write-Host "`nFant følgende gruppe:" -Fore Green
                            $script:GruppeFinnes | FL -Property Name,GroupScope,GroupCategory,DistinguishedName

                            do { #Hva ønsker bruker å endre på?
                                Write-Host "Hva ønsker du å endre?`n" -Fore Cyan 
                                Write-Host "`tBeskrivelse:    " -NoNewline -Fore Cyan; Write-Host "1"
                                Write-Host "`tGruppekategori: " -NoNewline -Fore Cyan; Write-Host "2"
                                Write-Host "`tGruppeScope:    " -NoNewline -Fore Cyan; Write-Host "3"

                                $endring = Read-Host -Prompt “`nVelg et tall"

                                    if ($endring -eq "") { Write-Host "`n`tFeltet kan ikke være tomt" -Fore Red }

                            } while ( #Kjører til et av valgene nedenfor blir valgt
                                $endring -ne "1" -and `
                                $endring -ne "2" -and `
                                $endring -ne "3"
                               )

                            if ($endring -eq "1") {
                                
                                do {
                                    Write-Host "`nSkriv inn en beskrivelse nedenfor`n" -Fore Yellow
                                        $beskrivelse = Read-Host "`tBeskrivrlse"
                                            if ($beskrivelse -eq "") {
                                                Write-Host "`n`tFeltet kann ikke være tomt" -Fore Red
                                            }
                                } while ($beskrivelse -eq "")

                                    Write-Host "`nØnsker du å fortsett handlingen?" -Fore Cyan
                                    ErDuHeltSikker?; Write-Host; #Lager et mellomrom mellom output og svaret til bruker

                                        if ($script:valg -eq "j") {

                                            Try {
                                                Set-ADGroup -Identity $script:gruppeNavn -Description $beskrivelse -Verbose
                                                    BleDetSuksess?
                                            } Catch { FeilMelding }

                                        } else { Reload_meny_gruppe_admin } #Laster inn meny
                            }

                            #Dersom valget er nr 2 - gruppekategori
                            if ($endring -eq "2") {
                                $kategori = Get-ADGroup -Filter "Name -eq '$script:gruppeNavn'" | Select -ExpandProperty GroupCategory
                                
                                Write-Host "`n`tGruppa har kategori '$kategori'" -Fore Yellow

                                    #Gjør at verdien blir motsatt da den skal byttes.
                                    If ($kategori -eq "Security") { $kategori = "Distribution" }
                                    else { $kategori = "Security" }
                                    
                                    Write-Host "`nØnsker du å fortsett handlingen?" -Fore Cyan
                                        ErDuHeltSikker?

                                        if ($script:valg -eq "n") { Reload_meny_gruppe_admin }
                                        else {
                                            Try {
                                                Set-ADGroup -Identity $script:gruppeNavn -GroupCategory $kategori
                                                 BleDetSuksess?
                                            } Catch { FeilMelding }
                                        }
                            }

                            if ($endring -eq "3") {
                                $Scope = Get-ADGroup -Filter "Name -eq '$script:gruppeNavn'" | Select -ExpandProperty GroupScope

                                do {
                                    Write-Host "`nGruppa er '$Scope'. Derfor er " -NoNewline -Fore Yellow
                                    if ($Scope -eq "DomainLocal") {
                                        Write-Host "følgende scope tilgjengelige:`n"         -Fore Yellow
                                            Write-Host "`t1. Global"                         -Fore Cyan
                                            Write-Host "`t2. Universal"                      -Fore Cyan
                                            $Scope1 = "Global"
                                            $Scope2 = "Universal"
                                    }
                                    if ($Scope -eq "Universal") {
                                        Write-Host "følgende scope tilgjengelige:`n" -Fore Yellow
                                            Write-Host "`t1. Global"                 -Fore Cyan
                                            Write-Host "`t2. DomainLocal"            -Fore Cyan
                                            $Scope1 = "Global"
                                            $Scope2 = "DomainLocal"
                                    }
                                    if ($Scope -eq "Global") {
                                        Write-Host "følgende scope tilgjengelige:`n" -Fore Yellow
                                            Write-Host "`t1. DomainLocal"            -Fore Cyan
                                            Write-Host "`t2. Universal"              -Fore Cyan
                                            $Scope1 = "DomainLocal"
                                            $Scope2 = "Universal"
                                    }
                                    
                                        $ScopeValg =  Read-Host "`n`tScope"
                                            if ($ScopeValg -ne "1" -and
                                                $ScopeValg -ne "2"
                                               ){ Write-Host "`n`tVennligst velg blant tilgjengelige scope" -Fore Red }

                                } while ($ScopeValg -ne "1" -and $ScopeValg -ne "2")
                                    
                                    If ($ScopeValg -eq "1") { $ScopeValg = $Scope1 }
                                    else { $ScopeValg = $Scope2 }

                                    Write-Host "`nØnsker du å fortsett handlingen?" -Fore Cyan
                                     ErDuHeltSikker?

                                        if ($script:valg -eq "n") { Reload_meny_gruppe_admin }
                                        else {
                                            Try {
                                                Set-ADGroup -Identity $script:gruppeNavn -GroupScope $ScopeValg
                                                    BleDetSuksess?
                                            } Catch { FeilMelding }
                                        }
                            }#/If 3

                    } else { Write-Host "`n`tFant ingen gruppe med navn '$script:gruppeNavn'" -Fore Yellow }

                  prompt_meny_gruppe_admin

                }#/ Slutt 7 - Endre en gruppe

                8 { #Vis alle brukere i en gruppe

                    SkrivGruppeNavn #Skriv inn gruppenavn
                    FinnGruppe      #Søker etter gruppe

                    if ($script:GruppeFinnes) { #Dersom den finnes:
                        Write-Host "`nFant følgende gruppe:" -Fore Green
                        
                        $script:GruppeFinnes | FL -Property Name,GroupScope,GroupCategory,DistinguishedName
                        
                        $brukere = Get-ADGroupMember $script:GruppeFinnes
                        
                        if ($brukere) { #Sjekker om variabelen
                            Write-Host "`nFant følgende brukere i gruppa" -Fore Green
                            $brukere | FL -Property Name,SamAccountName
                        }
                        else {
                            Write-Host "Fant ingen brukere i gruppa '" -NoNewline -Fore Red
                            Write-Host "$script:gruppeNavn" -NoNewline
                            Write-Host "'" -Fore Red
                        }      
                     }
                     else {
                        Write-Host "`nFant ingen gruppe med navn '" -NoNewline -Fore Red
                        Write-Host "$script:gruppeNavn" -NoNewline
                        Write-Host "'" -Fore Red
                     }
                    prompt_meny_gruppe_admin
                }#/ Slutt 8 - Vis alle brukere i en gruppe

                9 { #Vis alle grupper med scope 'x'
                    Spesifiser_gruppeScope
                    try {
                        $grupper = Get-ADGroup -Filter "groupscope -eq '$script:gruppeScope' " | FL -Property Name,GroupCategory,DistinguishedName
                            if ($grupper) {
                                Write-Host "`n`tFant følgende grupper med scope '$script:gruppeScope'`n" -Fore Green
                                $grupper
                            }
                            else {Write-Host "`n`tFant ingen grupper med scope '$script:gruppeScope'" -Fore Yellow}
                    } catch { FeilMelding }
                    
                    prompt_meny_gruppe_admin
                }#/ Slutt 9 - Vis alle grupper med scope 'x'

                10 { #Finn tomme grupper
                    # Kilde: https://nidhinck.wordpress.com/2013/07/23/find-empty-groups-in-active-directory-using-powershell-script/
                    Get-ADGroup -Filter * | where {-Not $_.members} | 
                    select Name,ObjectClass,GroupScope,DistinguishedName | Format-Table
                    prompt_meny_gruppe_admin

                }#/ Slutt 10 - Finn tomme grupper

                11 { LastInnMeny }

            
            } #Slutt switch
      }#/ funksjon meny_gruppe_administrasjon

      meny_gruppe_administrasjon

      } #Slutt menyalternativ 5 - Gruppe-administrasjon

        6  { #Menyalternativ 6 - 'GPO-administrasjon'

            function Prompt_GPO-Administrasjon { #funksjon som gir bruker mulighet til å trykk enter for menyen lastes inn på nytt
                Read-Host "`nTrykk 'enter' for å gå tilbake"
                $MenyGPO = 0
                GPO-Administrasjon
            }

            function Reload_GPO-Administrasjon { #Laster inn meny med en gang funksjonen kjøres
                $MenyBruker = 0
                GPO-Administrasjon
            }

            function Finn_GPO {

                #Prøver å hente navnet på GPO
                Try { $script:GPOFinnes = Get-GPO -DisplayName $script:navn -ErrorAction SilentlyContinue }
                
                #Hvis det oppstår feil får bruker beskjed og funksjonen
                #stopper fra å gå videre.
                Catch { FeilMelding; Prompt_GPO-Administrasjon }
            }

            Function SpesifiserKorrektOU {
                Do {
                    Do {
                        SkrivNavnOU
                                            
                        #Prøver å finne OU basert på navn. Dersom det oppstår feil i
                        #utføring av kommando stoppes utføring av resten av kommando.
                            Try { FinnOrganizationalUnit } catch { FeilMelding; Prompt_GPO-Administrasjon }

                                if ($script:OU ) {
                                    Write-Host "`nFant følgende OU" -Fore Cyan
                                    $script:OU
                                     FinnDistinguishedNameOU

                                } Else { Write-Host "`n`tFant ingen OU med navn '$script:navn'" -Fore Yellow }

                    } While ($script:OU -eq $null)

                    Write-Host "`nEr dette korrekt OU?"
                    ErDuHeltSikker?

                } While ($script:valg -eq "n")  
            }

            function GPO-Administrasjon {

            [int] $AntallMenyAlternativer = 9 #Antall alternativer i undermenyen
         [string] $sti = "Hovedmeny / GPO-administrasjon /"
                  $t2  = "`t`t"
                  $t3  = "`t`t`t"
                  $t4  = "`t`t`t`t"
                  $t5  = "`t`t`t`t`t"

			while ( $MenyGPO -lt 1 -or $MenyGPO -gt $AntallMenyAlternativer ) {
				Clear-Host
				Write-Host " $appNavn "                                         -Fore Magenta
                Write-Host "`tDu står i:"                            -NoNewline -Fore Cyan
                Write-Host " $sti`n"
				Write-Host "$t2`Velg mellom følgende administrative oppgaver`n" -Fore Cyan

                Write-Host "$t2`1. Oppdater GPO (GPupdate)`n"                   -Fore Cyan
                Write-Host "$t2`2. Group Policy Results (GPResult.exe)"         -Fore Cyan
                Write-Host "$t3- " -NoNewline 
                Write-Host "Skriver ut all tilgjengelig informasjon til fil"    -Fore Cyan
                Write-Host "`n$t2`3. List ut alle GPO på server`n"              -Fore Cyan
                Write-Host "$t2`4. Opprett ny GPO"            -Fore Cyan
                    Write-Host "$t3 Navn:        " -NoNewline -Fore Cyan; Write-Host "(kreves)"
                    Write-Host "$t3 Beskrivelse: " -NoNewline -Fore Cyan; Write-Host "(Valgfritt)"
                    Write-Host "$t3 Link GPO:    " -NoNewline -Fore Cyan; Write-Host "(valgfritt)"
                    Write-Host "$t4- "             -NoNewline -Fore Cyan; Write-Host "Organizational Unit`n"

                Write-Host "$t2`5. Slett GPO-link "      -Fore Cyan
                Write-Host "$t3 (Dette sletter ikke selve GPO objektet)"
                    Write-Host "$t3 Navn:   " -NoNewline -Fore Cyan; Write-Host "(kreves)"
                    Write-Host "$t3 Target: " -NoNewline -Fore Cyan; Write-Host "Organizational Unit`n"
                
                Write-Host "$t2`6. Slett GPO 'navn'`n"                  -Fore Cyan
                Write-Host "$t2`7. Søk etter spesifikt GPO`n"           -Fore Cyan
                Write-Host "$t2`8. Sikkerhetskopier alle GPO til sti`n" -Fore Cyan
                Write-Host "$t2`9. Tilbake`n"                           -Fore Cyan

		        [int]$MenyGPO = Read-Host "`t`t`tUtfør" #Henter respons fra bruker
                    if ( $MenyGPO -lt 1 -or $MenyGPO -gt $AntallMenyAlternativer ) {
                        Write-Host $feilmelding -Fore Red; Sleep -Seconds $VentSekunder
		            }
            } #Slutt While

            Switch ($MenyGPO) {

				1 { #Oppdater GPO (GPupdate
                    try {
                        Write-Host "`nPrøver å oppdaterer Group Policy`n" -Fore Yellow

                        gpupdate.exe /force

                            if ($?) { Write-Host "Computer Policy og User Policy ble suksessfullt oppdatert" -Fore Green }

                    } catch { FeilMelding } #Viser feilmelding
                  Prompt_GPO-Administrasjon

                } #Slutt 1 - Oppdater GPO

                2 { #Group Policy Results
                    Write-Host "`nHva skal fila hete og Hvor ønsker du å lagre fila?"  -Fore Cyan
                    Write-Host "`tDefault: " -NoNewline -Fore Cyan; Write-Host "C:\GRP.txt"
                        
                    $path = Read-Host "Sti"
                        if ($path -eq "") { 
                            Write-Host "`n`tVelger default navn og sti!" -Fore Yellow
                            $path = "C:\GRP.txt"
                        }

                        try { #starter 'Group Policy Results' og sender output til fil
                            gpresult /z >$path #
                            BleDetSuksess? #Sjekker om kommmandoen ble utført suksessfullt
                        } Catch { FeilMelding }

                    Prompt_GPO-Administrasjon

                } #Slutt 2 - Group Policy Results

                3 { #List ut alle GPO på server
                    
                    #Henter alle GPO, sorterer dem og formaterer output
                    try { Get-GPO -All | Select -Property DisplayName,GpoStatus,Description,CreationTime | Sort | FT }
                    Catch { FeilMelding } #Viser eventuell feilmelding
                    
                    Prompt_GPO-Administrasjon
                
                } #Slutt 3 - List ut alle GPO på server

                4 { #Opprett ny GPO

                    Do {
                        Do {
                            Write-Host "`nHVa skal GPO-et hete?" -Fore Cyan
                             SkrivNavn
                             Finn_GPO

                                if ($GPOFinnes) { Write-Host "`nDet fines et GPO med samme navn" -Fore Red }

                        } While ($GPOFinnes -ne $null) #Utføres så lenge det ikke finnes et navn


                        Write-Host "`nLegge til beskrivelse?" -Fore Cyan
                         ErDuHeltSikker?
                            if ($script:valg -eq "j") {
                                Write-Host "`nSkriv inn ønsket beskrivelse" -Fore Cyan
                                $Beskrivelse = Read-Host "`tBeskrivelse"
                                    if ( $Beskrivelse -eq "") {
                                        Write-Host "`n`tBeskrivelsen kan ikke være tom!" -Fore Red
                                    }
                                #Endrer variabel slik at det kommer med anførelsestegn
                                $Beskrivelse = "'$Beskrivelse'" 
                            } else { $Beskrivelse = "'$script:navn'" } #Setter beskrivelsen til navnet på GPO'et

                            Write-Host "`nØnsker du å linke GPO?" -Fore Cyan
                             ErDuHeltSikker?

                                if ($script:valg -eq "j") {
                                    $LinkGPO = $true  
                                    SpesifiserKorrektOU
                                }

                                Write-Host "`nEr oppsett korrekt?`n"    -Fore Yellow
                                Write-Host "`tNavn GPO:    " -NoNewline -Fore Cyan; Write-Host $script:navn
                                Write-Host "`tBeskrivelse: " -NoNewline -Fore Cyan; Write-Host $Beskrivelse
                                Write-Host "`tOrganizational Unit: " -NoNewline -Fore Cyan; Write-Host $script:navnOU
                                Write-Host ""
                                    ErDuHeltSikker?

                    } While ($script:valg -eq "n")

                        if ($LinkGPO -eq $true) {
                            Try {

                                New-GPO -Name $script:navn -comment "$Beskrivelse" |
                                new-gplink -target $script:DistinguishedName

                                 BleDetSuksess? #Sjekker om kommandoen ovenfor ble kjørt suksessfullt

                            } Catch { FeilMelding } #Viser eventuell feilmelding
                        } else {
                            Try {
                                New-GPO -Name $script:navn -comment "$Beskrivelse"

                                 BleDetSuksess? #Sjekker om kommandoen ovenfor ble kjørt suksessfullt

                            } Catch { FeilMelding } #Viser eventuell feilmelding
                        }

                    Prompt_GPO-Administrasjon

                } #Slutt 4 - Opprett ny GPO
                    
                5 { #Slett GPO-link

                    Do {
                        Write-Host "`nHva heter GPO'et?" -Fore Cyan
                         SkrivNavn
                         Finn_GPO
                            if ($GPOFinnes -eq $null) { Write-Host "`n`tFant ingen GPO med navn '$script:navn'" -Fore Red }

                    } While ($GPOFinnes -eq $null) #Utføres så lenge det ikke finnes et navn

                    Write-Host "`nSpesifiser navn på OU" -Fore Cyan
                     SpesifiserKorrektOU

                    Write-Host "`nEr du helt sikker på du ønsker å fjerne link til OU '$script:navn'" -Fore Yellow
                     ErDuHeltSikker?
                     Write-Host "" #Lager en ekstra linje mellom svar og output som kommer på skjerm.
                        if ($valg -eq "n") { Reload_GPO-Administrasjon }
                        else {
                            Try {
                                Remove-GPLink -Name $script:navn -Target $script:DistinguishedName
                                 BleDetSuksess? #Sjekker om kommando ble utført suksessfullt
                            } Catch { FeilMelding }
                        }

                    Prompt_GPO-Administrasjon

                } #Slutt 5 - Slett GPO-link

                6 { #Slett GPO
                
                    Do {
                        Write-Host "`nHva heter GPO'et?" -Fore Cyan
                         SkrivNavn
                         Finn_GPO

                            #Bruker får beskjed at variabelen er tom, det vil si at det ikke finnes noen GPO.
                            if ($GPOFinnes -eq $null) { Write-Host "`n`tFant ingen GPO med navn '$script:navn'" -Fore Red }

                    } While ($GPOFinnes -eq $null) #Utføres så lenge det ikke finnes et navn
                    
                    Write-Host "`nEr du helt sikker på at du ønsker å slette GPO '$script:navn'?" -Fore Red
                        ErDuHeltSikker?

                        if ($valg -eq "n") { Reload_GPO-Administrasjon } #Går tilbake til meny
                        else {
                            Try {
                                Remove-GPO -Name $script:navn
                                    if ($?) { Write-Host "`n`tGPO '$script:navn' ble slettet suksessfullt" -Fore Yellow }
                            } Catch { FeilMelding }
                        }

                    Prompt_GPO-Administrasjon

                } #Slutt 6 - Slett GPO

                7 { #Søk etter spesifikt GPO
                    Write-Host "`nHva heter GPO'et som skal søkes etter?" -Fore Cyan
                     SkrivNavn
                     Finn_GPO

                        #Bruker får beskjed at variabelen er tom, det vil si at det ikke finnes noen GPO.
                        if ($script:GPOFinnes -eq $null) { Write-Host "`n`tFant ingen GPO med navn '$script:navn'" -Fore Red }
                        else {
                            Write-Host "`nFant følgende GPO" -Fore Cyan
                            $script:GPOFinnes
                        }
                    Prompt_GPO-Administrasjon
                } #Slutt 7 - Søk etter spesifikt GPO

                8 { #Sikkerhetskopier alle GPO til sti

                    #Funksjon som ber bruker skrive inn en gyldig sti
                    Do {
                        Write-Host "`nSkriv inn sti der GPO'ene skal lagres til"
                        $Sti = Read-Host "`tSti"
                            if ($sti -eq "") {
                                Write-Host "`n`tStien kan ikke være blank" -Fore Red
                                $GyldigSti = $false
                            } Else {
                                if ((Test-Path $sti) -eq $true) {
                                    Write-Host "`n`tSetter sti til '$sti'" -Fore Green
                                    $GyldigSti = $true
                                } else {
                                    Write-Host "`n`tUgyldig sti" -Fore Red
                                    $GyldigSti = $false
                                }
                            }
                    #Utføres så lenge stien ikke er gyldig
                    } While ($GyldigSti -eq $false)

                    Try {
                        #Kommando som utfører backup
                        Backup-Gpo -All -Path $sti
                            #Sjekker om utføring av oppgave gikk greit
                            BleDetSuksess? 

                    } Catch { FeilMelding } #Henter eventuell feilmelding

                 Prompt_GPO-Administrasjon

                }#Slutt 8 - Sikkerhetskopier alle GPO

                9 { LastInnMeny }
            
            } #Slutt switch

            }#/Slutt GPO-Administrasjon

                GPO-Administrasjon #Kjører menyen

      } #Slutt menyalternativ 6 - GPO-administrasjon

        7  { #Menyalternativ 7 - 'OU-administrasjon'

        function VisOUMeny {

            function prompt_OUMeny { #Gir brukeren mulig til å lese output før h*n må trykke 'enter'
                Read-Host "`nTrykk 'enter' for gå tilbake"
                $MenyOU = 0
                VisOUMeny
            }

            function RealoadOUMeny { #Laster inn meyen med en gang
                $MenyOU = 0
                VisOUMeny
            }

            function VisOrganizationalUnit {
                if ($OU) {
                    Write-Host "`nFølgende Organizational Unit ble funnet:" -Fore Cyan
                    $OU
                }
                else {Write-Host "`n`tFant ingen OU'er med navn '$navnOU'" -Fore Yellow}
            } #/VisOrganizationalUnit

            function FinnAlleOrganizationalUnits { #Finner alle OU og viser dem med noen egenskaper.
                try {
                    Get-ADOrganizationalUnit -Filter * | Select-Object -Property DistinguishedName,Name | Format-Table
                } catch { FeilMelding }
            }

            function Suksess_Ubeskyttet { #Hvis det opprettes et OU uten beskyttelse
                if ($?) {
                    Write-Host "`n`tSuksessfull oppretting av OU '$navnOU' uten beskyttelse mot uhelldig sletting" -Fore Green
                }
            }

            function Suksess_Beskyttet { #Hvis det opprettes et OU med beskyttelse
                if ($?) {
                    Write-Host "`n`tSuksessfull oppretting av OU '$navnOU' med beskyttelse mot uhelldig sletting" -Fore Green
                }
            }

            function OUBeskyttet ($verdi) {
 
            #Henter alle OU'er som har egenskapen 'ProtectedFromAccidentalDeletion' satt
            #til verdien som blir spesifisert i parameteret '$verdi'.
                Get-ADOrganizationalUnit -Filter * -Properties ProtectedFromAccidentalDeletion | 
                where {$_.ProtectedFromAccidentalDeletion -eq $verdi } | 
                Select -Property DistinguishedName,Name | FT
            }

                   $t = "`t`t`t"

            [int] $AntallMenyAlternativer = 9 #Antall alternativer i undermenyen
         [string] $sti = "Hovedmeny / OU-administrasjon /"
			while ( $MenyOU -lt 1 -or $MenyOU -gt $AntallMenyAlternativer ) {
				Clear-Host
				Write-Host " $appNavn "                                         -Fore Magenta
                Write-Host "`tDu står i:"                            -NoNewline -Fore Cyan
                Write-Host " $sti`n"
				Write-Host "`t`tVelg mellom følgende administrative oppgaver`n" -Fore Cyan
                Write-Host $t"1. Opprett nytt OU"                               -Fore Cyan
                    Write-Host $t"`tNavn: "                          -NoNewline -Fore Cyan
                    Write-Host "(Kreves)"
                    Write-Host $t"`tBeskytt mot uhelldig sletting: " -NoNewline -Fore Cyan
                    Write-Host "J/N"
                    Write-Host $t"`tSti: "                           -NoNewline -Fore Cyan
                    Write-Host "(Valgfritt)`n"
                Write-Host $t"2. Slett OU`n"                                    -Fore Cyan
                Write-Host $t"3. List ut alle OU'er"                            -Fore Cyan
                Write-Host $t"`t$AntallOU"                           -NoNewline
                Write-Host " OU'er totalt`n"                                    -Fore Cyan
                Write-Host $t"4. Søk etter spesifikt OU`n"                      -Fore Cyan
                Write-Host $t"5. List alle OU som inneholder navn 'navn'`n"     -Fore Cyan
                Write-Host $t"6. List alle OU som har"                          -Fore Cyan
                Write-Host $t"`tProtected From Accidental Deletion:" -NoNewline -Fore Cyan
                Write-Host " Enabled / Disabled`n"
                Write-Host $t"7. Beskytt alle OU'er i AD mot uhelldig sletting" -Fore Cyan
                Write-Host $t"   $AntallOU_Ubeskyttet/$AntallOU"     -NoNewline
                Write-Host " OU er ubeskyttet mot sletting`n"                   -Fore Cyan
                Write-Host $t"8. Fjern beskyttelse mot uhelldig sletting på alle OU`n" -Fore Cyan

                Write-Host $t"9. Tilbake`n"                                     -Fore Cyan

		    [int]$MenyOU = Read-Host "`t`t`tUtfør" #Henter respons fra bruker
                if ( $MenyOU -lt 1 -or $MenyOU -gt $AntallMenyAlternativer ){
                    Write-Host $feilmelding -Fore Red;Start-Sleep -Seconds $VentSekunder
		        }
            } #Slutt While løkke

            Switch ($MenyOU){

				1 { #Opprett nytt OU

                    do {
                        SkrivNavnOU
                        FinnOrganizationalUnit
                            if ($OU) { 
                                Write-Host "`n`tOU'et '$navnOU' finnes fra før av. Skriv inn et nytt navn." -Fore Red
                            }
                    } while ($OU) #Utføres så lenge det fins et OU med likt navn

                    #Ønsker bruker å beskytte OU?
                    Write-Host "`nBeskytt mot sletting ved uhell? J/N" -Fore Cyan
                        ErDuHeltSikker?

                    #Endrer varabelen slik at den ikke endres av funksjonen 'ErDuHeltSikker?'
                    if ($valg -eq "j") {$BeskyttSletting = "j"}
                    else { $BeskyttSletting = "n"}

                    #Ønsker bruker å se en liste med oversikt over OU'er?
                        Write-Host "`nOU'et kan legges inni et annet OU." -Fore Cyan
                        Write-Host "Vil du vise en liste over tilgjengelige OU'er? J/N" -Fore Cyan
                            ErDuHeltSikker?

                    if ($valg -eq "j") { FinnAlleOrganizationalUnits }

                    Write-Host "`nSkriv inn sti der OU'et skal opprettes:`n" -Fore Cyan
                     #Funksjon som tillater en blank sti.
                     #Hvis det skrives inn noe får ikke bruker
                     #gå videre før stien er gyldig i AD.
                    Skriv-Gyldig-Path-i-AD 

                    try {
                        
                        if ($BeskyttSletting -eq "j" -and $path -eq "") {
                            NEW-ADOrganizationalUnit $navnOU `
                            -ProtectedFromAccidentalDeletion $true
                                Suksess_Beskyttet
                        }

                        if ($BeskyttSletting -eq "j" -and $path -ne "") {
                            NEW-ADOrganizationalUnit $script:navnOU `
                            -ProtectedFromAccidentalDeletion $true  `
                            -Path $script:path
                                Suksess_Beskyttet
                        }

                        if ($BeskyttSletting -eq "n" -and $path -eq "") {
                            NEW-ADOrganizationalUnit $navnOU `
                            -ProtectedFromAccidentalDeletion $false
                                Suksess_Ubeskyttet     
                        }

                        if ($BeskyttSletting -eq "n" -and $path -ne "") {
                            NEW-ADOrganizationalUnit $navnOU `
                            -ProtectedFromAccidentalDeletion $false `
                            -Path $path
                                Suksess_Ubeskyttet
                        }
                    
                    } catch { FeilMelding } #Viser eventuell feilmelding

                    prompt_OUMeny #Gir bruker mulighet til å trykke 'enter' for menyen lastes inn på nytt
                } #Slutt 1 - Opprett nytt OU

                2 { #Slett OU

                    SkrivNavnOU #Bruker må skrive inn et navn

                    FinnOrganizationalUnit #Prøver å finne OU med navnet som er spesifisert

                    VisOrganizationalUnit #Viser OU'et dersom det eksisterer
                        if ($script:ou) {
                    Write-Host "`nEr du sikker på at du ønsker å slette følgende OU? J/N`n" -Fore Cyan

                    ErDuHeltSikker? #Funksjon som spørr om brukeren er sikker på om h*n ønsker å fortsette
                    
                    if ($valg -eq "j") {
                        $GUID = Get-ADOrganizationalUnit -Filter "name -like '$navnOU'" | Select-Object -Property ObjectGUID
                        [string]$NyGUID = $GUID -replace "@{ObjectGUID=" -replace "}"

                        try {
                          #Koden under søker etter og fjerner OU med GUID som er funnet.
                          Remove-ADOrganizationalUnit -Identity "$NyGUID" -Confirm:$false

                            if ($?) {Write-Host "`n`tOU'et '$navnOU' ble slettet suksessfullt" -Fore Yellow}
                            else { 
                                Write-Host "`tOU'et '$navnOU' kunne ikke slettes" -Fore Red
                                Write-Host "`tEr det beskyttet mot uhelldig sletting?`n" -Fore Red
                            }
                        }
                        catch { FeilMelding }
                       # prompt_OUMeny
                    }
                    else { RealoadOUMeny } #Laster inn OU menyen umiddelbart
                  }

                  prompt_OUMeny

                } #Slutt 2 - Slett OU

                3 { #List ut alle OU'er

                    FinnAlleOrganizationalUnits #Henter alle OU'er og viser dem med noen utvalgte/viktige egenskaper.
                    prompt_OUMeny #Trykk enter for å gå tilbake

                } #Slutt 3 - List ut alle OU'er

                4 { #Søk etter spesifikt OU

                    SkrivNavnOU
                    
                    FinnOrganizationalUnit

                    VisOrganizationalUnit
                    
                    prompt_OUMeny
                    
                } #Slutt 4 - Søk etter spesifikt OU

                5 { #List ut alle OU som inneholder navn 'navn'

                    SkrivNavnOU

                        try {
                            $OU = Get-ADOrganizationalUnit -Filter "name -like '*$navnOU*' " | Select-Object -Property Name,ObjectClass,DistinguishedName
                            VisOrganizationalUnit
                        } catch { feilmelding }
                    
                    prompt_OUMeny

                } #Slutt 5 - List alle OU som inneholder navn 'navn'

                6 { #List alle OU som har ProtectedFromAccidentalDeletion Enabled / Disabled

                    do {
                        Write-Host "`nHva ønsker du å vise?`n" -Fore Cyan
                        Write-Host "`t1. " -NoNewline
                        Write-Host "Beskyttede OU'er" -Fore Cyan
                        Write-Host "`t2. " -NoNewline
                        Write-Host "Ubeskyttede OU'er" -Fore Cyan
                        $valg = Read-Host "`nValg"
                            if ( $valg -ne "1" -and $valg -ne "2" ) { 
                                Write-Host "`n`tUgyldig verdi"    -Fore Red
                            }
                    } while ($valg -ne "1" -and $valg -ne "2" )

                    if ($valg -eq "1") { $verdi = $true }
                    if ($valg -eq "2") { $verdi = $false }

                    try {
                        $OUer = OUBeskyttet $verdi 
                            if ($OUer) {
                                Write-Host "`n`tFant følgende OU'er" -Fore Green
                                $OUer
                            }
                            else { Write-Host "`n`tFant ingen OU'er" -Fore Yellow }
                    } 
                    catch { FeilMelding }

                 prompt_OUMeny
                
                } #Slutt 6 - List alle OU som har ProtectedFromAccidentalDeletion Enabled / Disabled

                7 { #Beskytt alle OU'er i AD mot uhelldig sletting

                        Write-Host "`nEr du sikker på at du ønsker å sette beskyttelse `nmot uhelldig sletting på " -NoNewline -Fore Red
                        Write-Host "alle" -NoNewline
                        Write-Host " OU'er?`n" -Fore Red
                            ErDuHeltSikker?

                    try {
                        if ($script:valg -eq "j") {
                            Write-Host "`nPrøver sette på beskyttelse mot uhelldig sletting" -Fore Yellow
                            Get-ADOrganizationalUnit  -Filter * | Set-ADObject -ProtectedFromAccidentalDeletion $true -Confirm:$false
                                if ($?) {Write-Host "`n`tAlle OU'er ble beskyttet suksessfullt" -Fore Green}
                        }
                        else { RealoadOUMeny }

                    } catch { FeilMelding } #Viser feilmelding}

                prompt_OUMeny

                } #Slutt 7 - Beskytt alle OU'er i AD mot uhelldig sletting

                8 { #Fjern beskyttelse mot uhelldig sletting på alle OU

                    Write-Host "`n`tDette endrer egenskapen 'ProtectedFromAccidentalDeletion' fra 'True' 
    til 'False' på alle OrganizationalUnits i hele Active Directory.`n" -Fore Red

                    Write-Host "`tEr du helt sikker på at du ønsker å gjøre dette?`n" -Fore Cyan
                
                    ErDuHeltSikker?

                    if ($script:valg -eq "j") {

                        try {
                        #Kode er hentet fra https://gallery.technet.microsoft.com/scriptcenter/Organizational-Units-7b3ff0bc
                            Get-ADOrganizationalUnit -filter * `
                            -Properties ProtectedFromAccidentalDeletion | 
                            where {$_.ProtectedFromAccidentalDeletion -eq $true} | 
                            Set-ADOrganizationalUnit -ProtectedFromAccidentalDeletion $false

                                if ($?) { Write-Host "`n`tUtføring av kommando gikk suksessfullt" -Fore Green }
                        }

                        catch { FeilMelding } #Henter feilmelding

                    }
                    else { RealoadOUMeny }

                   prompt_OUMeny

                } #Slutt 8 - Fjern beskyttelse mot uhelldig sletting på alle OU

                9 { LastInnMeny }
            
            } #Slutt switch
        } #Slutt funksjon VisOUMeny

        VisOUMeny #Kjører funksjonen

      } #Slutt menyalternativ 7 - OU-administrasjon

        8  { #Menyalternativ 8 - 'Vis Domenestruktur'
            
                $Forest                  = HentDomeneEgenskap Forest
                $DNSRoot                 = HentDomeneEgenskap DNSRoot
                $DomainMode              = HentDomeneEgenskap DomainMode
                $ObjektKlasse            = HentDomeneEgenskap ObjectClass
                $NavnBarneDomener        = HentDomeneEgenskap ChildDomains
                $InfraStructureMaster    = HentDomeneEgenskap InfraStructureMaster
                $ReplicaDirectoryServers = HentDomeneEgenskap ReplicaDirectoryServers
                $OperatingMasterRoles    = HentDomeneEgenskap OperationMasterRoles
                $AntallBarneDomener      = (HentDomeneEgenskap ChildDomains).Count
                $AntallDomeneKontrollere = $AntallDomeneKontrollere+" stk"

                $t2                   = "`t`t"        #Disse lager et tab mellomrom
                $t3                   = "`t`t`t"      #for hver 't'
                $t5                   =  "`t`t`t`t`t" #Lager mellomrom for 'Domenekontrollere'

                [INT] $AntallMenyAlternativer = 1 #Antall alternativer i undermeny

            [STRING] $sti = "Hovedmeny / Vis DomeneKontrollerStruktur /"
			    while ( $MenyDomeneStruktur -lt 1 -or $MenyDomeneStruktur -gt $AntallMenyAlternativer ) {
				    Clear-Host
				    Write-Host " $appNavn "                                -Fore Magenta
                    Write-Host "`tDu står i:"                   -NoNewline -Fore Cyan
                    Write-Host " $sti`n"

                    Write-Host "$t2`Oversikt over domenestruktur`n"        -Fore Cyan

                    Write-Host "$t3`Forest:                   " -NoNewline -Fore Cyan; Write-Host $Forest
                    Write-Host "$t3`DNS Root:                 " -NoNewline -Fore Cyan; Write-Host $DNSRoot
                    Write-Host "$t3`Domainmode:               " -NoNewline -Fore Cyan; Write-Host $DomainMode
                    Write-Host "$t3`Objekt klasse:            " -NoNewline -Fore Cyan; Write-Host $ObjektKlasse
                    Write-Host "$t3`Antall domenekontrollere: " -NoNewline -Fore Cyan; Write-Host $AntallDomeneKontrollere
                    Write-Host "$t3`Antall barnedomener:      " -NoNewline -Fore Cyan; Write-Host $AntallBarneDomener
                    Write-Host "$t3`Navn barnedomener:        " -NoNewline -Fore Cyan; Write-Host $NavnBarneDomener
                    Write-Host "$t3`InfrastructureMaster:     " -NoNewline -Fore Cyan; Write-Host $InfraStructureMaster
                    Write-Host "$t3`OperationMasterRole:      " -NoNewline -Fore Cyan; Write-Host $OperatingMasterRoles
                    Write-Host "$t3`ReplicaDirectoryServers:  " -NoNewline -Fore Cyan

                        Try {
                            $teller = 1
                                
                                #For hver server i egenskapen 'ReplicaDirectoryServers'
                                #skal det skrives ut navnet på server
                                foreach ($server in $ReplicaDirectoryServers) {
                                    if ($teller -eq "1") { 
                                        Write-Host "$teller. $server"
                                    } else { 
                                        Write-Host "`t`t`t`t`t`t`t`t`t  $teller. $server"
                                    }
                                    $teller++ #Øker teller med 1 slik at domenekontroller nr2
                                              #får tallet 2 foran seg.
                                }
                        } Catch { } #Catcher ingenting.

                        #Prøver å hente alle servere som er domenekontroller
                        Try { 
                            $AlleDomeneKontrollere = Get-ADGroupMember 'Domain Controllers'
                        } Catch { 
                            #Viser feilmelding på skjermen med rød skrift.
                            Write-Host "`n`n$t3`Kommandoen 'Get-ADGroupMember ble ikke gjenkjent.`n" -Fore Red
                          }

                    #Det kan tenkes at en bedrift har flere eller mindre enn 3 domenekontrollere.
                    #Det kan lages funksjon som teller hvor mange DC'er, for deretter generere pyramider
                    #som visualiserer strukturen. Jeg har tatt utgangspunkt i 3 domenekontrollere.

                    #Splitter først domenenavnet. Her er f.eks. variabelen 'domene.com'
                    $Del1,$Del2 = $domene.split('.')
                    #'Del1' er første del av domenenavn, f.eks. 'domene'
                    #'Del2' er andre del av domenenavn, f.eks. 'com'

                    #Fjerner unødvendig tekst
                    $domeneNavn = $AlleDomeneKontrollere -replace "CN=" `
                                                         -replace $Del1 `
                                                         -replace $Del2 `
                                                         -replace ",ou=Domain Controllers" `
                                                         -replace ",dc=" `
                                                         -replace ",dc="

                    $DC1,$DC2,$DC3 = $domeneNavn.split('.')

                    Write-Host "`n`n$t5`  Domenekontrollere`n" -Fore Yellow

                        #Dersom domenenavnet er mindre eller lik 8 bokstaver settes lengden til 10.
                        #Dette gjøres for å skape en litt større pyramide.

                        if (($DC1.Length) -eq 8 -or ($DC1.Length) -lt 8) { $antallTegn = 10 }
                        else { $antallTegn =  $DC1.Length }

                        #Dersom antall tegn er større enn 15 kuttes det litt ned
                        if ( $antallTegn -gt 15) { $antallTegn = 12 }

                        #Sjekker om tallet er et oddetall. Dersom det er det legges det til et tall
                        #slik at det blir et partall. Dette gjøres for at pyramiden som genereres
                        #ikke skal få rette linjer så det bli presentert på en pen måte, alltid.
                        if ($antallTegn % 2 -eq 1 ) { $antallTegn++ }

                        $max = ($antallTegn * 1.5)

                        # Variabelen '$_' betyr gjeldende verdi i pipelinen.
                        #Bruker minus 1, slik at den øverste trekanten får en litt
                        #mindre trekant slik at det ser smooth ut langs kantene
                            1..($max-1) | % {
                                ' ' * $max        + #Lager et rektangel på venstre side
                                ' ' * ($max - $_) + #Skreller vekk en trekant
                                '^' * ($_ * 2)      #Ganger '^' tegnet med (gjeldende verdi * 2)
                             }

                            #I en loop fra '1' til maks '1' utføres det 'foreach-object'
                            1..1 | %  { 
                                $mellomrom = $max * 4.4
                                $Avstand = (($mellomrom - $antallTegn) / 2) #pluss?
                                ' ' * $Avstand +
                                $DC1 #navnet på 1. domenekontroller
                             }

                            #Fra 1 til tallet $max | foreach tall
                            1..$max | % { 
                                ' ' * ($max - $_) + 
                                "'" * ($_ * 2 - 1) + 
                                ' ' * ($max - $_) + 
                                "  " + #Legger til to mellomrom mellom de to nederste pyramidene
                                ' ' * ($max - $_) + 
                                "'" * ($_ * 2 - 1)
                                #' ' * ($max - $_) #Lager en halv trekant som er gjennomsiktig, lar denne stå
                             }

                            #Fra 1 til tallet 1 | foreach tall:
                            1..1 | % {
                                $antallTegnDomene2 = $DC2.Length
                                $HeleAvstanden     = ($max * 2) + 1           #Legger til antallet + et mellomrom
                                $Avstand1          = ($HeleAvstanden / 8) * 2 #Avstand fra marg til første navn
                                $Avstand2          = $Avstand1 / 2
                                ' ' * $Avstand1 +
                                $DC2 +
                                ' ' * ($HeleAvstanden - $antallTegnDomene2) +
                                $DC3 
                            }

				Write-Host "`n$t2`Velg mellom følgende administrative oppgaver`n" -Fore Cyan
                Write-Host "$t3`1. Tilbake`n"

		    [int]$MenyDomeneStruktur = Read-Host "`t`t`tUtfør" #Henter respons fra bruker
                if ( $MenyDomeneStruktur -lt 1 -or $MenyDomeneStruktur -gt $AntallMenyAlternativer ){
                    Write-Host $feilmelding -Fore Red; Sleep -Seconds $VentSekunder
		        }
            } #Slutt While

            Switch ($MenyDomeneStruktur){

				1 { LastInnMeny }

                #2 { } #Det kan legges til funksjonalitet. Tips til funksjonalitet kan være
                       #å vise mer detaljert informasjon om hver domenekontroller

                #3 { }

                #4 { }
            
            } #Slutt switch
      } #Slutt menyalternativ 8 - Vis domenestruktur

        9  { #Menyalternativ 9 - 'Backup'

            [int]    $AntallMenyAlternativer = 7 #Antall alternativer i undermeny
            [string] $sti = "Hovedmeny / Backup /"
            [string] $t3  = "`t`t`t"   #Gir 3 tabulator mellomrom
            [string] $t4  = "`t`t`t`t" #Gir 4 tabulator mellomrom

            #Funksjon som gir bruker mulighet til å trykke 'enter'
            #før brukeren får lastet inn menyen på nytt.
            function Prompt_MenyBackup {
                Read-Host "`n`tTrykk 'enter' for å gå tilbake"
                $MenyBackup = 0
                BackupMeny
            }

            #Funksjon som laster inn backupmenyen med en gang
            function Reload_MenyBackup {
                $MenyBackup = 0
                BackupMeny
            }
         
         Function BackupMeny {

            while ( $MenyBackup -lt 1 -or $MenyBackup -gt $AntallMenyAlternativer ) {

			    Clear-Host
				Write-Host " $appNavn "                                         -Fore Magenta
                Write-Host "`tDu står i:"                            -NoNewline -Fore Cyan
                Write-Host " $sti`n"
				Write-Host "`t`tVelg mellom følgende administrative oppgaver`n" -Fore Cyan
                Write-Host "$t3`1. Installer Windows Server Backup`n"           -Fore Cyan
                Write-Host "$t3`2. "                                 -NoNewline -Fore Cyan
                Write-Host "Avinstaller"                             -NoNewline -Fore Red
                Write-Host " Windows Server Backup`n"                           -Fore Cyan

                Write-Host "$t3`3. Vis Backup Policy på server`n"               -Fore Cyan
                Write-Host "$t3`4. Vis utførte Backup operasjoner`n"            -Fore Cyan
                Write-Host "$t3`5. Vis interne og eksterne harddisker
               som er online for lokal server`n"                                -Fore Cyan

               

                Write-Host "$t3`6. Konfigurer backup"                           -Fore Cyan
                    Write-Host "$t4`Navn på policy:          "      -NoNewline; Write-Host "(krever input)"
                    Write-Host "$t4`Disk for lagring:        "      -NoNewline; Write-Host "(krever input)"

                    #Legg merke til at de tre neste punktene under ikke er på samme 'inje' som de over og under.
                    #Dette er gjort med vilje for å øke sjekkpunktet med et ekstra mellomrom i mot høyre.

                    Write-Host "$t4`Kritiske volum:           "     -NoNewline; Write-Host @SjekkPunkt
                    Write-Host "$t4`Legg til systemtilstand:  "     -NoNewline; Write-Host @SjekkPunkt
                    Write-Host "$t4`Kjøres med en gang:       "     -NoNewline; Write-Host @SjekkPunkt
                    Write-Host "$t4`Legge til i tidsplan:    "      -NoNewline; Write-Host "(krever input)"
                    Write-Host "$t4`Utfør etter XX minutter: "      -NoNewline; Write-Host "(krever input)"
                Write-Host "`n$t3`7. Tilbake`n"                                 -Fore Cyan


				[int]$MenyBackup = Read-Host "`t`tUtfør alternativ"

				if( $MenyBackup -lt 1 -or $MenyBackup -gt $AntallMenyAlternativer ){
					Write-Host $feilmelding -Fore Red; Sleep -Seconds $VentSekunder
				}
			}

			Switch ($MenyBackup) {

				1 { #Installer Windows Server Backup
                    
                    Try {
                    Write-Host "`n`tPrøver å installere Windows Server Backup“ -Fore Yellow
                    $sjekk = Get-WindowsFeature -Name "Windows-Server-Backup"
                        if ($sjekk.Installed -ne "true") { #Sjekker om tjenesten IKKE er installert
                            Write-Host "`nHelt sikker på du ønsker å installere Windows Server Backup? J/N" -Fore Yellow
                                ErDuHeltSikker? #Funksjon som retunerner 'j' eller 'n'
                                Write-Host ""   #Lager et mellomrom mellom svaret J/N og output.
                                if ($valg -eq "j") {
                                    try {
                                        Install-WindowsFeature -Name "Windows-Server-Backup" -IncludeAllSubFeature -Verbose
                                            if ($?) { #Sjekker om installeringen gikk fint
                                                Write-Host $Suksessfull_installering -Fore Green
                                            }
                                    } catch { FeilMelding }
                                } #Hvis valget er noe annet enn ja
                                else { Reload_MenyBackup }
                        } #Hvis tjenesten allerede er installert
                        else { Write-Host $ErInstallert -Fore Green } #Dersom den er installert får bruker beskjed

                    } Catch { FeilMelding }

                    prompt_MenyBackup
                } #Slutt 1 - Installer Windows Server Backup

                2 { #Avnstaller Windows Server Backup

                    Try {
                    Write-Host "`n`tPrøver å avinstallere Windows Server Backup“ -Fore Yellow
                    $sjekk = Get-WindowsFeature -Name "Windows-Server-Backup"
                        if ($sjekk.Installed -eq "true") {
                            Write-Host "`nHelt sikker på du ønsker å avinstallere Windows Server Backup? J/N" -Fore Red
                                ErDuHeltSikker? #Funksjon som retunerner 'j' eller 'n'
                                Write-Host ""   #Lager et mellomrom mellom svaret J/N og output.
                                if ($valg -eq "j") {
                                    try {
                                        Remove-WindowsFeature -Name "Windows-Server-Backup" -Verbose
                                            if ($?) { #Sjekker om avinstalleringen gikk fint
                                                Write-Host $Suksessfull_AVinstallering -Fore Green
                                        }
                                    } catch { FeilMelding }
                                } #Hvis valget er noe annet enn ja
                                else { Reload_MenyBackup }
                        } #Hvis tjenesten allerede er installert
                        else { Write-Host $Allerede_Avinstallert -Fore Green }

                    } Catch { FeilMelding }

                    prompt_MenyBackup
                } #Slutt 2 - Avnstaller Windows Server Backup

                3 { #Vis Backup Policy på server
                    Try {
                        $BackupPolicy = Get-WBPolicy
                            If ($BackupPolicy -eq $null) {
                                Write-Host "`n`tFant ingen Backup Policy på server!" -Fore Yellow
                            }
                            else { $BackupPolicy }
                    } Catch { FeilMelding }

                  Prompt_MenyBackup #Trykk 'enter' for å gå tilbake til meny

                } #Slutt 3 - Vis Backup Policy på server

                4 { #Vis utførte Backup operasjoner
                    Try {
                        $BackupHistorie = Get-WBSummary
                            If ($BackupHistorie -eq $null) {
                                Write-Host "`n`tFant ingen Backup historie på server!" -Fore Yellow
                            }
                            else { 
                                Write-Host "`n`tFant følgende backuphistorie:`n" -Fore Cyan
                                $BackupHistorie
                            }
                    } Catch { FeilMelding }

                  Prompt_MenyBackup #Trykk 'enter' for å gå tilbake til meny
                
                } #Slutt 4 - Vis utførte Backup operasjoner

                5 { #Vis interne og eksterne harddisker

                    Try {
                        $DiskerOnline = Get-WBDisk
                            If ($DiskerOnline -eq $null) {
                                Write-Host "`n`tFant ingen disker på server!" -Fore Yellow
                            }
                            else { 
                                Write-Host "`n`tFant følgende disker:`n" -Fore Cyan
                                $DiskerOnline }
                    } Catch { FeilMelding }

                    Prompt_MenyBackup #Trykk 'enter' for å gå tilbake til meny

                } #Slutt 5 - Vis interne og eksterne harddisker

                6 { #Konfigurer backup
                    Try {
                        Write-Host "`n`tKonfigurer backup" -Fore Yellow
                    
                    do {
                        Write-Host "`nHva skal policyen hete?" -Fore Cyan
                            SkrivNavn #Funksjon der bruker MÅ skrive inn noe
                        
                        do {
                        Write-Host "`nHvor skal backupen lagres?" -Fore Cyan
                            
                            #Henter alle tilgjengelige volum
                            $AlleVolum = Get-WBVolume -AllVolumes

                            Foreach ($Volum in $AlleVolum) { #For hvert eneste volum 

                                $VolumNavn  = $Volum | Select -ExpandProperty VolumeLabel
                                $Bokstav    = $Volum | Select -ExpandProperty MountPath

                                    if ($Bokstav -eq "") { $Bokstav = "(Ingen bokstav)" }

                                $FilSystem  = $Volum | Select -ExpandProperty FileSystem
                                $LedigPlass = $Volum | Select -ExpandProperty FreeSpace
                                #Regner ut i antall GigaByte
                                #$LedigPlass = "{0:N2}" -f ($LedigPlass.FreeSpace/1GB) 
                                
                                $LedigPlass = $LedigPlass / 1GB

                                #Kutter ned antall desimaler, slik at det bare blir et desimal
                                $LedigPlass = [math]::Round($LedigPlass,1)
                                
                                $TotalPlass = $Volum | Select -ExpandProperty TotalSpace
                              
                                #Regner ut i antall GigaByte
                                $TotalPlass = $TotalPlass / 1GB

                                #Kutter ned antall desimaler, slik at det bare blir et desimal
                                $TotalPlass = [math]::Round($TotalPlass,1)

                                Write-Host "`n`tVolum navn: " -NoNewline -Fore Cyan; Write-Host $VolumNavn
                                Write-Host "`tBokstav:      " -NoNewline -Fore Cyan; Write-Host $Bokstav
                                Write-Host "`tFilsystem:    " -NoNewline -Fore Cyan; Write-Host $FilSystem
                                Write-Host "`tLedig plass:  " -NoNewline -Fore Cyan; Write-Host "$LedigPlass GB"
                                Write-Host "`tTotal plass:  " -NoNewline -Fore Cyan; Write-Host "$TotalPlass GB"
                            }
                                
                                $Path = Read-Host "`n`tSti"

                                    if ($Path -eq "") {
                                        Write-Host "`n`tStien kan ikke være tom" -Fore Red
                                        $GyldigPath = $false
                                    }
                                    else {
                                        $GyldigPath = Test-Path $Path
                                            if ($GyldigPath -eq $false) {
                                                Write-Host "`n`tStien '$Path' er ikke gyldig!" -Fore Red
                                            }
                                    }
                            } while ($GyldigPath -ne $true) #Utføres så lenge pathen ikke er gyldig

                        Write-Host "`nLegge til backup i tidsplan? J/N" -Fore Cyan
                            ErDuHeltSikker?

                            if ($valg -eq "j") {
                                do {
                                    Write-Host "`nHvor mange minutter mellom hver utføring?" -Fore Cyan
                                    [int] $Minutter = Read-Host "`tAntall minutter"
                                        if ($Minutter -eq "") {
                                            Write-Host "`n`tVennligst spesifiser hvor mange minutter" -Fore Red
                                        }
                                } while ($Minutter -eq "")

                            }
                        Write-Host "`nOppsummering av konfigurasjon" -Fore Cyan
                        Write-Host "`n`tPolicynavn: " -NoNewline -Fore Cyan; Write-Host $navn
                        Write-Host "`tLagringssti: "    -NoNewline -Fore Cyan; Write-Host $Path

                            if ($valg -eq "j") {
                                Write-Host "`tLegge til i tidsplan: " -NoNewline -Fore Cyan ; Write-Host "Ja"
                                Write-Host "`tKjøres hvert "          -NoNewline -Fore Cyan
                                Write-Host $Minutter -NoNewline
                                Write-Host ". minutt" -Fore Cyan
                            }
                            else {
                                Write-Host "`tLegges til i tidsplan: " -NoNewline -Fore Cyan ; Write-Host "Nei"
                            }
                        Write-Host "`nEr disse innstillingene korrekt? J/N" -Fore Yellow
                        ErDuHeltSikker? #Funksjon der bruker må velge 'j' eller 'n'

                    } while ($valg -eq "n")

                    #Koden ovenfor gjentas så lenge bruker velger 'n'. Dersom bruker velger 'j'
                    #kjøres koden nedenfor, derfor trengs det ikke en sjekk om variabelen $valg er 'j'

                        try {
                            #Legger til policynavnet som en ny policy
                            $navn = New-WBPolicy
                        
                        #Legger til volum i policyen
                        Add-WBVolume -Policy $navn -Volume (Get-WBVolume -CriticalVolumes) | Out-Null

                        #Deklarer hvor backupen skal lagres
                        $BackupLokasjon = New-WBBackupTarget -VolumePath $Path

                        #Legg til systemtilstand
                        Add-WBSystemState -Policy $navn | Out-Null

                        #Legger til backuplokasjonen til policy
                        Add-WBBackupTarget -Policy $navn -Target $BackupLokasjon | Out-Null

                     

                      #Dersom variabelen 'Minutter' er satt, betyr det at
                      #bruker ønsker å legge til backupen i tidsskjema
                      if ($Minutter) {
                        $Tid = ([datetime]::Now.AddMinutes($Minutter))
                        Write-Host "`nTid for neste kjøring av backup er: " -NoNewline -Fore Cyan; Write-Host $Tid

                        #Setter schedule til datoen + 34 minutter. Bruker 'Out-Null' for
                        #ikke å vise noe output til brukeren.
                        Set-WBSchedule -Policy $navn -Schedule ([datetime]::Now.AddMinutes($Minutter)) | Out-Null
                      }

                         #starter backupen
                        Start-WBBackup -Policy $navn 
                        if ($?) {
                            Write-Host "`n`tBackupen har blitt utført!" -Fore Green
                        }
                        } catch { FeilMelding }


                    } Catch { FeilMelding }

                  Prompt_MenyBackup

                } #Slutt 6 - Konfigurer backup

                7 { LastInnMeny }

            } #Slutt switch

         }#Slutt funksjon BackupMeny

            BackupMeny #Kaller på funksjonen

      } #Slutt menyalternativ 9 - Backup

        10 { #Menyalternativ 10 - 'Opprett ulike testmiljø for server'

        function Reload_MenyTestmiljo {
            $MenyTestmiljo = 0 #Setter variabelen til 0 slik at ingen av casene er valgt
            Opprett_test_miljo #Kaller på hele menyen
        }

        function prompt_MenyTestmiljo { #Gir brukeren mulig til å lese output før h*n må trykke 'enter'
            Read-Host "`nTrykk 'enter' for gå tilbake" #Gir brukeren mulighet til å lese feilmelding på skjerm
            $MenyTestmiljo = 0
            Opprett_test_miljo
        }

        function Opprett_test_miljo { #Funksjon av hele menyen

            [int] $AntallMenyAlternativer = 4 #Antall alternativer i undermeny 9
         [string] $sti = "Hovedmeny / Opprett ulike testmiljø for AD /"
         [string] $t = "`t`t`t`t`t" #For hver '`t' lages det litt mellomrom

            while ( $MenyTestmiljo -lt 1 -or $MenyTestmiljo -gt $AntallMenyAlternativer ){
			    Clear-Host
				Write-Host " $appNavn "                                                    -Fore Magenta
                Write-Host "`tDu står i:"                                       -NoNewline -Fore Cyan
                Write-Host " $sti`n"
				Write-Host "`t`tVelg mellom følgende administrative oppgaver`n"            -Fore Cyan

				Write-Host "`t`t`t1.  Testmiljø 1 for WS. 2016 - Domenekontroller Ice"     -Fore Cyan
				    Write-Host "$t`Domenenavn: "                                -NoNewline -Fore Cyan; Write-Host "Ice.local"
                    Write-Host "$t`SafeModeAdmin passord: "                     -NoNewline -Fore Cyan; Write-Host "(Krever input fra bruker)"
                    Write-Host "$t`Domainmode: "                                -NoNewline -Fore Cyan; Write-Host "Win2016"
                    Write-Host "$t`ForestMode: "                                -NoNewline -Fore Cyan; Write-Host "Win2016"
                    Write-Host "$t`DatabasePath: "                              -NoNewline -Fore Cyan; Write-Host "'%SYSTEMROOT%\NTDS'"
                    Write-Host "$t`LogPath "                                    -NoNewline -Fore Cyan; Write-Host "'%SYSTEMROOT%\NTDS'"
                    Write-Host "$t`SysvolPath "                                 -NoNewline -Fore Cyan; Write-Host "'%SYSTEMROOT%\SYSVOL'"
                    Write-Host "$t`Automatisk restart etter installering: "     -NoNewline -Fore Cyan; Write-Host "Ja"
                    Write-Host "$t`Installering av DNS: "                       -NoNewline -Fore Cyan
                    Write-Host "Ja`n"
                    Write-Host "$t`Krever restart av server for å fullføre installasjon`n" -Fore Yellow

				Write-Host "`t`t`t2.  Testmiljø 2 - "                           -NoNewline -Fore Cyan
                    Write-Host "Apple"
                    Write-Host "$t`Organizational Units: "      -Fore Cyan
                    Write-Host "$t`t- Apple-Salg"
                    Write-Host "$t`t- Apple-Produksjon"
                    Write-Host "$t`t- Apple-Regnskap"
                    Write-Host "$t`t- Apple-Ledelse"
                    Write-Host "$t`Datamaskiner: "             -Fore Cyan
                    Write-Host "$t`t- 16 stk (4 i hver avdeling)"
                    Write-Host "$t`Brukere: "                  -Fore Cyan
                    Write-Host "$t`t- 4 stk i Salg"
                    Write-Host "$t`t- 4 stk i produksjon"
                    Write-Host "$t`t- 4 stk i regnskap"
                    Write-Host "$t`t- 4 stk i ledelse`n"

				Write-Host "`t`t`t3.  Opprett CSV-fil"          -Fore Cyan
                    Write-Host "$t`Path: "           -NoNewline -Fore Cyan
                    Write-Host "C:\Brukere.csv"
                    Write-Host "$t`Antall brukere: " -NoNewline -Fore Cyan
                    Write-Host "21"
                    Write-Host "$t`Passord: "        -NoNewline -Fore Cyan
                    Write-Host "Passord1234"
                    Write-Host "$t`Avdelinger: "                -Fore Cyan
                    Write-Host "$t`t- Salg"
                    Write-Host "$t`t- Administrasjon"
                    Write-Host "$t`t- Produksjon"
                    Write-Host "$t`t- IT`n"

                Write-Host "`t`t`t4.  Tilbake`n"                -Fore Cyan

				[int]$MenyTestmiljo = Read-Host "`t`tUtfør alternativ"
				if( $MenyTestmiljo -lt 1 -or $MenyTestmiljo -gt $AntallMenyAlternativer ) {
					Write-Host $feilmelding -Fore Red; Sleep -Seconds $VentSekunder
				}
			}
			Switch ($MenyTestmiljo) {

				1 { #Opprett testmiljø 1

                    #Sjekk om AD Certificate Server er installert
                    $sjekk = Get-WindowsFeature -Name "AD-Certificate"
                        if ($sjekk.Installed -eq "true") { 
                              Write-Host "`nKunne ike opprette Forest siden AD Certificate Server er installert." -Fore Red
                              Write-Host "Avinstaller tjenesten for å ha mulighet til å fortsette."               -Fore Red
                              prompt_MenyTestmiljo #Funksjon som ber bruker trykke 'enter' for å reloade menyen
                        }
                        else {
                            Write-Host "`nEr du helt sikker på at du ønsker å opprette 'test miljø 1'? Ja/nei" -Fore Yellow
                                ErDuHeltSikker?
                                    if ($valg -eq "j") { 
                                        Install-ADDSForest `
                                        -DomainName "ice.local" `
                                        -SafeModeAdministratorPassword (Read-Host -Prompt “Safe Mode passord" -AsSecureString) `
                                        -DomainMode "7" `
                                        -ForestMode "7" `
                                        -DatabasePath “%SYSTEMROOT%\NTDS" `
                                        -LogPath "%SYSTEMROOT%\NTDS" `
                                        -SysvolPath "%SYSTEMROOT%\SYSVOL" `
                                        -NoRebootOnCompletion:$false `
                                        -InstallDns -Force

                                        prompt_MenyTestmiljo
                                    }
                                    else { Reload_MenyTestmiljo } #Laster inn menyen på nytt
                                    }
                } ##Opprett testmiljø 1

                2 { #Testmiljø 2
                    
                    Write-Host "`nEr du helt sikker på du ønsker å legge til testmiljøet på server?" -Fore Yellow
                        ErDuHeltSikker?
                            if ($valg -eq "n") { Reload_MenyTestmiljo } #Hvis bruker ikke ønsker å legges til lastes menyen på nytt
                            else {
                                try {
                                    Write-Host "" #Lager mellomrom mellom J/N svaret.

                                    #Oppretter funksjon som lager OU med paramtereret $navn
                                    function LagAppleOU ($script:navnOU) { 
                                        NEW-ADOrganizationalUnit $script:navnOU -ProtectedFromAccidentalDeletion $false
                                            if ($?) {Write-Host "`tOpprettet OU '$script:navnOU'" -Fore Green}
                                    }

                                    #Funksjon som lager 5 datamaskiner
                                    function OpprettAppleMaskin ($script:navnOU) {
                               
                                        for ($i=1; $i -lt 5; $i++) { #For hvert tall fra 1 til 10
                                            $maskin = $script:navnOU+$i #Legger til navn+tall

                                        FinnDistinguishedNameOU

                                            #Kode som legger til datamaskin
                                            New-ADComputer -Name $maskin -path $script:DistinguishedName -Enabled $true -Confirm:$false
                                                #Gir tilbakemelding til bruker
                                                if ($?) {Write-Host "`tOpprettet maskin '$maskin'" -Fore Green}
                                        }
                                    }

                                    function LeggTilBruker ($script:navnOU) {

                                        FinnDistinguishedNameOU

                                        for ($i=1; $i -lt 5; $i++) {
                                            
                                            #Bruker sekunder og ms for å lage unike navn
                                            $ms = Get-Date -Format sfff
                                            $fornavn = "fornavn"+$ms
                                            $BrukerNavn = "bruk"+$ms

                                                try {
                                                    #Konverterer passordet
                                                    $passord = "Passord123?" | ConvertTo-SecureString -AsPlainText -Force 

                                                    New-ADUser                  `
                                                    -Name $fornavn           `
                                                    -GivenName $fornavn      `
                                                    -Surname $BrukerNavn        `
                                                    -SamAccountName $brukernavn `
                                                    -DisplayName $brukernavn    `
                                                    -AccountPassword $passord   `
                                                    -Path $script:DistinguishedName

                                                        if ($?) {Write-Host "`n`tBruker '$fornavn $etternavn' ble opprettet suksessfullt i OU '$script:DistinguishedName'" -Fore Green }

                                                } Catch { FeilMelding }
                                        }
                                        
                                    }#/LeggTilBruker

                                    #Oppretter navn, lager OU og lager datamaskin
                                    Try {
                                        $script:navnOU = "Apple-Salg";       LagAppleOU         $script:navnOU
                                                                             OpprettAppleMaskin $script:navnOU
                                                                             LeggTilBruker      $script:navnOU

                                        $script:navnOU = "Apple-Produksjon"; LagAppleOU         $script:navnOU
                                                                             OpprettAppleMaskin $script:navnOU
                                                                             LeggTilBruker      $script:navnOU

                                        $script:navnOU = "Apple-Regnskap";   LagAppleOU         $script:navnOU
                                                                             OpprettAppleMaskin $script:navnOU
                                                                             LeggTilBruker      $script:navnOU

                                        $script:navnOU = "Apple-Ledelse";    LagAppleOU         $script:navnOU
                                                                             OpprettAppleMaskin $script:navnOU
                                                                             LeggTilBruker      $script:navnOU
                                    } Catch { FeilMelding }


                                } Catch { FeilMelding }  #Henter feilmelding
                            }

                    prompt_MenyTestmiljo

                } #Testmiljø 2
                
                3 { #Opprett CSV-fil
                    $CSVpath = "C:\Brukere.csv" #Lagrer en standard verdi for path
                        if ((Test-Path $CSVpath) -eq $true) { #Tester om de eksisterer en fil der
                            #Dersom det finnes en fil ønsker kanskje bruker å slette den?
                            Write-Host "`nDet finnes allerede en fil $CSVpath`n" -Fore Red
                            Write-Host "Skal jeg slette den?" -Fore Yellow
                                ErDuHeltSikker? #Funksjon som retunerer 'j' eller 'n'
                                    if ($valg -eq "j") {
                                        try { #'RM' er alias for 'Remove-Item'
                                            RM $CSVpath -Force #Tvinger sletting av fil
                                                if ($?) { Write-Host "`n`tFila ble slettet" -Fore Green }
                                        } catch { FeilMelding }
                                    } #hvis bruker ikke ønsker å slette fil:
                                    else { Reload_MenyTestmiljo } #Laster inn hele menyen med en gang
                        }
                        
                        #Oppretter ny fi. 'NI' er alias for 'New-Item'
                        NI $CSVpath -ItemType File | Out-Null

                                $Avdeling_1 = "Salg"
                                $Avdeling_2 = "Administrasjon"
                                $Avdeling_3 = "Produksjon"
                                $Avdeling_4 = "IT"
                                $Passord = "Passord1234"
#Følgende innhold legges til csv-fil:
$Innhold = “
Henrik1;Johnsen1;$Avdeling_1;$Passord.
henrik2;Johnsen2;$Avdeling_1;$Passord.
henrik3;Johnsen3;$Avdeling_1;$Passord.
henrik4;Johnsen4;$Avdeling_2;$Passord.
henrik5;Johnsen5;$Avdeling_2;$Passord.
Herb;Biff1;$Avdeling_2;$Passord.
Annu;Biff2;$Avdeling_2;$Passord.
Anne;Biff3;$Avdeling_2;$Passord.
henrik6;Johnsen6;$Avdeling_3;$Passord.
henrik7;Johnsen7;$Avdeling_3;$Passord.
henrik8;Johnsen8;$Avdeling_3;$Passord.
henrik9;Johnsen9;$Avdeling_3;$Passord.
Mia1;Pettersen1;$Avdeling_3;$Passord.
Mia2;Pettersen2;$Avdeling_3;$Passord.
Mia3;Pettersen3;$Avdeling_3;$Passord.
henrik10;Johnsen10;$Avdeling_4;$Passord.
Ola;Johnsen11;$Avdeling_4;$Passord.
Ole;Johnsen12;$Avdeling_4;$Passord.
Ottar;Johnsrud1;$Avdeling_4;$Passord.
Martin2;Johnsrud2;$Avdeling_4;$Passord.
Martin3;Johnsrud3;$Avdeling_4;$Passord.
" #Hvis det brukes tabulator for å skyve koden lenger til høyre
  #oppstår det mellomrom i fila. Derfor må det stå slik det står.

                                    #Kode for å legger til innholdet i fil
                                    Set-Content $CSVpath -Value $Innhold -Force
                                        if ($?) { Write-Host "`n`tOpprettet CSV-fil sukessfullt" -Fore Green }
                                            Write-Host "`nØnsker du å vise innholdet?" -Fore Cyan
                                                ErDuHeltSikker?
                                                    if ($valg -eq "j") {
                                                        Write-Host "`nInnholdet er følgende:`n" -Fore Cyan
                                                        Get-Content $CSVpath
                                                        prompt_MenyTestmiljo
                                                     }
                                                     else { Reload_MenyTestmiljo }
                } #Opprett CSV-fil

                4 { LastInnMeny } #Går tilbake til hovedmeny

            } #Slutt Switch
        } #Slutt function Opprett_test_miljo

            Opprett_test_miljo #Kaller på funksjonen slik at undermenyen vises

         } #Slutt menyalternativ 10 - Opprett ulike testmiljø for server

        11 { #Menyalternativ 11 - 'Eksporter AD statistikk til rapport'
            
            Function Prompt_Statistikk_Meny {
                Read-Host "`nTrykk 'enter' for å gå tilbake"

                #Resetter valg for bruker. Hvis denne ikke settes til '0'
                #vil samme kommando utføres i det uendelige.
                $MenyRapport = 0 
                StatistikkMeny   #Laster inn statistikkmeny
            }

            Function StatistikkMeny {
            [INT] $AntallMenyAlternativer = 2 #Antall alternativer i undermeny
         [STRING] $sti = "Hovedmeny / Eksporter AD statistikk til rapportt /"
                   $t2 = "`t`t"     #'t2' gir to tab-mellomrom
                   $t3 = "`t`t`t"   #Gir 3 tab-mellomrom

            #Henter egenskaper og lagrer dem i variabler
            Try { #Bruker en 'Try' for å ikke vise eventuelle feilmeldinger som oppstår
                  #under kjøring av funksjoner.

                   #Deklarering av variabler nedenfor. Dette gjøres slik at det kan brukes i
                   #eksportering av informasjon til HTML-fil.
            
                #Variabler for brukerkontoer
                $AntallBrukerkontoerTotalt = (Get-ADUser -Filter *).count
                $DeaktiverteKontoer        = (Search-ADAccount -AccountDisabled -UsersOnly).count
                $UtløpteKontoer            = (Search-ADAccount -AccountExpired -UsersOnly).count
                $KontoerSomUtløper         = (Search-ADAccount -AccountExpiring -UsersOnly).count
                $Inaktivekontoer           = (Search-ADAccount -AccountInactive -UsersOnly).count
                $LåsteKontoer              = (Search-ADAccount -LockedOut -UsersOnly).count
                $UtgåttePassord            = (Search-ADAccount -PasswordExpired -UsersOnly).count
                $PassordAldriUtgår         = (Search-ADAccount -PasswordNeverExpires -UsersOnly).count

                #Variabler for maskiner
                $AntallMaskiner          = (Get-ADComputer -Filter *).count
                $DeaktiverteMaskiner     = (Get-ADComputer -Filter {enabled -eq $false}).count
                $InaktiveMaskiner        = (Search-ADAccount -AccountInactive -ComputersOnly).count
                $LåsteMaskiner           = (Search-ADAccount -LockedOut -ComputersOnly).count  

                #Variabler for grupper
                $AntallGrupper             = (Get-ADGroup -Filter *).count
                $AntallLokaleGrupper       = (Get-ADGroup -Filter {GroupScope -eq 'DomainLocal'}).count
                $AntallGlobaleGrupper      = (Get-ADGroup -Filter {GroupScope -eq 'Global'}).count
                $AntallUniversaleGrupper   = (Get-ADGroup -Filter {GroupScope -eq 'Universal'}).count
                $AntallDistributionGrupper = (Get-ADGroup -Filter {GroupCategory -eq 'Distribution'}).count
                $AntallSecurityGrupper     = (Get-ADGroup -Filter {GroupCategory -eq 'Security'}).count
            
            } Catch {}

			while ( $MenyRapport -lt 1 -or $MenyRapport -gt $AntallMenyAlternativer ) {

				Clear-Host #Fjerner tidligere output på skjermen

				Write-Host " $appNavn "              -Fore Magenta
                Write-Host "`tDu står i:" -NoNewline -Fore Cyan
                Write-Host " $sti`n"
				Write-Host "$t2`Statistikk`n"        -Fore Cyan
                
                try {
                Write-Host "`t Domene:"
                Write-Host "$t2$domene"
                Write-Host "$t2$AntallDomeneKontrollere" -NoNewline; Write-Host " domenekontrollere totalt" -Fore Cyan 

                Write-Host "`n`t Brukere:"
                Write-Host "$t2$AntallBrukerkontoerTotalt" -NoNewline; Write-Host " brukerkontoer totalt"                  -Fore Cyan 
                Write-Host "$t2$DeaktiverteKontoer"        -NoNewline; Write-Host " deaktiverte kontoer"                   -Fore Cyan 
                Write-Host "$t2$UtløpteKontoer"            -NoNewline; Write-Host " utløpte kontoer"                       -Fore Cyan 
                Write-Host "$t2$KontoerSomUtløper"         -NoNewline; Write-Host " kontoer som utløper"                   -Fore Cyan 
                Write-Host "$t2$Inaktivekontoer"           -NoNewline; Write-Host " inaktive kontoer"                      -Fore Cyan 
                Write-Host "$t2$LåsteKontoer"              -NoNewline; Write-Host " låste kontoer"                         -Fore Cyan 
                Write-Host "$t2$UtgåttePassord"            -NoNewline; Write-Host " Kontoer med utgåtte passord"           -Fore Cyan 
                Write-Host "$t2$PassordAldriUtgår"         -NoNewline; Write-Host " kontoer med passord som aldri utløper" -Fore Cyan

                Write-Host "`n`t Datamaskiner:"
                Write-Host "$t2$AntallMaskiner"          -NoNewline; Write-Host " datamaskiner totalt"                   -Fore Cyan 
                Write-Host "$t2$DeaktiverteMaskiner"     -NoNewline; Write-Host " deaktiverte maskiner"                  -Fore Cyan 
                Write-Host "$t2$InaktiveMaskiner"        -NoNewline; Write-Host " inaktive datamaskiner"                 -Fore Cyan 
                Write-Host "$t2$LåsteMaskiner"           -NoNewline; Write-Host " låste maskiner"                        -Fore Cyan 

                Write-Host "`n`t Grupper:"
                Write-Host "$t2$AntallGrupper"             -NoNewline; Write-Host " grupper totalt"       -Fore Cyan
                Write-Host "`n`t`tScope"                                                                  -Fore Cyan
                Write-Host "$t2$AntallLokaleGrupper"       -NoNewline; Write-Host " Lokale grupper"       -Fore Cyan 
                Write-Host "$t2$AntallGlobaleGrupper"      -NoNewline; Write-Host " Globale grupper"      -Fore Cyan
                Write-Host "$t2$AntallUniversaleGrupper"   -NoNewline; Write-Host " Universale grupper"   -Fore Cyan
                Write-Host "`n`t`tKategori"                                                               -Fore Cyan
                Write-Host "$t2$AntallSecurityGrupper"     -NoNewline; Write-Host " Security grupper"     -Fore Cyan
                Write-Host "$t2$AntallDistributionGrupper" -NoNewline; Write-Host " Distribution grupper" -Fore Cyan 

                Write-Host "`n`t Organizational Units:"
                Write-Host "$t2$AntallOU"                         -NoNewline; Write-Host " OrganizationalUnits totalt"                    -Fore Cyan 
                Write-Host "$t2$AntallOU_Ubeskyttet"              -NoNewline; Write-Host " OU har ikke beskyttelse mot uhelldig sletting" -Fore Cyan 
                Write-Host "$t2$($AntallOU-$AntallOU_Ubeskyttet)" -NoNewline; Write-Host " OU HAR beskyttelse"                            -Fore Cyan 

                } Catch { FeilMelding } #Viser feilmelding dersom kommandoene ikke kan kjøres suksessfullt

                Write-Host "`n$t3`1. Eksporter til HTML-fil" -Fore Cyan
                Write-Host "$t3`t Sti: "       -NoNewline -Fore Cyan; Write-Host "C:\AD-Statistikk.html"

                #Write-Host "`n$t3`2. Alternativ"             -Fore Cyan #Dersom det ønskes flere alternativer
                #Write-Host "`n$t3`3. Alternativ"             -Fore Cyan #Dersom det ønskes flere alternativer
                Write-Host "`n$t3`2. Gå tilbake"             -Fore Cyan
                
		    [int]$MenyRapport = Read-Host "`n$t3`Utfør" #Henter respons fra bruker
                if ( $MenyRapport -lt 1 -or $MenyRapport -gt $AntallMenyAlternativer ){
                    Write-Host $feilmelding -Fore Red; Sleep -Seconds $VentSekunder
		        }
            } #Slutt While

                Switch ($MenyRapport) {
                
				    1 { #Eksporter til HTML-fil
                        #Referanse: http://blogs.technet.com/b/heyscriptingguy/archive/2013/04/01/working-with-html-fragments-and-files.aspx

                        #Kilden har blitt brukt som utgangspunkt, der koden jeg har produsert har blitt endret en del.

                        #Genererer info om brukere
                        function BrukerStatistikk {
                            $Brukere = @{
                                "Antall brukere totalt" = $AntallBrukerkontoerTotalt
                                "Deaktiverte kontoer" = $DeaktiverteKontoer
                                "Utløpte kontoer" = $UtløpteKontoer
                                "Kontoer som utløper" = $KontoerSomUtløper
                                "Inaktive kontoer" = $Inaktivekontoer
                                "Låste kontoer" = $LåsteKontoer
                                "Kontoer med utgåtte passord" = $UtgåttePassord
                                "Kontoer med passord som aldri utløper" = $PassordAldriUtgår
                            }

                            $ObjektBrukere = New-Object -TypeName PSObject -Property $Brukere

                            Write-Output $ObjektBrukere
                    
                        }

                        #Genererer info om maskiner
                        function MaskinStatistikk {
                            $Datamaskiner = @{
                                "datamaskiner totalt" = $AntallBrukerkontoerTotalt
                                "Deaktiverte maskiner" = $DeaktiverteKontoer
                                "inaktive datamaskiner" = $Inaktivekontoer
                                "låste maskiner" = $LåsteKontoer
                            }

                                $ObjektDatamaskiner = New-Object -TypeName PSObject -Property $Datamaskiner
                                Write-Output $ObjektDatamaskiner
                        }

                        #Genererer info om grupper
                        function GruppeStatistikk {
                            $Grupper = @{
                                "Grupper totalt" = $AntallGrupper
                                "Antall lokale grupper" = $AntallLokaleGrupper
                                "Antall globale grupper" = $AntallGlobaleGrupper
                                "Antall universale grupper" = $AntallUniversaleGrupper
                                "Antall Security grupper"    = $AntallSecurityGrupper
                                "Antall Distribution grupper" = $AntallDistributionGrupper
                            }

                                $ObjektGrupper = New-Object -TypeName PSObject -Property $Grupper
                                Write-Output $ObjektGrupper
                        }

                        #Genererer info om OU
                        Function OUStatistikk {
                            $OrganizationalUnits = @{
                                "OUer totalt" = $AntallOU
                                "OUer uten beskyttelse" = $AntallOU_Ubeskyttet
                                "OUer MED beskyttelse" = $($AntallOU-$AntallOU_Ubeskyttet)
                            }
                                $ObjektOU = New-Object -TypeName PSObject -Property $OrganizationalUnits
                                Write-Output $ObjektOU
                        }

                        #Henter litt domeneinfo
                        Function Domene {
                            $DC = @{
                                "Domene" = $domene
                                "Antall domenekontrollere" = $AntallDomeneKontrollere
                            }
                                $ObjektDomene = New-Object -TypeName PSObject -Property $DC
                                Write-Output $ObjektDomene
                        }


                #Konverterer funksjonen til html, som en liste.
                $innhold1 = Domene | ConvertTo-Html -As LIST -Fragment -PreContent `
                            "<h2 class='overskrift'> Domene </h2>"  | Out-String

                $innhold2 = BrukerStatistikk | ConvertTo-Html -As LIST -Fragment -PreContent `
                            "<h2 class='overskrift'> Brukere </h2>"  | Out-String

                $innhold3 = MaskinStatistikk | ConvertTo-Html -As LIST -Fragment -PreContent `
                            "<h2 class='overskrift'> Maskiner </h2>" | Out-String
                
                $innhold4 = GruppeStatistikk | ConvertTo-Html -As LIST -Fragment -PreContent `
                            "<h2 class='overskrift'> Grupper </h2>"  | Out-String

                $innhold5 = OUStatistikk     | ConvertTo-Html -As LIST -Fragment -PreContent `
                            "<h2 class='overskrift'> Organizational Units </h2>" | Out-String

#HTML som formaterer presentasjonen i nettleser
$head = @’

<style>

    .overskrift {
        margin-left: 1em; #Gjør at klassen 'overskrift' flyttes 1 en til høyre
    }
body { background-color:#F0F8FF;

font-family:Times New Roman;

font-size:1em; }

    td, th {
        border:1px solid black;
        border-collapse:collapse;
    }

    th {
        color:white;
        background-color:black;
    }

    table, tr, td, th { padding: 2px; margin: 0px }

table { margin-left:3em; }

</style>

‘@

                    try { 
                        #Samler hele greia
                        ConvertTo-HTML -head $head -PostContent $innhold1,$innhold2,$innhold3,$innhold4,$innhold5 `
                        -PreContent “<h1>Active Directory statistikk for server '$Hostname'</h1>” | Out-File C:\AD-Statistikk.html

                            if ($?) {
                                Write-Host "`n`tKommandoen ble kjørt suksessfullt!" -Fore Green
                                Write-Host "`n`tRapport er lagt til i "  -NoNewline -Fore Green
                                Write-Host "'C:\AD-Statistikk.html'"
                            }
                    } Catch  { FeilMelding }

                    Prompt_Statistikk_Meny

                } #Slutt 1 - Eksporter til HTML-fil

                    2 { LastInnMeny }

                    # 3 { } #Dersom det ønskes flere alternativer
                    # 4 { } #Dersom det ønskes flere alternativer
            
                    } #Slutt switch

            } #/StatistikkMeny

                StatistikkMeny #Kaller på funksjonen

            } #Slutt menyalternativ 11 - Eksporter AD statistikk til rapport

        12 { #Menyalternativ 12 - 'Server info'

            Import-Module Storage    #Gjør at 'Get-Disk' fungerer
            Import-Module CimCmdlets #GJør at vi blandt annet kan bruke 'Get-CimInstance'

         ##########################################
         ############### FUnksjoner ###############
         ###############            ###############

            #Funksjon som henter egenskaper om prosessoren
            function HentProsessorEgenskap ($verdi) {
                #'gwmi' er alias for 'Get-WmiObject'
                gwmi win32_Processor | select -ExpandProperty $verdi
            }

            #Funksjon som henter spesifisert egenskap
            function Hent-Cim-Egenskap ($verdi) {
                #'gcim' er alias for 'Get-CimInstance'
                gcim -ClassName win32_operatingsystem | select -ExpandProperty $verdi
            }

            #Henter spesifisert egenskap
            function HentBIOSinfo ($verdi) {
                Get-WmiObject -Class win32_bios | Select -ExpandProperty $verdi
            }

            #Henter EN egenskap om maskinens minne
            function HentRAMinfo ($verdi) {
                gcim Win32_PhysicalMemory | select -ExpandProperty $verdi | Select -First 1
            }

            #Funksjon som henter temperatur
            function VisTemperatur {
            #Koden er tilpasset og endret, men er hentet fra

            #Kilde: https://social.technet.microsoft.com/Forums/systemcenter/en-US/227d6eb7-677d-4499-9ea0-d28673c36761/get-cputemp-with-powershell?forum=winserverpowershell

                $tempInfo   = @( Get-WmiObject MSAcpi_ThermalZoneTemperature -Namespace "root/wmi" -ErrorAction SilentlyContinue)
                $Temperatur = @()

                $teller = 1
                    foreach ($temp in $tempInfo) {
        
                        $TempKelvin = $temp.CurrentTemperature / 10
                        $TempCelsius = $TempKelvin - 273.15
        
                        #For å teste at fargene virker ved de ulike temperaturene kan det settes
                        #en variabel slik: $TempCelsius =  45
        
                        #Runder temperaturen opp, og viser et desimal bak komma.
                        $TempCelsius = [math]::Round($TempCelsius,1)

                        $TempFahrenheit = (9/5) * $TempCelsius + 32
                        #Runder Farenheiten opp, og viser et desimal bak komma.
                        $TempFahrenheit = [math]::Round($TempFahrenheit,1)

                        #Dersom temperaturen er under 35 grader vises temp med GRØNN farge.
                        if ($TempCelsius -eq 35 -or $TempCelsius -lt 35) {
                            Write-Host "`tTemperatur $teller er: " -NoNewline; Write-Host $TempCelsius    -NoNewline -Fore Green
                            Write-Host " °Celsius eller "          -NoNewline; Write-Host $TempFahrenheit -NoNewline -Fore Green
                            Write-Host " °Fahrenheit"
                        }

                        #Dersom temperaturen er over 35 grader men under 45 vises temp med GUL farge.
                        if ($TempCelsius -gt 35 -and $TempCelsius -lt 45) {
                            Write-Host "`tTemperatur $teller er: " -NoNewline; Write-Host $TempCelsius    -NoNewline -Fore Yellow
                            Write-Host " °Celsius eller "          -NoNewline; Write-Host $TempFahrenheit -NoNewline -Fore Yellow
                            Write-Host " °Fahrenheit"
                        }

                        #Dersom temperaturen er over 45 grader vises temp med RØD farge.
                        if ($TempCelsius -eq 45 -or $TempCelsius -gt 45) {
                            Write-Host "`tTemperatur $teller er: " -NoNewline; Write-Host $TempCelsius    -NoNewline -Fore Red
                            Write-Host " °Celsius eller "          -NoNewline; Write-Host $TempFahrenheit -NoNewline -Fore Red
                            Write-Host " °Fahrenheit"
                        }
                      $teller++ #Øker teller med en
                    }    
} #/VisTemperatur
            
            #Viser info om volum på diskene
            function VisDiskBruk {
                #Henter harddisker og sorterer dem alfabetisk etter bokstav på disk.
                $Harddisker = Get-Volume | Sort DriveLetter

                foreach ($disk in $Harddisker) {
                    #'Select' er alias for 'Select-Object'
                    $navn       = $disk | Select -ExpandProperty FileSystemLabel
                    $Bokstav    = $disk | Select -ExpandProperty DriveLetter
                    $Helse      = $disk | Select -ExpandProperty HealthStatus

                    #Utfører en 'Try' med -ErrorAction SilentlyContinue slik at det ikke kommer noe output
                    #ved feil, slik at presenteringen av andre egenskaper fremdeles blir pen.
                    Try { $FilSystem  = $disk | Select -ExpandProperty FileSystemType -ErrorAction SilentlyContinue }
                    Catch {$FilSystem = "(Greide ikke hente filsystem)"}
        
                    #Velger egenskapen 'Size'
                    $Stoerrelse = $disk | Select -ExpandProperty Size
        
                    #Regner ut i antall GigaByte
                    $Stoerrelse = $Stoerrelse / 1GB

                    #Kutter ned antall desimaler, slik at det bare blir et desimal
                    $Stoerrelse = [math]::Round($Stoerrelse,1)
        
                    $LedigPlass = $disk | Select -ExpandProperty SizeRemaining
                    #Regner ut i antall GigaByte
                    $LedigPlass = $LedigPlass / 1GB

                    #Kutter ned antall desimaler, slik at det bare blir et desimal
                    $LedigPlass = [math]::Round($LedigPlass,1)

                    #Sjekker om harddisk har bokstav, har den ikke bokstav må det gis beskjed
                        if ($Bokstav -eq $null) {
                            Write-Host "`tBokstav    : " -NoNewline -Fore Cyan
                            Write-Host "(Ingen bokstav)"            -Fore Yellow
                        } else {Write-Host "`tBokstav    : " -NoNewline -Fore Cyan; Write-Host $Bokstav}

                        if ($navn -eq "" -or $navn -eq $null) {
                            Write-Host "`tnavn       : " -NoNewline -Fore Cyan
                            Write-Host "(Tomt navn)"                -Fore Yellow
                        } else {Write-Host "`tNavn       : " -NoNewline -Fore Cyan; Write-Host $navn}

                        if ($FilSystem -eq $null) {
                            Write-Host "`tFilsystem  : " -NoNewline -Fore Cyan
                
                            Write-Host $tFilsystem              -Fore Yellow
                        } else {Write-Host "`tFilsystem  : " -NoNewline -Fore Cyan; Write-Host $FilSystem}

                        #Sjekker om helsen er 'Healthy'. Er den det får den grønn skrift, hvis ikke
                        #får den rød skriv, siden det tydeer på at noe er galt.
                        if ($Helse -eq "Healthy") {
                            Write-Host "`tHelse      : " -NoNewline -Fore Cyan; Write-Host $Helse -Fore Green
                        } else {Write-Host "`tHelse      : " -NoNewline -Fore Cyan; Write-Host $Helse -Fore Red}
                            Write-Host "`tStørrelse  : " -NoNewline -Fore Cyan; Write-Host "$Stoerrelse GB"
                            Write-Host "`tLedig plass: " -NoNewline -Fore Cyan; Write-Host "$LedigPlass GB`n"
                }#/foreach
        } #/ VisDiskBruk

            #Viser oppetiden på server
            function VisOppetid {
                $OS = Get-WmiObject Win32_OperatingSystem
                $Tid = (Get-Date) - ($OS.ConvertToDateTime($OS.lastbootuptime))

                $OppeTid = "" + $Tid.Days    + " dager, " + `
                                $Tid.Hours   + " timer, " + `
                                $Tid.Minutes + " minutter"
                return $OppeTid
            } #/VisOppetid

         ##########################################
         ###########  Slutt funksjoner ############
         ###########                   ############

            $PowerShellVersjon  = Get-PSSnapin | select -ExpandProperty PSVersion
            $manufacturer       = Get-WmiObject -Class win32_computersystem | Select -ExpandProperty Manufacturer
            $HovedKort          = Get-WmiObject Win32_BaseBoard | Select -ExpandProperty Product
            #koden til 'HovedKort' er endret litt, men er hentet fra:
            #Kilde: http://use-powershell.blogspot.no/2015/02/motherboard-model-and-manufacturer.html

            $bruker             = WhoamI #Viser hvem scriptet kjøres av

            #Kilde: https://blogs.technet.microsoft.com/heyscriptingguy/2013/03/27/powertip-get-the-last-boot-time-with-powershell/
            $LastBootTime = Get-CimInstance -ClassName win32_operatingsystem | Select -ExpandProperty LastBootUpTime 
            
            #Henter fysisk minne og måler egenskapen 'Capacity'
            $TotaltRAM = (Get-CimInstance -ClassName Win32_PhysicalMemory | Measure -Property capacity -Sum).Sum
            #Koden er endret litt, men i hovedsak hentet fra følgende adresse:
            #Kilde: http://www.tomsitpro.com/articles/powershell-calculated-properties,2-5.html

            $TotaltRAM = $TotaltRAM / 1GB #Deler på GigaByte for å få det i GB.

            [int] $teller = 0 #Det er et valg i menyen, derfor brukes det en teller.
            [int] $AntallMenyAlternativer = 1 #Antall alternativer i undermenyen
         [string] $t    = "`t"
         [string] $sti  = "Hovedmeny / Server info /"

         $RAM_Hastighet = HentRAMinfo Speed #Lagrer hastigheten som en variabel slik at jeg putte tekst bak i menyen.
         $L2Cache       = HentProsessorEgenskap L2CacheSize; $L2Cache = $L2Cache / 1KB #Deler på '1Kb' for å få det i KiloByte
         $L3Cache       = HentProsessorEgenskap L3CacheSize; $L3Cache = $L3Cache / 1KB #Deler på '1MB' for å få det i MegaByte

         #Henter klokkefrekvens og deler det på '1000 for å få det i antall GigaHertz
         $klokkeHastighet = HentProsessorEgenskap MaxClockSpeed; $klokkeHastighet = $klokkeHastighet / 1000 

			while ( $teller -lt 1 -or $teller -gt $AntallMenyAlternativer ) {
				CLS #'CLS' er alias for 'Clear-Host' og fjerner alt på skjermen slik at menyen kan vises
				Write-Host " $appNavn "                     -Fore Magenta
                Write-Host "`tDu står i:"        -NoNewline -Fore Cyan
                Write-Host " $sti`n"

                Write-Host "$t`tServer informasjon`n"        -Fore Cyan
                Write-Host "$t`PowerShell v.  : " -NoNewline -Fore Cyan; Write-Host $PowerShellVersjon
                Write-Host "$t`Server navn    : " -NoNewline -Fore Cyan; Write-Host $Hostname
                Write-Host "$t`IP adresse     : " -NoNewline -Fore Cyan; Write-Host $ip
                Write-Host "$t`Operativsystem : " -NoNewline -Fore Cyan; Write-Host $OperativSystem
                Write-Host "$t`Innlogget som  : " -NoNewline -Fore Cyan; Write-Host $bruker
                Write-Host "$t`Siste boote tid: " -NoNewline -Fore Cyan; Write-Host $LastBootTime
                Write-Host "$t`Oppetid        : " -NoNewline -Fore Cyan; VisOppetid
                Write-Host "$t`Manufacturer   : " -NoNewline -Fore Cyan; Write-Host $manufacturer
                Write-Host "$t`HovedKort      : " -NoNewline -Fore Cyan; Write-Host $HovedKort
                Write-Host "$t`Domene         : " -NoNewline -Fore Cyan; Write-Host $domene
                Write-Host ""
                Write-Host "$t`EncryptionLevel : " -NoNewline -Fore Cyan; Hent-Cim-Egenskap EncryptionLevel
                Write-Host "$t`OSArchitecture  : " -NoNewline -Fore Cyan; Hent-Cim-Egenskap OSArchitecture
                Write-Host "$t`SerialNumber    : " -NoNewline -Fore Cyan; Hent-Cim-Egenskap SerialNumber
                Write-Host "$t`SystemDrive     : " -NoNewline -Fore Cyan; Hent-Cim-Egenskap SystemDrive
                Write-Host "$t`SystemDirectory : " -NoNewline -Fore Cyan; Hent-Cim-Egenskap SystemDirectory
                Write-Host "$t`WindowsDirectory: " -NoNewline -Fore Cyan; Hent-Cim-Egenskap WindowsDirectory
                Write-Host ""
                Write-Host "$t`BIOS leverandør : " -NoNewline -Fore Cyan; HentBIOSinfo Manufacturer
                Write-Host "$t`BIOS versjon    : " -NoNewline -Fore Cyan; HentBIOSinfo SMBIOSBIOSVersion
                Write-Host "$t`Serials         : " -NoNewline -Fore Cyan; HentBIOSinfo SerialNumber
                
                #'FL' er alias for 'Format-List'
                try { Get-ADForest | FL -Property DomainNamingMaster,ForestMode,RootDomain }
                catch { 
                    Write-Host "`n$t`Active Directory skog: " -NoNewline -Fore Cyan
                    Write-Host "(fant ingen)`n" -Fore Yellow
                }
                
                VisTemperatur

                Write-Host "`n$t`tProsessor informasjon`n"      -Fore Cyan
                Write-Host "$t`Navn           : " -NoNewline -Fore Cyan; HentProsessorEgenskap Name
                Write-Host "$t`status         : " -NoNewline -Fore Cyan; HentProsessorEgenskap status
                Write-Host "$t`L2CacheSize    : " -NoNewline -Fore Cyan; Write-Host "$L2Cache KB"
                Write-Host "$t`L3CacheSize    : " -NoNewline -Fore Cyan; Write-Host "$L3Cache MB"
                Write-Host "$t`MaxClockSpeed  : " -NoNewline -Fore Cyan; Write-Host "$klokkeHastighet GHz"
                Write-Host "$t`Beskrivelse    : " -NoNewline -Fore Cyan; HentProsessorEgenskap Description
                Write-Host "$t`Antall kjerner : " -NoNewline -Fore Cyan; HentProsessorEgenskap NumberOfCores
                Write-Host "$t`Logiske kjerner: " -NoNewline -Fore Cyan; HentProsessorEgenskap NumberOfLogicalProcessors
                Write-Host "$t`Virtualisering : " -NoNewline -Fore Cyan; HentProsessorEgenskap VirtualizationFirmwareEnabled

                Write-Host "`n$t`tRandom Access Memory - RAM`n" -Fore Cyan
                Write-Host "$t`Beskrivelse  : " -NoNewline -Fore Cyan; HentRAMinfo Description 
                Write-Host "$t`Leverandør   : " -NoNewline -Fore Cyan; HentRAMinfo Manufacturer
                Write-Host "$t`DeleNR       : " -NoNewline -Fore Cyan; HentRAMinfo PartNumber 
                Write-Host "$t`Størrelse    : " -NoNewline -Fore Cyan; Write-Host "$TotaltRAM GB"
                Write-Host "$t`Hastighet    : " -NoNewline -Fore Cyan; Write-Host "$RAM_Hastighet MHz"
                Write-Host "$t`DeviceLocator: " -NoNewline -Fore Cyan; HentRAMinfo DeviceLocator 

                Write-Host "`n$t`tHarddisk informasjon`n" -Fore Cyan
                    VisDiskBruk

                #Dersom en ønsker å utvide funksjonalitet for å vise disker og egenskaper:
                #Henter disker, formaterer listen, velger egenskapene
                #Get-Disk | FL -Property BusType,HealthStatus,Model,NumberOfPartitions,Size | Format-Table

				Write-Host "`n`t`t1. Gå tilbake`n"             -Fore Cyan

		    [int]$teller = Read-Host "`t`t`tUtfør" #Henter respons fra bruker
                if ( $teller -lt 1 -or $teller -gt $AntallMenyAlternativer ){
                    Write-Host $feilmelding -Fore Red; Sleep -Seconds $VentSekunder
		        }
            } #Slutt While

            Switch ($teller) {

                1 { LastInnMeny }

                #2 { kode } Her kan det legges inn et alternativ nr 2

                #3 { kode } Her kan det legges inn et alternativ nr 3
            
            }

      } #Slutt menyalternativ 12 - Server info

        13 { #menyalternativ 13 - Logger

            function Reload_LoggMeny {
                $MenyLogger = 0 #Setter variabelen til 0 slik at ingen av casene er valgt
                VisLoggMeny     #Kaller på hele menyen
            }

            function prompt_LoggMeny { #Gir brukeren mulig til å lese output før h*n må trykke 'enter'
                Read-Host "`nTrykk 'enter' for gå tilbake" #Gir brukeren mulighet til å lese feilmelding på skjerm
                $MenyLogger = 0
                VisLoggMeny
            }

            function HentAlleLogger {
                #Henter alle logger, velger navnet 'Log' og sorterer dem alfabetisk
                #Bruker scope 'script' slik at variabelen kan aksesseres via andre funksjoner
                $script:AlleLogger = Get-EventLog -LogName * | Select -ExpandProperty Log | Sort
            }

            #Funksjon som lister ut loggene, men som samtidig teller antall oppføringer i hver logg.
            function VisTilgjengeligeLoggerMedEntries { 
                HentAlleLogger #Lagrer alle logger sortert i en variabel
                        
                [int]$teller = 1

                #For hvert objekt i variabelen, altså for hver logg
                Foreach ($loggNavn in $AlleLogger) {
                    #Teller antall oppføringer i hver logg
                    $AntallOppfoeringer = (Get-EventLog -LogName $loggNavn -ErrorAction SilentlyContinue ).Count

                    #Skriv ut nr + navn på logg. F.eks. "1. LoggNnavn"
                    Write-Host "$t4$teller. " -NoNewline -Fore Cyan
                    Write-Host $loggNavn #Skriver navnet på loggen
                    Write-Host "$t4`tAntall oppføringer " -NoNewline
                    Write-Host "$AntallOppfoeringer`n" -Fore Yellow
                    #Øker teller med +1 slik at neste loggnavn får et nummer opp, f.eks. "2. LoggNnavn"
                    $teller++
                }
            }

            function VisAlleLogger {

                HentAlleLogger #Lagrer alle loggene sortert i en variabel

                #Bruker 'script' slik at variabelen kan aksesseres i andre scope i scriptet
                [int] $script:Nummer = 1

                #Lager en liste med loggene
                Foreach ($loggNavn in $AlleLogger) {
                    
                    #Skriv ut nr + navn på logg. F.eks. "1. LoggNnavn"
                    Write-Host "$t4$script:Nummer. " -NoNewline -Fore Cyan
                    Write-Host $loggNavn
                    $script:Nummer++
                }
            }

            function VelgLogg {
                do {
                    Write-Host "`n`tHvilken logg ønsker du å bruke?" -Fore Cyan
                        
                    #Kaller på funksjon som viser tilgjengelige logger
                    VisAlleLogger 
                        
                    #Henter input fra bruker
                    #Det må brukes 'script' i variabelen slik at når funksjonen kalles i
                    #andre og dypere scope, så kan variabelen endres.

                    [int]$script:valg = Read-Host "`n`tBruk logg nr"

                    #Sjekker om input er blankt.
                        if ($script:valg -eq "" -or
                         $script:valg -eq $script:Nummer -or
                         $script:valg -gt $script:Nummer -or 
                         $script:valg -lt 1
                           ) { Write-Host "`n`tTallet du valgte er ugyldig" -Fore Red }
                    #Dersom brukeren skriver blankt, et tall som er større enn det siste tallet
                    #i loggen, et tall mindre enn 1, så gjentas funksjonen.
                } while ($script:valg -eq "" -or
                         $script:valg -eq $script:Nummer -or
                         $script:valg -gt $script:Nummer -or 
                         $script:valg -lt 1
                         ) #Utføres så lenge variabelen er tom
             }

            function VelgAntallOppfoeringer {
                do { #Funksjon som finner ut hvor mange oppføringen bruker ønsker å vise
                    Write-Host "`nHvor mange nye oppføringen ønsker du å vise?"  -Fore Cyan
                    
                    #Henter input fra bruker
                    #Det må brukes 'script' i variabelen slik at når funksjonen kalles i
                    #andre og dypere scope, så kan variabelen endres.
                    $script:antall = Read-Host "`tSkriv et tall"
                        
                        #Sjekker om input er blankt.
                        if ($script:antall -eq "") { Write-Host "`n`tSkriv inn et tall" -Fore Red }

                } while ($script:antall -eq "") #Utføres så lenge variabelen er tom
            }

        #Hovedmenyen
        function VisLoggMeny {
               
            [int] $AntallMenyAlternativer = 5 #Antall alternativer i undermenyen
         [string] $sti = "Hovedmeny / Logger /"
                   $t3 = "`t`t`t"
                   $t4 = "`t`t`t`t" #Brukes for å gi tabulator-mellomrom fra margen til venstre

			while ( $MenyLogger -lt 1 -or $MenyLogger -gt $AntallMenyAlternativer ) {
				Clear-Host  # Fjerner forrige meny på skjerm for å gjøre presenteringen penere
				
                # Presenter menyalternativene
				Write-Host " $appNavn "                                                       -Fore Magenta
                Write-Host "`tDu står i:"                                          -NoNewline -Fore Cyan
                Write-Host " $sti`n" 
				Write-Host "`t`tVelg mellom følgende administrative oppgaver`n"               -Fore Cyan
                Write-Host "$t3`Følgende logger er tilgjengelige:"                            -Fore Cyan
                
                    VisAlleLogger #Viser alle tigjengelige logger på maskinen man jobber på

                Write-Host "`n$t3`1. Vis 'X' oppføringer av de nyeste meldinger i en logg"    -Fore Cyan

                Write-Host "`n$t3`2. List ut en logg med EventID 'X'"                         -Fore Cyan
                Write-Host "$t4`Eksempel: "                                        -NoNewline -Fore Cyan
                Write-Host "407, 14, 206"

                Write-Host "`n$t3`3. List ut en logg med Entry 'X' og 'X' antall oppføringer" -Fore Cyan
                Write-Host "$t4`Entry: "                                           -NoNewline -Fore Cyan
                Write-Host "Error / Warning"

                Write-Host "`n$t3`4. List antall oppføringer på alle loggene"                 -Fore Cyan
                    
                Write-Host "`n$t3`5. Tilbake"                                                 -Fore Cyan

                [int]$MenyLogger = Read-Host "`n`t`t`tUtfør" #Henter respons fra bruker
                if ( $MenyLogger -lt 1 -or $MenyLogger -gt $AntallMenyAlternativer ){
                    Write-Host $feilmelding -Fore Red; Sleep -Seconds $VentSekunder
		        }
}

            Switch ($MenyLogger) {

				1 { # Vis 'X' av de nyeste meldinger i en logg

                    VelgAntallOppfoeringer #Hvor mange oppføringer ønsker bruker å se?
                    VelgLogg               #Hvilken logg ønsker bruker å vise?

                    try {
                        $script:Nummer = 1 #Oppretter en variabel som skal telle loggene

                        #Henter variabelen $AlleLogger fra funksjonen 'VisTilgjengeligeLogger'
                        foreach ($logg in $AlleLogger) { #For hver eneste logg  utføres følgende:

                            #Sjekker om valget er det samme som telleren
                            #Dersom den er det betyr det at det innskrevne nummeret fra brukeren
                            #matcher med loggnummeret som ble funnet.
                            if ($script:valg -eq $script:Nummer) {

                                #Viser output til bruker om hvas om skjer
                                Write-Host "`nHenter '$logg' loggen" -Fore Cyan

                                #Henter loggen og antall oppføringer spesifisert
                                #Lagrer loggen i en variabel slik at jeg kan sjekke om den er tom.
                                #Bruker '-ErrorAction SilentlyContinue' for å ikke vise feilmelding til bruker
                                $VisLogg = Get-EventLog -LogName $logg -Newest $script:antall -ErrorAction SilentlyContinue
                                    if ($VisLogg -eq $null) {Write-Host "`n`tLoggen ser ut til å være tom! ¯\_(ツ)_/¯" -Fore Yellow}
                                    else { $VisLogg }
                            }

                            #Øker telleren, slik at hvis det ikke var rett logg
                            #prøves neste nummer i loggmenyen.
                            $script:Nummer++

                        }#/ foreach
                    } Catch  { FeilMelding } #Henter feilmelding om det skjer noe

                    #Gir bruker mulighet til å trykke 'enter' for å gå tilbake til menyen
                    #slik at bruker får tid til å lese output.
                    prompt_LoggMeny

                } #Vis 'X' av de nyeste meldinger i en logg

                2 { #List ut en logg med EventID 'X'

                    do { #Ber bruker skrive inn tallet på Event ID'en
                        Write-Host "`nSkriv inn en EventID:" -Fore Cyan
                        $EventID = Read-Host "`tEventID"
                            if ($EventID -eq "") { Write-Host "`n`tSkriv inn et tall" -Fore Red}
                    } while ($EventID -eq "") #Utføres så lenge variabelen er tom
                    
                    VelgAntallOppfoeringer

                    VelgLogg

                    try {
                        $teller = 1 #Oppretter en variabel som skal telle loggene

                        #Henter variabelen $AlleLogger fra funksjonen 'VisTilgjengeligeLogger'
                        foreach ($logg in $AlleLogger) { #For hver eneste logg  utføres følgende:

                            #Sjekker om valget er det samme som telleren
                            #Dersom den er det betyr det at det innskrevne nummeret fra brukeren
                            #matcher med loggnummeret som ble funnet.
                            if ($valg -eq $teller) {

                                #Viser output til bruker om hvas om skjer
                                Write-Host "`nHenter '$logg' loggen" -Fore Cyan

                                $VisLogg = Get-EventLog -LogName $logg -Newest $antall  |
                                Where-Object {$_.EventID -eq $EventID} -ErrorAction SilentlyContinue

                                if ($VisLogg -eq $null) {Write-Host "`n`tLoggen har ingen oppføringer med EventID spesifisert! ¯\_(ツ)_/¯" -Fore Yellow}
                                    else { $VisLogg }
                            }

                            $teller++

                        }#/ foreach
                    } Catch  { FeilMelding } #Henter feilmelding om det skjer noe

                    prompt_LoggMeny 


                } #List ut en logg med EventID 'X'

                3 { #List ut en logg med Entry 'X'
                    
                    do {
                        Write-Host "`n`tHvilken entry ønsker du å bruke?" -Fore Cyan
                            Write-Host "`n`t1. " -NoNewline -Fore Cyan
                            Write-Host "Error" 
                            Write-Host "`t2. " -NoNewline -Fore Cyan
                            Write-Host "Warning" 
                        $Entry = Read-Host "`n`tSkriv et tall"
                            if ($Entry -eq ""  -or
                                $Entry -ne "1" -and
                                $Entry -ne "2"
                               ){ Write-Host "`n`tVennligst velg blandt alternativ 1 og 2." -Fore Red }

                    } while ($Entry -ne "1" -and
                             $Entry -ne "2"
                            ) #Utføres så lenge "1" eller "2" ikke er valgt
                    
                        if ($Entry -eq "1") {$Entry = "Error"}
                        else {$Entry = "Warning"}

                        VelgAntallOppfoeringer

                        VelgLogg      #Funksjon der bruker velger et tall basert på tilgjengelige logger

                        try {
                            $teller = 1 #Oppretter en variabel som skal telle loggene

                            #Henter variabelen $AlleLogger fra funksjonen 'VisTilgjengeligeLogger'
                            foreach ($logg in $AlleLogger) { #For hver eneste logg  utføres følgende:

                            #Sjekker om valget er det samme som telleren
                            #Dersom den er det betyr det at det innskrevne nummeret fra brukeren
                            #matcher med loggnummeret som ble funnet.
                            if ($valg -eq $teller) {

                                #Viser output til bruker om hvas om skjer
                                Write-Host "`nHenter '$logg' loggen" -Fore Cyan

                                #Henter loggen og antall oppføringer spesifisert
                                #Lagrer loggen i en variabel slik at jeg kan sjekke om den er tom.
                                #Bruker '-ErrorAction SilentlyContinue' for å ikke vise feilmelding til bruker
                                $VisLogg = Get-EventLog -LogName $logg -Newest $antall -EntryType $Entry -ErrorAction SilentlyContinue
                                    if ($VisLogg -eq $null) {Write-Host "`n`tLoggen ser ut til å være tom! ¯\_(ツ)_/¯" -Fore Yellow}
                                    else { $VisLogg }
                            }
                            #Øker telleren, slik at hvis det ikke var rett logg
                            #prøves neste nummer i loggmenyen.
                            $teller++

                        }#/ foreach
                    } Catch  { FeilMelding } #Henter feilmelding om det skjer noe

                    prompt_LoggMeny

                } #List ut en logg med Entry 'X'

                4 { #List antall oppføringer på alle loggene

                    Write-Host "`nVent mens antall oppføringer telles.`n" -Fore Yellow

                    #Funksjon som viser alle loggene, men som også viser
                    #antall oppføringer bak hver logg i presentasjonen.
                    VisTilgjengeligeLoggerMedEntries

                    #Bruker må trykke 'enter' for å gå tilbake til meny.
                    #Bruker får da tid til å lese output på skjermen.
                    prompt_LoggMeny 

                } #List antall oppføringer på alle loggene

                5 { LastInnMeny } #Laster inn hovedmenyen

            }#Slutt Switch

        } #/ VisLoggMeny

         VisLoggMeny #Kaller på hele funksjonen

        } #Slutt menyalternativ 13 - Logger
        
        14 { #Menyalternativ 13 - 'Om'

         [string] $sti = "Hovedmeny / Hjelp /"
                   $t2 = "`t`t"
                   $t3 = "`t`t`t"
                   $t4 = "`t`t`t`t" 
				Clear-Host
				Write-Host " $appNavn "              -Fore Magenta
                Write-Host "`tDu står i:" -NoNewline -Fore Cyan
                Write-Host " $sti`n"
				Write-Host "`t`tKort om scriptet`n" -Fore Cyan
                
                Write-Host " Dette scriptet er laget av studenten Henrik Johnsen i forbindelse med bacheloroppgave
 for vår 2017 på NTNU. Scriptet skal administrere Active Directory i den grad det lar
 seg gjøre innenfor en tidsramme på ca 500 timer +- 5%.`n
 I scriptet brukes tallene 1-9 for å navigere mellom menyene, og for å utføre funksjoner og kommanoder.
"
                Read-Host "`tTrykk 'enter' for å gå tilbake" #Henter respons fra bruker
                LastInnMeny

      } #Slutt menyalternativ 13 - Hjelp

            #Kode som skal kjøres dersom ingen av casene blir valgt. Det vil si, når tallet 15 velges.

            #Koden til CowSay er endret men i utgangspunktet hentet fra følgende link:
            #https://github.com/piuccio/cowsay

        default { 
            Write-Host "`n`t __________________ "
            Write-Host "`t<     På gjensyn   >"
            Write-Host "`t ------------------"
            Write-Host "`t        \   ^__^"
            Write-Host "`t         \  (oo)\_______"
            Write-Host "`t            (__)\       )\/\"
            Write-Host "`t                ||----w |"
            Write-Host "`t________________" -Fore Green -NoNewline
            Write-Host "||" -NoNewline
            Write-Host "_____" -Fore Green -NoNewline
            Write-Host "||" -NoNewline
            Write-Host "__`n" -Fore Green
            exit #Avslutter funksjon
        } #Kode som kjøres om ingen av casene er valgt
        
    } #Slutt Switch Hovedmeny

} #Slutt funksjon 'LastInnMeny'

    LastInnMeny #Kaller på funksjonen
