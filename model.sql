-- region DROP - Tabellen und Sequenzen löschen

DROP TABLE GruppenEinladung;
DROP TABLE GruppenAnfrage;
DROP TABLE Gruppe_Student;
DROP TABLE GruppenBeitrag;
DROP TABLE GruppenDienstlink;
DROP TABLE Gruppe;
DROP TABLE StudentWiederherstellung;
DROP TABLE StudentVerifizierung;
DROP TABLE EindeutigeKennung;
DROP TABLE Student;
DROP TABLE Studiengang_Modul;
DROP TABLE Modul;
DROP TABLE Studiengang;
DROP TABLE Fakultaet;

DROP PROCEDURE GruppenBeitragVerfassen;
DROP PROCEDURE GruppeLoeschen;
DROP PROCEDURE AccountZuruecksetzen;
DROP PROCEDURE LerngruppenAusgeben;

DROP FUNCTION StudentenName;

DROP SEQUENCE sequence_Fakultaet;
DROP SEQUENCE sequence_Studiengang;
DROP SEQUENCE sequence_Modul;
DROP SEQUENCE sequence_Student;
DROP SEQUENCE sequence_EindeutigeKennung;
DROP SEQUENCE sequence_Gruppe;
DROP SEQUENCE sequence_GruppenBeitrag;

-- endregion

-- region TABLE - Tabellen erstellen

CREATE TABLE Fakultaet (
    id       INTEGER PRIMARY KEY,
    name     VARCHAR2(64) NOT NULL,
    standort VARCHAR2(64) NOT NULL
);

CREATE TABLE Studiengang (
    id           INTEGER PRIMARY KEY,
    name         VARCHAR2(64) NOT NULL,
    fakultaet_id INTEGER      NOT NULL,
    abschluss    VARCHAR(16)  NOT NULL,
    FOREIGN KEY (fakultaet_id)
        REFERENCES Fakultaet (id)
);

ALTER TABLE Studiengang
    ADD CONSTRAINT check_Studiengang_abschluss
        CHECK (UPPER(abschluss) in (
            'BSC.INF', 'BSC.ING', 'DIPL.ING', 'DIPL.INF')
        );

CREATE TABLE Modul (
    id             INTEGER PRIMARY KEY,
    name           VARCHAR2(64) NOT NULL,
    dozent         VARCHAR(64)  NOT NULL,
    semester       INTEGER
);

ALTER TABLE Modul
    ADD CONSTRAINT check_Modul_semester
        CHECK (semester > 0);

CREATE TABLE Studiengang_Modul (
    studiengang_id INTEGER NOT NULL,
    modul_id INTEGER NOT NULL,
    PRIMARY KEY (studiengang_id, modul_id),
    FOREIGN KEY (studiengang_id)
        REFERENCES Studiengang (id),
    FOREIGN KEY (modul_id)
        REFERENCES Modul (id)
);

CREATE TABLE Student (
    id                  INTEGER PRIMARY KEY,
    name                VARCHAR2(64)      NOT NULL,
    smail_adresse       VARCHAR2(64)      NOT NULL,
    studiengang_id      INTEGER           NOT NULL,
    semester            INTEGER DEFAULT 1 NOT NULL,
    -- TODO: Hash-Größe hängt von Implementierung ab.
    passwort_hash       VARCHAR2(64)      NOT NULL,
    profil_beschreibung VARCHAR(256),
    profil_bild         BLOB,
    geburtsdatum        DATE,
    FOREIGN KEY (studiengang_id)
        REFERENCES Studiengang (id)
);

ALTER TABLE Student
    ADD CONSTRAINT check_Student_semester
        CHECK (semester > 0);

-- TODO [Scheduler] Nach Ablauf des Semesters `semester` des Studenten erhöhen.

CREATE TABLE EindeutigeKennung (
    id      INTEGER PRIMARY KEY,
    kennung CHAR(32) NOT NULL -- UUID
);

CREATE UNIQUE INDEX index_EindeutigeKennung_kennung
    ON EindeutigeKennung(kennung);

-- Ein Eintrag zur Verifizierung des Nutzer-Accounts.
CREATE TABLE StudentVerifizierung (
    kennung_id INTEGER PRIMARY KEY,
    student_id INTEGER NOT NULL UNIQUE,
    FOREIGN KEY (kennung_id)
        REFERENCES EindeutigeKennung (id),
    FOREIGN KEY (student_id)
        REFERENCES Student (id)
);

