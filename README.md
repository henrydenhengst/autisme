# autisme
script voor een autisme vriendelijke desktop


FreeBoot Rustig Signaal

Een rustige, consistente en prikkelarme werkomgeving voor Omarchy / Arch Linux.

Versie: 3.0
Platform: Omarchy / Arch Linux
Script: "freeboot-rustig-signaal.sh"
Licentie: nader te bepalen

---

1. Doel

FreeBoot Rustig Signaal is een configuratiescript voor een rustige en overzichtelijke Linux-werkomgeving.

Het project richt zich op:

- Minder visuele prikkels.
- Een consistente kleurweergave.
- Duidelijke functionele signalen.
- Beperking van onnodige animaties en beweging.
- Herkenbare kleuren in verschillende toepassingen.
- Behoud van bestaande gebruikersconfiguraties.
- Controleerbare wijzigingen en herstelmogelijkheden.

Het ontwerp is geïnspireerd op de behoefte aan een voorspelbare, rustige digitale werkomgeving, onder andere voor mensen met autisme en sensorische gevoeligheid.

2. Ontwerpprincipes

Kleurgebruik

Het kleurenschema gebruikt vaste functionele betekenissen.

Kleur| Hexcode| Betekenis
Achtergrond| "#24262b"| Rust
Voorgrond| "#cfd2d6"| Standaardtekst
Rood| "#e8707c"| Fout of gevaar
Oranje| "#e0a050"| Waarschuwing
Groen| "#76c9a0"| Succes
Blauw| "#7aa2d4"| Informatie
Paars| "#c9a0dc"| Aanvullende accentkleur
Grijs| "#8a909a"| Secundaire informatie

Aanvullende kleuren:

- Selectie: "#3a3f4b"
- Heldere voorgrond: "#e6e8eb"
- Donkere achtergrond: "#1e2025"
- Extra donkere achtergrond: "#1a1c20"

Gedragsprincipes

- Geen onnodig knipperen.
- Geen onnodige animaties.
- Geen transparante vensters als standaard.
- Geen overbodige visuele versiering.
- Functionele kleuren worden consequent toegepast.
- Belangrijke meldingen moeten ook tekstueel herkenbaar zijn.

3. Onderdelen

Het script configureert de volgende onderdelen:

Onderdeel| Functie
Omarchy| Centraal kleurenthema
Kitty| Rustige terminalweergave
eza| Bestands- en directorykleuren
Bash| Shellinstellingen
Zsh| Shellinstellingen
Fish| Shellinstellingen
fzf| Rustige selectieweergave

Omarchy gebruikt "colors.toml" als centrale kleurenbron voor de themageneratie.

4. Bestandsstructuur

De belangrijkste bestanden en mappen zijn:

~/.config/
├── omarchy/
│   └── themes/
│       └── freeboot-rustig-signaal/
│           └── colors.toml
│
├── eza/
│   └── theme.yml
│
├── kitty/
│   └── kitty.conf
│
└── fish/
    └── conf.d/
        └── freeboot-rustig-signaal.fish

~/.local/
├── share/
│   └── freeboot/
│       └── backups/
│
└── state/
    └── omarchy/
        └── current/

Het script maakt zelf de benodigde mappen aan.

5. Installatie

Vereisten

- Omarchy op basis van Arch Linux.
- Bash.
- Python 3.11 of hoger.
- Pacman.
- tar.
- Een normale gebruikersaccount.
- Een werkende Omarchy-themafunctie.

Voer het script niet uit als root.

Script uitvoerbaar maken

chmod +x freeboot-rustig-signaal.sh

Eerst controleren

./freeboot-rustig-signaal.sh --check

Deze controlemodus voert geen configuratiewijzigingen uit.

Installeren

./freeboot-rustig-signaal.sh

Het script vraagt vooraf toestemming voordat het wijzigingen uitvoert.

Installeren zonder bevestigingsvragen

./freeboot-rustig-signaal.sh --yes

Deze optie slaat de bevestigingsvragen over. Gebruik deze optie alleen wanneer je vooraf de werking begrijpt.

6. Commandosyntax

freeboot-rustig-signaal.sh [OPTIE]

Beschikbare opties:

Optie| Betekenis
"--check"| Alleen systeem- en configuratiecontroles uitvoeren
"--yes"| Bevestigingsvragen overslaan
"--restore"| Laatste beschikbare back-up herstellen
"--restore PAD"| Een specifieke back-up herstellen
"--help"| Gebruikssyntax en uitleg tonen

Voorbeelden:

./freeboot-rustig-signaal.sh --help

./freeboot-rustig-signaal.sh --check

./freeboot-rustig-signaal.sh

./freeboot-rustig-signaal.sh --yes

./freeboot-rustig-signaal.sh --restore

7. Back-up en herstel

