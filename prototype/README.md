## Protoyp DBS2 SS20 - Team 20
## Getting Started

Voraussetzung ist, dass Python 3 installiert ist.

1. Virtuelle Umgebung venv erstellen

    ```
    $ cd prototype
    $ python3 -m venv .venv && source .venv/bin/activate
    ```

2. Packages aus reqirements.txt installieren

    ```
    $ pip install -r requirements.txt
    ```

3. .env Datei vorbereiten
    ```
    $ cp .env.example .env
    ```
    Ändern Sie `ORACLE_USER` und `ORACLE_PASS` zu Ihrer GMID und Passwort.
    Stellen Sie sicher, dass sie mit der VPN verbunden sind oder sich auf andere Weise im Hochschulnetz befinden.

4. Tabellen erstellen und Test-Daten einfügen
    ```
    $ flask db init
    $ flask db demo
    ```

4. Nun kann der Prototyp gestartet werden:
    ```
    flask run
    ```

5. Öffnen Sie [`http://localhost:5000`](http://localhost:5000) in Ihrem Browser.

6. Mit folgenden Benutzern können Sie sich anmelden:
    |Mail-Adresse|Passwort|
    |---|---|
    | dieter@smail.th-koeln.de | password |
    | jamie@smail.th-koeln.de | password |
    | frank@smail.th-koeln.de | password |
    | andrej@smail.th-koeln.de | password |
    | tom@smail.th-koeln.de | password |
    | nuri@smail.th-koeln.de | password |
    | vivian@smail.th-koeln.de | password |
    | hilal@smail.th-koeln.de | password |
    | tayo@smail.th-koeln.de | password |
    | yuri@smail.th-koeln.de | password |