-- Ein Eintrag zur Widerherstellung des Passworts eines Studenten.
CREATE TABLE StudentWiederherstellung (
    kennung_id INTEGER PRIMARY KEY,
    student_id INTEGER NOT NULL UNIQUE,
    FOREIGN KEY (kennung_id)
        REFERENCES EindeutigeKennung (id),
    FOREIGN KEY (student_id)
        REFERENCES Student (id)
);

CREATE TABLE Gruppe (
    id           INTEGER PRIMARY KEY,
    modul_id     INTEGER             NOT NULL,
    ersteller_id INTEGER             NOT NULL,
    name         VARCHAR2(64)        NOT NULL,
    limit        INTEGER DEFAULT 8,
    oeffentlich  CHAR(1) DEFAULT '1' NOT NULL,
    betretbar    CHAR(1) DEFAULT '0' NOT NULL,
    deadline     DATE,
    -- FIXME: Ort als Geokoordinaten abspeichern.
    ort          VARCHAR2(64),
    FOREIGN KEY (modul_id)
        REFERENCES Modul (id),
    FOREIGN KEY (ersteller_id)
        REFERENCES Student (id)
);

COMMENT ON COLUMN Gruppe.betretbar
    IS 'Studenten können der Gruppe beitreten ohne erst vom Ersteller angenommen werden zu müssen.';

ALTER TABLE Gruppe
    ADD CONSTRAINT check_Gruppe_limit
        CHECK (limit > 0);

ALTER TABLE Gruppe -- TODO: Kann man das irgendwie schöner abbilden?
    ADD CONSTRAINT check_Gruppe_oeffentlich
        CHECK (oeffentlich in ('1', '0'));

ALTER TABLE Gruppe
    ADD CONSTRAINT check_Gruppe_betretbar
        CHECK (betretbar in ('1', '0'));

CREATE TABLE GruppenDienstlink (
    gruppe_id INTEGER     NOT NULL,
    url       HTTPURITYPE NOT NULL,
    FOREIGN KEY (gruppe_id)
        REFERENCES Gruppe (id)
);

CREATE TABLE GruppenBeitrag (
    id         INTEGER PRIMARY KEY,
    gruppe_id  INTEGER        NOT NULL,
    student_id INTEGER, -- Darf NULL sein, falls Nutzer gelöscht wurde.
    datum      DATE           NOT NULL,
    nachricht  VARCHAR2(1024) NOT NULL,
    FOREIGN KEY (gruppe_id)
        REFERENCES Gruppe (id),
    FOREIGN KEY (student_id)
        REFERENCES Student (id)
);

CREATE INDEX index_GruppenBeitrag_gruppe_datum
    ON GruppenBeitrag (gruppe_id, datum);

ALTER TABLE GruppenBeitrag
    ADD CONSTRAINT check_GruppenBeitrag_nachricht
        CHECK (LENGTH(nachricht) > 0);

-- Studenten die in einer Gruppe sind.
CREATE TABLE Gruppe_Student (
    gruppe_id      INTEGER NOT NULL,
    student_id     INTEGER NOT NULL,
    beitrittsdatum DATE    NOT NULL,
    PRIMARY KEY (gruppe_id, student_id),
    FOREIGN KEY (gruppe_id)
        REFERENCES Gruppe (id),
    FOREIGN KEY (student_id)
        REFERENCES Student (id)
);

-- Anfrage eines Studenten um einer Gruppe beizutreten.
CREATE TABLE GruppenAnfrage (
    gruppe_id  INTEGER                 NOT NULL,
    student_id INTEGER                 NOT NULL,
    datum      DATE    DEFAULT SYSDATE NOT NULL,
    nachricht  VARCHAR2(256) DEFAULT NULL,
    bestaetigt CHAR(1) DEFAULT '0'     NOT NULL,
    PRIMARY KEY (gruppe_id, student_id),
    FOREIGN KEY (gruppe_id)
        REFERENCES Gruppe (id),
    FOREIGN KEY (student_id)
        REFERENCES Student (id)
);

ALTER TABLE GruppenAnfrage
    ADD CONSTRAINT check_GruppenAnfrage_betretbar
        CHECK (bestaetigt in ('1', '0'));

