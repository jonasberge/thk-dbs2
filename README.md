# Lerngruppen-Tool

Projekt im Rahmen des Datenbankpraktikums im SS20.

**Team 20**

| Name                         | Matrikelnummer |
| ---------------------------- | -------------- |
| Kaan Bıçakcı                 | 11139154       |
| Cihan Cosdan (Projektleiter) | 11121481       |
| Yendoukon Nayante            | 11034938       |
| Tadeg Jonas van den Berg     | 11131788       |
| Edis Vilja                   | 11109956       |

## Einleitung

Das Studium verlangt Studenten viel Selbstorganisation ab, was für viele überfordern sein kann. Dabei können gemeinsames Lernen und ein regelmäßiger Austausch mit Kommilitonen das Studium erheblich erleichtern. Dafür eignen sich Lerngruppen besonders gut.

Solche zu bilden und erfolgreich zu gestalten ist jedoch nicht leicht. Um zumindest den Prozess der Gruppenbildung zu vereinfachen, möchten wir eine digitale Plattform erstellen, die es Studenten der TH Köln ermöglicht, online eine passende Gruppe zu finden oder eine Gruppe selbst zu erstellen.

### Ziele

1. Dazu beitragen, dass mehr Lerngruppen gebildet werden.
2. Hindernisse beseitigen, die das Bilden von Lerngruppen erschweren.
3. Lerngruppen am Wohnort findbarer machen.
4. Zeitlich ausgelasteten Studenten das Finden von Lerngruppen vereinfachen. 



## Planung und Spezifikation

In diesem Abschnitt präsentieren wir unsere geplanten Funktionalitäten, die in unserem Projekt relevanten Benutzergruppen und stellen die Modelle, die wir für unser Projekt modelliert haben vor. Darunter ein Use-Case-Diagramm und zwei Entity Relationship Modelle, ein einfaches und ein erweitertes.

### Funktionalitäten

Der folgende Abschnitt befasst sich mit den Funktionalitäten, die wir in unserem Projekt umsetzen möchten. Die Funktionalitäten werden kategorisiert aufgelistet und enthalten die für den Arbeitsablauf relevanten Daten. Da wir aus verschiedenen Gründen nicht alle Funktionalitäten umsetzen können, die wir uns gedacht haben, werden die Funktionalitäten außerdem noch mit  „geplant“,  „nice-to-have“ und  „nicht-geplant“ gekennzeichnet. Zum Ende behandeln wir noch einmal die Funktionalitäten, die mit „nice-to-have“ und  „nicht-geplant“ gekennzeichnet sind und beschreiben welchen Mehrwert sie bieten würden.

#### Benutzerkonto

| Funktionalität                     | Relevante Daten                                              | Planung       |
| ---------------------------------- | ------------------------------------------------------------ | ------------- |
| Verifizierung des Studentenstatus  | S-Mail-Adresse<br />Gewünschtes Passwort<br />Verifizierungslink<br />Fakultät und Studiengang<br />Semester<br />Modulauswahl<br />Name<br />Profilbild (optional)<br />Profilbeschreibung (optional) | nicht geplant |
| Einfaches Login                    | S-Mail-Adresse<br />Passwort                                 | geplant       |
| One-Time-Password Login            | S-Mail-Adresse                                               | nicht geplant |
| Passwort ändern                    | S-Mail-Adresse<br />Altes Passwort<br />Neues Passwort       | geplant       |
| Passwort zurücksetzen              | S-Mail-Adresse<br />Altes Passwort<br />Neues Passwort       | nicht geplant |
| Profil bearbeiten                  | Name<br />Profilbild<br />Profilbeschreibung (Bio)           | nice-to-have  |
| Studiengangsinformationen anpassen | Fakultät und Studiengang<br />Semester<br />                 | nice-to-have  |
| Account zurücksetzen               | Name<br />Profilbild<br />Profilbeschreibung (Bio)<br />Gruppenmitgliedschaften<br />Gruppenspezifische Daten<br /> | geplant       |

#### Gruppe

