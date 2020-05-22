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

-- endregion

-- region TABLE - Tabellen erstellen

CREATE TABLE Fakultaet (
    id       INT PRIMARY KEY AUTO_INCREMENT,
    name     VARCHAR(64) NOT NULL,
    standort VARCHAR(64) NOT NULL
);

CREATE TABLE Studiengang (
    id           INT PRIMARY KEY AUTO_INCREMENT,
    name         VARCHAR(64) NOT NULL,
    fakultaet_id INT      NOT NULL,
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
    id             INT PRIMARY KEY AUTO_INCREMENT,
    name           VARCHAR(64) NOT NULL,
    dozent         VARCHAR(64)  NOT NULL,
    semester       TINYINT
);

ALTER TABLE Modul
    ADD CONSTRAINT check_Modul_semester
        CHECK (semester > 0);

CREATE TABLE Studiengang_Modul (
    studiengang_id INT NOT NULL,
    modul_id INT NOT NULL,
    PRIMARY KEY (studiengang_id, modul_id),
    FOREIGN KEY (studiengang_id)
        REFERENCES Studiengang (id),
    FOREIGN KEY (modul_id)
        REFERENCES Modul (id)
);

CREATE TABLE Student (
    id                  INT PRIMARY KEY AUTO_INCREMENT,
    name                VARCHAR(64)      NOT NULL,
    smail_adresse       VARCHAR(64)      NOT NULL,
    studiengang_id      INT           NOT NULL,
    semester            TINYINT DEFAULT 1 NOT NULL,
    -- TODO: Hash-Größe hängt von Implementierung ab.
    passwort_hash       VARCHAR(64)      NOT NULL,
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
    id      INT PRIMARY KEY AUTO_INCREMENT,
    kennung CHAR(32) NOT NULL -- UUID
);

CREATE UNIQUE INDEX index_EindeutigeKennung_kennung
    ON EindeutigeKennung(kennung);

-- Ein Eintrag zur Verifizierung des Nutzer-Accounts.
CREATE TABLE StudentVerifizierung (
    kennung_id INT PRIMARY KEY,
    student_id INT NOT NULL UNIQUE,
    FOREIGN KEY (kennung_id)
        REFERENCES EindeutigeKennung (id),
    FOREIGN KEY (student_id)
        REFERENCES Student (id)
);

-- Ein Eintrag zur Widerherstellung des Passworts eines Studenten.
CREATE TABLE StudentWiederherstellung (
    kennung_id INT PRIMARY KEY,
    student_id INT NOT NULL UNIQUE,
    FOREIGN KEY (kennung_id)
        REFERENCES EindeutigeKennung (id),
    FOREIGN KEY (student_id)
        REFERENCES Student (id)
);

CREATE TABLE Gruppe (
    id           INT PRIMARY KEY AUTO_INCREMENT,
    modul_id     INT             NOT NULL,
    ersteller_id INT             NOT NULL,
    name         VARCHAR(64)        NOT NULL,
    `limit`        TINYINT DEFAULT 8,
    oeffentlich  CHAR(1) DEFAULT '1' NOT NULL,
    betretbar    CHAR(1) DEFAULT '0' NOT NULL
        COMMENT 'Studenten können der Gruppe beitreten ohne erst vom Ersteller angenommen werden zu müssen.',
    deadline     DATE,
    -- FIXME: Ort als Geokoordinaten abspeichern.
    ort          VARCHAR(64),
    FOREIGN KEY (modul_id)
        REFERENCES Modul (id),
    FOREIGN KEY (ersteller_id)
        REFERENCES Student (id)
);

ALTER TABLE Gruppe
    ADD CONSTRAINT check_Gruppe_limit
        CHECK (`limit` > 0);

ALTER TABLE Gruppe -- TODO: Kann man das irgendwie schöner abbilden?
    ADD CONSTRAINT check_Gruppe_oeffentlich
        CHECK (oeffentlich in ('1', '0'));

ALTER TABLE Gruppe
    ADD CONSTRAINT check_Gruppe_betretbar
        CHECK (betretbar in ('1', '0'));