-- Eine Einladung zu einer Gruppe. Wird für Einladungslinks verwendet.
CREATE TABLE GruppenEinladung (
    kennung_id   INTEGER PRIMARY KEY,
    gruppe_id    INTEGER NOT NULL,
    ersteller_id INTEGER, -- Darf NULL sein, falls Nutzer gelöscht wurde.
    gueltig_bis  DATE,
    FOREIGN KEY (kennung_id)
        REFERENCES EindeutigeKennung (id),
    FOREIGN KEY (gruppe_id)
        REFERENCES Gruppe (id),
    FOREIGN KEY (ersteller_id)
        REFERENCES Student (id)
);

-- TODO [Tabelle] Treffzeiten nach Wochentag.

-- endregion

-- region SEQUENCE - Sequenzen erstellen

CREATE SEQUENCE sequence_Fakultaet;
CREATE SEQUENCE sequence_Studiengang;
CREATE SEQUENCE sequence_Modul;
CREATE SEQUENCE sequence_Student;
CREATE SEQUENCE sequence_EindeutigeKennung;
CREATE SEQUENCE sequence_Gruppe;
CREATE SEQUENCE sequence_GruppenBeitrag;

-- endregion

-- region APPLICATION_ERROR - Eigene Fehlermeldungen

/*
    Gruppenbeitritts-Trigger
    -20001, Gruppe bereits vollständig
    -20002, Beitritt nicht mehr möglich, Deadline überschritten.
    -20003, Beitritt nur bei bestätigter Anfrage möglich.
    -20004, Mit Insert Limit and Gruppenmitgliedern überschritten
    -20009, Gruppendaten konnten nicht abgerufen werden.


    Gruppendienstlink-Trigger
    -20011, Überschreitung der maximalen Anzahl an Dienstlinks.

    AccountZuruecksetzen-Funktion
    -20021, Student mit der ID ? existiert nicht.
*/

-- endregion

-- region FUNCTION - Funktionen erstellen

CREATE OR REPLACE FUNCTION StudentenName
    (student_id INTEGER)
RETURN Student.name % TYPE
IS
    name Student.name % TYPE;
BEGIN
    SELECT s.name INTO name
    FROM Student s
    WHERE s.id = student_id;

    RETURN name;
END;
/

-- endregion

-- region PROCEDURE - Prozeduren erstellen

CREATE OR REPLACE PROCEDURE GruppenBeitragVerfassen
    (nachricht IN GruppenBeitrag.nachricht % TYPE,
     gruppe_id IN INTEGER, student_id IN INTEGER DEFAULT NULL)
IS
BEGIN
    INSERT INTO GruppenBeitrag gb (id, gb.gruppe_id, gb.student_id, datum, gb.nachricht)
    VALUES (sequence_GruppenBeitrag.nextval,
            GruppenBeitragVerfassen.gruppe_id,
            GruppenBeitragVerfassen.student_id, SYSDATE,
            GruppenBeitragVerfassen.nachricht);
END;

CREATE OR REPLACE PROCEDURE GruppeLoeschen
    (id IN INTEGER)
IS
BEGIN
    DELETE FROM GruppenAnfrage ga WHERE ga.gruppe_id = id;
    DELETE FROM GruppenEinladung ge WHERE ge.gruppe_id = id;
    DELETE FROM GruppenDienstlink gdl WHERE gdl.gruppe_id = id;
    DELETE FROM GruppenBeitrag gb WHERE gb.gruppe_id = GruppeLoeschen.id;
    DELETE FROM Gruppe_Student gs WHERE gs.gruppe_id = id;
    DELETE FROM Gruppe g WHERE g.id = GruppeLoeschen.id;
END;

CREATE OR REPLACE PROCEDURE AccountZuruecksetzen
    (student_id IN INTEGER)
IS
    student_existiert INTEGER;