| Funktionalität                                               | Relevante Daten                                              | Planung      |
| ------------------------------------------------------------ | ------------------------------------------------------------ | ------------ |
| Gruppe erstellen                                             | Modul<br />Gruppenname<br />Maximale Mitgliederzahl<br />Zutrittsbeschränkung<br />Deadline (optional)<br />Sichtbarkeit der Gruppe<br />Zeit (optional)<br />Ort (optional) | geplant      |
| Suche mit Filterfunktion                                     | Modul<br />Zeit (optional)<br />Ort (optional)               | geplant      |
| Studenten zur Gruppe einladen                                | Einladungslink                                               | nice-to-have |
| Gruppe beitreten/verlassen                                   | Gruppenmitgliedschaft                                        | geplant      |
| Verwaltung von Links zu Diensten, die in der Gruppe verwendet werden | Gruppen<br />Links zu anderen Diensten                       | nice-to-have |
| Einfache Beiträge innerhalb der Gruppe                       | Ersteller<br />Zeitpunkt der Erstellung<br />Gruppe          | geplant      |
| Gruppeneinstellungen                                         | Maximale Mitgliederzahl<br />Gruppenname<br />Zutrittsbeschränkung<br />Sichtbarkeit der Gruppe<br />Zeit<br />Ort | nice-to-have |
| Gruppenmitglied aus Gruppe entfernen                         | Gruppenmitgliedschaft                                        | nice-to-have |
| Gruppe löschen                                               | Gruppe<br />Gruppenspezifische Daten                         | geplant      |

#### Termine

| Funktionalität                      | Relevante Daten     | Planung      |
| ----------------------------------- | ------------------- | ------------ |
| Termin für Gruppe erstellen         | Gruppe<br />Termin  | nice-to-have |
| Übersicht der Termine in Gruppe     | Gruppe<br />Termin  | nice-to-have |
| Übersicht der Termine aller Gruppen | Gruppen<br />Termin | nice-to-have |

#### Benachrichtigungen

| Benachrichtigung                                             | Relevante Daten              | Planung      |
| ------------------------------------------------------------ | ---------------------------- | ------------ |
| Neue Gruppe für bestimmtes Modul erstellt                    | Gruppe<br />Modul            | nice-to-have |
| Gruppe eines bestimmten Moduls nimmt neue Teilnehmer auf     | Gruppe<br />Modul            | nice-to-have |
| Beitrittsanfrage (an Gruppenersteller)                       | Gruppe<br />Beitrittsanfrage | nice-to-have |
| Lange Inaktivität mit Hinweis Gruppe zu löschen (an Gruppenersteller) | Gruppe                       | nice-to-have |
| Ereignisse innerhalb der Gruppe<br />- Neuer Beitrag<br />- Neues Mitglied<br />- Aus Gruppe entfernt<br />- Gruppe gelöscht<br />- (Neuer Termin) | Gruppe<br />Benachrichtigung | nice-to-have |
| Erinnerung bei Gruppentermin                                 | Gruppe<br />Termin           | nice-to-have |

### Funktionalitäten, die nicht als "geplant" gekennzeichnet sind

#### Benutzerfunktionalitäten

Da wir nur eine prototypische App entwickeln verzichten wir auf folgende Funktionalitäten:

- Registrierung
- OAuth2-Authentifizierung mittels Campus ID oder GMID
- One-Time-Passwort
- Passwort zurücksetzen

Wir implementieren dafür nur ein klassisches Login ohne Passwort zurücksetzen und verwenden Dummy-Daten für die verschiedenen Studenten.

Wir waren anfangs ambitionierter und hatten die Idee eine Authentifizierung mittels der OAuth2 Services der Campus IT oder des ADV-Labors umzusetzen. Vom ADV-Labor haben wir sogar eine Zustimmung dafür erhalten.

Außerdem hatten wir die Idee ein Login mittels One-Time-Passwort umzusetzen.

Wir verzichten aus dem selben Grund auf all diese Funktionalitäten und verwenden wie bereits oben gennant Dummy-Daten für die verschiedenen Nutzer und Module.

Auch wenn wir auf Passwort zurücksetzen verzichten, möchten wir eine Änderung des Passwort während einer eingeloggten Session ermöglichen.