CREATE TABLE GruppenDienstlink (
    gruppe_id INT     NOT NULL,
    url       TEXT NOT NULL,
    FOREIGN KEY (gruppe_id)
        REFERENCES Gruppe (id)
);

CREATE TABLE GruppenBeitrag (
    id         INT PRIMARY KEY AUTO_INCREMENT,
    gruppe_id  INT        NOT NULL,
    student_id INT, -- Darf NULL sein, falls Nutzer gelöscht wurde.
    datum      DATE           NOT NULL,
    nachricht  VARCHAR(1024) NOT NULL,
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
    gruppe_id      INT NOT NULL,
    student_id     INT NOT NULL,
    beitrittsdatum DATE    NOT NULL,
    PRIMARY KEY (gruppe_id, student_id),
    FOREIGN KEY (gruppe_id)
        REFERENCES Gruppe (id),
    FOREIGN KEY (student_id)
        REFERENCES Student (id)
);

-- Anfrage eines Studenten um einer Gruppe beizutreten.
CREATE TABLE GruppenAnfrage (
    gruppe_id  INT NOT NULL,
    student_id INT NOT NULL,
    datum      DATE    NOT NULL,
    nachricht  VARCHAR(256),
    bestaetigt CHAR(1) DEFAULT '0' NOT NULL,
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
    kennung_id   INT PRIMARY KEY,
    gruppe_id    INT NOT NULL,
    ersteller_id INT, -- Darf NULL sein, falls Nutzer gelöscht wurde.
    gueltig_bis  DATE,
    FOREIGN KEY (kennung_id)
        REFERENCES EindeutigeKennung (id),
    FOREIGN KEY (gruppe_id)
        REFERENCES Gruppe (id),
    FOREIGN KEY (ersteller_id)
        REFERENCES Student (id)
);

-- region TRIGGER - Trigger erstellen

DROP TRIGGER IF EXISTS trigger_GruppeBeitreten;

DELIMITER // -- delimiter setzen
CREATE TRIGGER trigger_GruppeBeitreten
BEFORE INSERT ON Gruppe_Student
FOR EACH ROW
BEGIN
    DECLARE g_limit TINYINT;
    DECLARE g_betretbar CHAR(1);
    DECLARE g_deadline DATE;

    DECLARE anzahl_mitglieder INT;
    DECLARE anfrage_bestaetigt INT;

    SELECT `limit`, betretbar, deadline
    INTO g_limit, g_betretbar, g_deadline
    FROM Gruppe g
    WHERE g.id = NEW.gruppe_id;

    SELECT COUNT(student_id)
    INTO anzahl_mitglieder
    FROM Gruppe_Student
    WHERE gruppe_id = NEW.gruppe_id AND student_id = NEW.student_id;

    IF anzahl_mitglieder = g_limit THEN
        signal sqlstate '20001' set message_text = 'Gruppe bereits vollständig.';
    END IF;

    IF g_deadline IS NOT NULL AND g_deadline < NOW() THEN
        signal sqlstate '20002' set message_text = 'Beitritt nicht mehr möglich, Deadline überschritten.';
    END IF;

    IF g_betretbar = '0' THEN
        SELECT COUNT(*) INTO anfrage_bestaetigt
        FROM GruppenAnfrage
        WHERE
            gruppe_id = NEW.gruppe_id AND
            student_id = NEW.student_id AND
            bestaetigt = '1';

        IF anfrage_bestaetigt <> 1 THEN
            signal sqlstate '20003' set message_text = 'Beitritt nur bei bestätigter Anfrage möglich.';
        END IF;
    END IF;

    -- Ggf. Vorhandende Beitrittsanfrage löschen
    DELETE FROM GruppenAnfrage
    WHERE gruppe_id = NEW.gruppe_id AND student_id = NEW.student_id;
END //
DELIMITER ; -- delimiter resetten

-- endregion

-- region FUNCTION - Funktionen erstellen

-- endregion

-- region PROCEDURE - Prozeduren erstellen

-- endregion

-- region Notizen

-- endregion