BEGIN
    SELECT COUNT(1) INTO student_existiert FROM dual;

    IF student_existiert = 0 THEN
        RAISE_APPLICATION_ERROR(
            -20021,
            'Student mit der ID ' || student_id || ' existiert nicht.'
        );
    END IF;

    -- Lösche Gruppenmitgliedschaften des Nutzers.
    -- Löst den unten definierten Trigger aus.
    DELETE FROM Gruppe_Student gs
    WHERE gs.student_id = AccountZuruecksetzen.student_id;

    -- TODO: student_id in GruppenBeitrag zu ersteller_id umbennen.
    UPDATE GruppenBeitrag gb
    SET gb.student_id = NULL
    WHERE gb.student_id = AccountZuruecksetzen.student_id;

    UPDATE GruppenEinladung ge
    SET ge.ersteller_id = NULL
    WHERE ge.ersteller_id = AccountZuruecksetzen.student_id;

    DELETE FROM GruppenAnfrage ga
    WHERE ga.student_id = AccountZuruecksetzen.student_id;

    DELETE FROM Student s
    WHERE s.id = student_id;
END;

-- TODO [Prozedur] Prüfen ob ein Student/Nutzer verifiziert ist.
-- Überprüft ob in der Tabelle `StudentVerifizierung` ein Eintrag vorhanden ist.
-- Nützlich für Client-seitiges welches nur für verifizierte Nutzer möglich ist.

-- TODO [Prozedur] Studenten/Nutzer verifizieren.
-- Nimmt Parameter `student_id` und `kennung` (UUID) und überprüft
-- ob damit ein der gegebene Student verifiziert werden kann.
-- 1) Eintrag in `StudentVerifizierung` nicht vorhanden -> ERROR
-- 1) Ansonsten -> Eintrag entfernen + SUCCESS

-- TODO [Prozedur] Einer Gruppe beitreten.
-- Versucht einer Gruppe einen Studenten hinzuzufügen.
-- Die folgenden 3 Fälle müssen abgedeckt werden:
-- 1) Die Gruppe ist bereits vollständig belegt -> ERROR
-- 2) Die Gruppe ist direkt betretbar
--      -> Student hinzufügen + Anfrage löschen, falls vorhanden
-- 3) Sonst -> Beitrittsanfrage erstellen (Prozedur aufrufen)
--      + entsprechenden Wert zurückgeben

-- TODO [Prozedur] Eine Gruppe verlassen.

-- TODO [Prozedur] Eine Beitrittsanfrage erstellen.
-- Erstellt für einen Studenten eine Beitrittsanfrage zu einer Gruppe.
-- 1) Der Student ist bereits in der Gruppe -> ERROR
-- 2) Sonst -> Beitrittsanfrage erstellen

-- TODO [Prozedur] Eine Beitrittsanfrage annehmen.
-- Nimmt eine Beitrittsanfrage eines Studenten an.
-- 1) Die Gruppe ist vollständig belegt -> ERROR
-- 2) Sonst -> Student hinzufügen und alle anderen
--      Anfragen des Studenten welche zum selben Modul gehören löschen.
--      Man möchte wahrscheinlich nicht mehrere Gruppen für ein Modul belegen.
--      Oder doch?

-- TODO [Prozedur] Eine Beitrittsanfrage ablehnen.

-- endregion

-- region TRIGGER - Trigger erstellen

CREATE OR REPLACE TRIGGER trigger_GruppenAnfrage
BEFORE INSERT OR UPDATE ON GruppenAnfrage
FOR EACH ROW
DECLARE
    gruppe_betretbar INTEGER;
    bereits_in_gruppe INTEGER;
    anfrage_existiert INTEGER;
BEGIN
    IF UPDATING THEN
        IF NOT UPDATING('nachricht') THEN
            RAISE_APPLICATION_ERROR(-20031, 'Nur die Nachricht einer Anfrage kann bearbeitet werden.');
        END IF;
        RETURN;
    END IF;

    SELECT g.betretbar INTO gruppe_betretbar
    FROM Gruppe g
    WHERE g.id = :new.gruppe_id;

    IF gruppe_betretbar = '1' THEN
        RAISE_APPLICATION_ERROR(-20032, 'Diese Gruppe erfordert keine Anfrage.');
    END IF;

    SELECT COUNT(1) INTO bereits_in_gruppe
    FROM Gruppe_Student gs
    WHERE gs.gruppe_id = :new.gruppe_id AND gs.student_id = :new.student_id;

    IF bereits_in_gruppe = 1 THEN
        RAISE_APPLICATION_ERROR(-20033, 'Der anfragende Nutzer ist bereits in dieser Gruppe.');
    END IF;

    SELECT COUNT(1) INTO anfrage_existiert
    FROM GruppenAnfrage ga
    WHERE ga.gruppe_id = :new.gruppe_id AND ga.student_id = :new.student_id;

    IF anfrage_existiert = 1 THEN
        RAISE_APPLICATION_ERROR(-20034, 'Es existiert bereits eine Anfrage für diesen Nutzer.');
    END IF;

    IF :new.bestaetigt = '1' THEN
        RAISE_APPLICATION_ERROR(-20035, 'Eine neue Gruppenanfrage muss unbestätigt sein.');
    END IF;

    :new.datum := SYSDATE; -- Stelle sicher dass das Datum aktuell ist.