Eine Bearbeitung des Profils und der Studiengangsinformationen möchten wir ggf. noch umsetzen.

#### Gruppenfunktionalitäten

Folgende Funktionalitäten haben wir als "nice-to-have" gekennzeichnet, da wir aus zeitlichen Gründen nicht alle davon umsetzen können:

- Gruppeneinstellungen ändern
- Gruppenmitglied aus Gruppe entfernen
- Studenten zur Gruppe einladen
- Verwaltung von Links zu Diensten, die in der Gruppe verwendet werden

Neben den grundlegenden Funktionen "Gruppeneinstellungen ändern" und "Gruppenmitglied aus Gruppe entfernen" haben wir uns zwei Funktionalitäten ausgedacht, die der Applikation zusätzlichen Mehrwert bieten.

Wir sind eher dazu gewillt die letzteren umzusetzen.

#### Termine und Benachrichtigungen

Diese beiden Gruppen von Funktionalitäten haben wir als "nice-to-have" klassifiziert. Sie würden der Applikation auch zusätzlichen Mehrwert bieten, sprengen jedoch unserer Meinung nach den Rahmen des Machbaren.

## Benutzergruppen

Die einzigen Stakeholder unseres Projekts sind **Studenten der TH Köln**.

### Geschäftsobjekte

#### Gruppe

- <u>Nutzer</u>-Rollen: *Ersteller, Teilnehmer*




- <u>Nutzer</u> (*Ersteller*) können <u>Gruppen</u> erstellen (**create**)
- Alle <u>Nutzer</u> können öffentliche <u>Gruppen</u> einsehen (**read**)
- *Ersteller* können <u>Gruppen</u> bearbeiten (**update**)
- Der *Ersteller* kann die <u>Gruppe</u> löschen (**delete**)





- *Ersteller* kann die Sichtbarkeit der <u>Gruppe</u> definieren
  - öffentliche <u>Gruppe</u> (sichtbar in der Suche)
  - private <u>Gruppe</u> (nur mit geteiltem Link aufrufbar)
- <u>Nutzer</u> (*Teilnehmer*) können <u>Gruppen</u> beitreten
- Der *Ersteller* kann *Teilnehmer* aus der <u>Gruppe</u> entfernen

#### Nutzer

- Besucher der Website können einen Nutzer-Account erstellen (create)
- Angemeldete Nutzer können das Profil eines anderen Nutzers einsehen (read)
- Angemeldete Nutzer können ihr eigenes Profil bearbeiten (update)
- Angemeldete Nutzer können ihr Profil löschen (delete)
- Nutzer kann andere Nutzer blockieren



### Modelle

#### Use-Case-Diagramm

##### Benutzerkonto

##### Gruppenfunktionalität

##### Erläuterung

#### ERM

#### EERM

### Datenbankschema

Da wir die Leserlichkeit dieses Dokuments beibehalten möchten, haber wir das DDL Script in eine separate Datei ausgelagert.

### Prozedurale Datenbankobjekte

#### Trigger

#### Prozeduren/Funktionen

#### View & INSTEAD-OF-Trigger

### Aufgabeneinteilung

#### Trigger

| Aufgabe          | Edis | Cihan | Joel | Jonas | Kaan |
| ---------------- | ---- | ----- | ---- | ----- | ---- |
| Gruppenbeitritt  |      |       |      |       |      |
| Gruppe verlassen |      |       |      |       |      |
| Gruppenbeitrag   |      |       |      |       |      |

#### Prozeduren

| Aufgabe                        | Edis | Cihan | Joel | Jonas | Kaan |
| ------------------------------ | ---- | ----- | ---- | ----- | ---- |
| Account zurücksetzen           |      |       |      |       |      |
| Gruppen eines Moduls auflisten |      |       |      |       |      |

#### Funktionen

| Aufgabe                      | Edis | Cihan | Joel | Jonas | Kaan |
| ---------------------------- | ---- | ----- | ---- | ----- | ---- |
| Letzter Beitrag einer Gruppe |      |       |      |       |      |