Voordat configuratiebestanden worden aangepast, maakt het script een back-up.

De standaardlocatie is:

~/.local/share/freeboot/backups/

Elke back-up krijgt een eigen tijdstempel.

De back-up bevat:

- Bestaande beheerde configuratiebestanden.
- De oorspronkelijke themabestanden.
- De eerder actieve themanaam.
- Een manifest van de beheerde bestanden.

Herstellen

De laatste back-up herstellen:

./freeboot-rustig-signaal.sh --restore

Een specifieke back-up herstellen:

./freeboot-rustig-signaal.sh --restore \
  ~/.local/share/freeboot/backups/20261119-190000

Herstel vervangt de beheerde configuratiebestanden door de opgeslagen versies.

Let op: herstel is bedoeld voor de bestanden die door dit script worden beheerd. Controleer de gekozen back-up voordat je herstel uitvoert.

8. Pakketbeheer

Het script bevat een lijst met 100 gewenste pakketten voor een uitgebreide Linux-werkomgeving.

De lijst omvat onder andere:

- Shells en terminalhulpmiddelen.
- Bestandsbeheer.
- Zoek- en filterprogramma's.
- Netwerkdiagnostiek.
- Systeemmonitoring.
- Opslag- en schijfbeheer.
- Ontwikkelgereedschap.
- Beheer- en automatiseringssoftware.
- Multimedia- en archiefhulpmiddelen.

Het script controleert welke pakketten al geïnstalleerd zijn.

Het script installeert geen pakketten.

Dit is een bewuste veiligheidskeuze. Arch Linux vereist zorgvuldig pakketbeheer en ondersteunt geen willekeurige gedeeltelijke systeemupgrades.

Pakketinstallatie moet daarom afzonderlijk en bewust worden uitgevoerd.

9. Veiligheidsmaatregelen

Het script is ontworpen om onverwachte systeemwijzigingen te beperken.

Het script:

- Voert geen volledige systeemupgrade uit.
- Installeert geen pakketten.
- Verwijdert geen pakketten.
- Voert geen automatische reboot uit.
- Maakt eerst een back-up.
- Controleert bestaande configuratiepaden.
- Weigert conflicterende symlinks.
- Controleert de themamap op onverwachte bestanden.

Het script werkt uitsluitend binnen de gebruikersomgeving.

10. Controle na installatie

Na installatie:

1. Open een nieuwe terminal.
2. Controleer de terminalweergave.
3. Controleer de kleuren van eza.
4. Controleer de actieve Omarchy-themanaam.
5. Controleer of Bash, Zsh of Fish de instellingen heeft geladen.
6. Controleer of bestaande configuraties behouden zijn.

Een nieuwe sessie kan nodig zijn voordat alle wijzigingen zichtbaar zijn.

11. Bekende beperkingen

Deze versie is een configuratiebasis en is nog niet op iedere Omarchy-versie getest.

Aandachtspunten:

- De gebruikte "colors.toml"-sleutels moeten overeenkomen met het schema van de geïnstalleerde Omarchy-versie.
- De eza-themaconfiguratie moet door de geïnstalleerde eza-versie worden geaccepteerd.
- Kitty-instellingen kunnen afhankelijk zijn van de geïnstalleerde Kitty-versie.
- De pakketlijst kan verschillen per actuele Arch-repository.
- Het script configureert niet automatisch alle toepassingen die kleuren kunnen gebruiken.
- De instellingen voor Hyprland-animaties en Starship worden in deze versie niet gewijzigd.

Een succesvolle uitvoering van het script betekent niet automatisch dat iedere toepassing de gewenste kleuren heeft overgenomen.

12. Ontwikkelprincipes

Bij toekomstige uitbreidingen gelden de volgende uitgangspunten:

1. Eén centrale kleurendefinitie.
2. Geen onnodige afhankelijkheden.
3. Geen automatische systeemupgrade.
4. Geen onverwachte wijzigingen buiten de gebruikersomgeving.
5. Back-up vóór configuratiewijzigingen.
6. Herstelbaarheid van gewijzigde bestanden.
7. Afzonderlijke controle per toepassing.
8. Duidelijke foutmeldingen.
9. Gedocumenteerde commandosyntax.
10. Compatibiliteit controleren voordat nieuwe instellingen worden toegevoegd.

13. Status

Versie 3.0 — Technische ontwikkelversie

De basisstructuur, kleurdefinities, configuratieaanpak en herstelprocedure zijn uitgewerkt.

De volledige werking moet nog worden gevalideerd op een echte Omarchy-installatie.

Er wordt geen foutloze werking of volledige compatibiliteit met iedere Omarchy-versie gegarandeerd.

---

FreeBoot Rustig Signaal

Een rustige digitale omgeving. Minder prikkels, meer overzicht.