END;

CREATE OR REPLACE TRIGGER trigger_GruppeBeitreten
FOR INSERT ON Gruppe_Student
COMPOUND TRIGGER
    TYPE gruppe_t IS TABLE OF Gruppe_Student.gruppe_id % TYPE
    INDEX BY PLS_INTEGER;

    g_gruppen gruppe_t := gruppe_t();

    BEFORE EACH ROW IS
        g_limit            Gruppe.limit % TYPE;
        g_betretbar        Gruppe.betretbar % TYPE;
        g_deadline         Gruppe.deadline % TYPE;
        anfrage_bestaetigt INTEGER DEFAULT 0;

        CURSOR cursor_Gruppe_Attribute IS
            SELECT limit, betretbar, deadline
            FROM Gruppe g
            WHERE g.id = :new.gruppe_id;
    BEGIN
        g_gruppen(g_gruppen.COUNT + 1) := :new.gruppe_id;

        OPEN cursor_Gruppe_Attribute;
        FETCH cursor_Gruppe_Attribute INTO g_limit, g_betretbar, g_deadline;
        IF cursor_Gruppe_Attribute % NOTFOUND THEN
            RAISE_APPLICATION_ERROR(-20009, 'Gruppendaten von Gruppe ' || :new.gruppe_id
                                         || ' konnten nicht abgerufen werden.');
        END IF;
        CLOSE cursor_Gruppe_Attribute;

        IF g_deadline IS NOT NULL AND g_deadline < SYSDATE THEN
            RAISE_APPLICATION_ERROR(-20002, 'Beitritt in Gruppe ' || :new.gruppe_id
                                         || ' nicht mehr möglich, Deadline überschritten.');
        END IF;

        IF g_betretbar = '0' THEN
            SELECT COUNT(1) INTO anfrage_bestaetigt
            FROM GruppenAnfrage
            WHERE gruppe_id = :new.gruppe_id AND student_id = :new.student_id AND bestaetigt = '1';

            IF anfrage_bestaetigt <> 1 THEN
                RAISE_APPLICATION_ERROR(-20003, 'Beitritt nur bei bestätigter Anfrage möglich.');
            END IF;
        END IF;

        -- Ggf. Vorhandende Beitrittsanfrage löschen
        DELETE FROM GruppenAnfrage
        WHERE gruppe_id = :new.gruppe_id AND student_id = :new.student_id;

        IF SQL%ROWCOUNT > 0 THEN
            DBMS_OUTPUT.PUT_LINE('Vorhandende Beitrittsanfrage gelöscht');
        END IF;

        GruppenBeitragVerfassen(StudentenName(:new.student_id)
            || ' ist der Gruppe beigetreten.', :new.gruppe_id);
    END BEFORE EACH ROW;

    AFTER STATEMENT IS
        g_limit           Gruppe.limit % TYPE;
        anzahl_mitglieder INTEGER DEFAULT 0;
    BEGIN
        FOR i IN g_gruppen.FIRST .. g_gruppen.LAST
        LOOP
            SELECT COUNT(gs.student_id) INTO anzahl_mitglieder
            FROM Gruppe_Student gs
            WHERE gs.gruppe_id = g_gruppen(i);

            SELECT limit INTO g_limit
            FROM Gruppe g
            WHERE g.id = g_gruppen(i);

            IF anzahl_mitglieder > g_limit THEN
                RAISE_APPLICATION_ERROR(-20004, 'Insert in Gruppe ' || g_gruppen(i)
                                             || ' überschreitet mit ' || anzahl_mitglieder
                                             || ' Mitgliedern das Limit von ' || g_limit);
            END IF;
        END LOOP;
    END AFTER STATEMENT;
