Hoe gebruik ik dit script?

Stap 1:

Installeer powershell 7.x

Stap 2:

Installeer binnen powershell 7.x de PNP Powershell module met het volgende commando:

Install-Module PnP.PowerShell -Scope CurrentUser

Stap 3:

open het script met powershell ISE, en werk de volgende variables bij:

1. Vul de volgende variabelen in de twee scripts (Dit is in beide scripts hetzeflde)
a.	$SiteURL1 = "" 					(SOURCE SITE)
b.	$SiteURL2 = ""					(TARGET SITE)
c.	$ListNameSource = ""				(SOURCE FOLDER)
d.	$ListNameTarget = ""				(TARGET FOLDER)
e.	$SourceExportPath = ""				(Export Paden)
f.	$TargetExportPath = "" 				(Export Paden)
g.	$ComparisonPath = “”				(Export Paden)


Stap 4:

Creer een appregistratie voor pnp Powershell (VOER DIT UIT IN POWERSHELL 7.x Window) : 

Register-PnPManagementShellAccess

Log in het scherm dat naar boven komt met de GA van de Office365 tenant in, en registreer de applicatie voor alleen de admin.

Stap 5:

Run het script in het powershell 7.x window. 

Het script vraagt tweemaal om in te loggen met de GA, eenmaal voor elke site.

De CSV export bevat alle bestanden die uniek zijn, en toont aan onder welke subfolder deze bestanden staan, en onder welke site.

Stap 6:

Zorg er voor dat na je werkzaamheden de appregistratie aangemaakt door PNPpowershell verwijderd wordt.



KNOWN ISSUES:

Het script throwt bij een aantal bestanden een cannot index into a null array error; dit is alleen op betrekking bij bestanden waar deze waardes niet gevuld zijn. Dit mag dus genegeerd worden.