END;
/

-- TODO [Trigger] Einfügen überlappender Treffzeiten zusammenführen.
-- Falls ein einzufügender Zeitintervall mit einem anderen überlappt
-- sollte der existierende geupdated werden anstatt einen Fehler zu werden.
-- -> { von: MIN(:old.von, :new.von), bis: MAX(:old.bis, :new.bis) }

CREATE OR REPLACE TRIGGER trigger_GruppeVerlassen
FOR DELETE ON Gruppe_Student
COMPOUND TRIGGER
    TYPE gruppe_t IS TABLE OF Gruppe_Student.gruppe_id % TYPE;

    g_gruppen gruppe_t := gruppe_t();

    AFTER EACH ROW IS
    BEGIN
        g_gruppen.EXTEND;
        g_gruppen(g_gruppen.LAST) := :old.gruppe_id;

        GruppenBeitragVerfassen(StudentenName(:old.student_id)
            || ' hat die Gruppe verlassen.', :old.gruppe_id);
    END AFTER EACH ROW;

    AFTER STATEMENT IS
        modifizierte_gruppe_id Gruppe_Student.gruppe_id % TYPE;
        ersteller_id           Gruppe_Student.student_id % TYPE; -- TODO: ersteller_id
        neuer_besitzer_id      Gruppe.ersteller_id % TYPE;
        anzahl_mitglieder      INTEGER;
        ist_ersteller_mitglied INTEGER;
    BEGIN
        IF g_gruppen IS NOT EMPTY THEN
            -- Jede involvierte Gruppe muss nur einmal überprüft werden.
            g_gruppen := SET(g_gruppen);

            FOR i IN g_gruppen.FIRST .. g_gruppen.LAST
            LOOP
                SELECT g_gruppen(i) INTO modifizierte_gruppe_id FROM dual;

                SELECT COUNT(gs.student_id) INTO anzahl_mitglieder
                FROM Gruppe_Student gs
                WHERE gs.gruppe_id = modifizierte_gruppe_id;

                IF anzahl_mitglieder = 0 THEN
                    -- Es ist kein Mitglied mehr übrig, die Gruppe kann gelöscht werden.
                    GruppeLoeschen(modifizierte_gruppe_id);
                    CONTINUE;
                END IF;

                SELECT g.ersteller_id INTO ersteller_id
                FROM Gruppe g WHERE g.id = modifizierte_gruppe_id;

                SELECT COUNT(gs.student_id) INTO ist_ersteller_mitglied
                FROM Gruppe_Student gs
                WHERE gs.gruppe_id = modifizierte_gruppe_id
                    AND gs.student_id = ersteller_id;

                IF ist_ersteller_mitglied = 1 THEN
                    CONTINUE;
                END IF;

                -- Der Ersteller befindet sich nicht mehr in der Gruppe.

                -- Unter den noch vorhandenen Nutzern wird derjenige zum
                -- neuen Besitzer erwählt, welcher zuerst beigetreten ist.

                SELECT gs.student_id INTO neuer_besitzer_id
                FROM Gruppe_Student gs
                WHERE gs.gruppe_id = modifizierte_gruppe_id
                ORDER BY beitrittsdatum
                FETCH FIRST ROW ONLY;

                UPDATE Gruppe g
                SET g.ersteller_id = neuer_besitzer_id
                WHERE g.id = modifizierte_gruppe_id;

                GruppenBeitragVerfassen(StudentenName(neuer_besitzer_id)
                    || ' wurde zum neuen Gruppenleiter erwählt.', modifizierte_gruppe_id);
            END LOOP;
        END IF;
    END AFTER STATEMENT;
END;

-- endregion



-- region Notizen
/*

CREATE OR REPLACE TYPE DienstLink_t AS OBJECT (
    url HTTPURITYPE
)
FINAL;

DROP TABLE DienstLink;

CREATE TABLE DienstLink
OF DienstLink_t
OBJECT IDENTIFIER IS PRIMARY KEY;

INSERT INTO DienstLink
VALUES (HTTPURITYPE('https://web.whatsapp.com/invite?id=123'));

SELECT LOWER(SYS_GUID()) FROM dual; -- , * FROM DienstLink;

*/
-- endregion
