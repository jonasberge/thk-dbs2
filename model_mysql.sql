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

    -- Bei MySQL kein Mutating Table Problem bei Select
    -- Wert bleibt aber bei jeder Zeile gleich (Zustand vor dem Insert)
    -- Limit Abfrage greift nur wenn Gruppe zu Beginn schon zu viele Mitglieder hat
    -- Daher Lösung außerhalb des Triggers hierfür nötig

    IF anzahl_mitglieder + 1 > g_limit THEN
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

DROP TRIGGER IF EXISTS trigger_GruppeVerlassen;

DELIMITER // -- delimiter setzen
CREATE TRIGGER trigger_GruppeVerlassen
AFTER DELETE ON Gruppe_Student
FOR EACH ROW
this_trigger: BEGIN
    DECLARE anzahl_mitglieder INT;
    DECLARE ersteller_id INT;
    DECLARE ist_ersteller_mitglied INT;
    DECLARE neuer_besitzer_id INT;

    CALL GruppenBeitragVerfassen(concat(StudentenName(old.student_id),
        ' hat die Gruppe verlassen.'), old.gruppe_id, NULL);

    SELECT COUNT(gs.student_id) INTO anzahl_mitglieder
    FROM Gruppe_Student gs
    WHERE gs.gruppe_id = old.gruppe_id;

    IF anzahl_mitglieder = 0 THEN
        -- Es ist kein Mitglied mehr übrig, die Gruppe kann gelöscht werden.
        DELETE FROM GruppenAnfrage WHERE gruppe_id = old.gruppe_id;
        DELETE FROM GruppenEinladung WHERE gruppe_id = old.gruppe_id;
        DELETE FROM GruppenDienstlink WHERE gruppe_id = old.gruppe_id;
        DELETE FROM GruppenBeitrag WHERE gruppe_id = old.gruppe_id;
        -- Die folgende Zeile kann nicht in MySQL ausgeführt werden.
        -- Da sie in diesem Kontext auch nichts tut ist es in Ordnung sie wegzulassen.
     -- DELETE FROM Gruppe_Student WHERE gruppe_id = old.gruppe_id;
        DELETE FROM Gruppe WHERE id = old.gruppe_id;
        LEAVE this_trigger;
    END IF;

    SELECT g.ersteller_id INTO ersteller_id
    FROM Gruppe g WHERE g.id = old.gruppe_id;

    SELECT COUNT(gs.student_id) INTO ist_ersteller_mitglied
    FROM Gruppe_Student gs
    WHERE gs.gruppe_id = old.gruppe_id
        AND gs.student_id = ersteller_id;

    IF ist_ersteller_mitglied = 1 THEN
        LEAVE this_trigger;
    END IF;

    -- Der Ersteller befindet sich nicht mehr in der Gruppe.

    -- Unter den noch vorhandenen Nutzern wird derjenige zum
    -- neuen Besitzer erwählt, welcher zuerst beigetreten ist.

    SELECT gs.student_id INTO neuer_besitzer_id
    FROM Gruppe_Student gs
    WHERE gs.gruppe_id = old.gruppe_id
    ORDER BY beitrittsdatum
    LIMIT 1;

    UPDATE Gruppe g
    SET g.ersteller_id = neuer_besitzer_id
    WHERE g.id = old.gruppe_id;

    CALL GruppenBeitragVerfassen(concat(StudentenName(neuer_besitzer_id),
        ' wurde zum neuen Gruppenleiter erwählt.'), old.gruppe_id, NULL);
END //
DELIMITER ; -- delimiter resetten

-- endregion

-- region FUNCTION - Funktionen erstellen

DROP FUNCTION IF EXISTS StudentenName;

DELIMITER //
CREATE FUNCTION StudentenName
    (in_student_id INT)
RETURNS VARCHAR(64)
DETERMINISTIC
BEGIN
    DECLARE name VARCHAR(64);

    SELECT s.name INTO name
    FROM Student s
    WHERE s.id = in_student_id;

    RETURN name;
END;
//
DELIMITER ;

-- endregion

-- region PROCEDURE - Prozeduren erstellen

DROP PROCEDURE IF EXISTS GruppenBeitragVerfassen;

DELIMITER //
CREATE PROCEDURE GruppenBeitragVerfassen
    (IN in_nachricht VARCHAR(1024),
     IN in_gruppe_id INTEGER,
     IN in_student_id INTEGER)
BEGIN
    INSERT INTO GruppenBeitrag (gruppe_id, student_id, datum, nachricht)
    VALUES (in_gruppe_id, in_student_id, CURRENT_DATE, in_nachricht);
END;
//
DELIMITER ;

DROP PROCEDURE IF EXISTS GruppeLoeschen;

DELIMITER //
CREATE PROCEDURE GruppeLoeschen
    (IN in_id INTEGER)
BEGIN
    DELETE FROM GruppenAnfrage WHERE gruppe_id = in_id;
    DELETE FROM GruppenEinladung WHERE gruppe_id = in_id;
    DELETE FROM GruppenDienstlink WHERE gruppe_id = in_id;
    DELETE FROM GruppenBeitrag WHERE gruppe_id = in_id;
    DELETE FROM Gruppe_Student WHERE gruppe_id = in_id;
    DELETE FROM Gruppe WHERE id = in_id;
END;
//
DELIMITER ;

DROP PROCEDURE IF EXISTS AccountZuruecksetzen;

DELIMITER //
CREATE PROCEDURE AccountZuruecksetzen
    (IN in_student_id INTEGER)
BEGIN
    DECLARE student_existiert INTEGER;

    SELECT COUNT(1) INTO student_existiert FROM dual;

    IF student_existiert = 0 THEN
        set @message_text = concat('Student mit der ID ', in_student_id, ' existiert nicht.');
        signal sqlstate '20021' set message_text = @message_text;
    END IF;

    -- Lösche Gruppenmitgliedschaften des Nutzers.
    -- Löst den oben definierten Trigger aus.
    DELETE FROM Gruppe_Student
    WHERE student_id = in_student_id;

    -- TODO: student_id in GruppenBeitrag zu ersteller_id umbennen.
    UPDATE GruppenBeitrag gb
    SET gb.student_id = NULL
    WHERE gb.student_id = in_student_id;

    UPDATE GruppenEinladung ge
    SET ge.ersteller_id = NULL
    WHERE ge.ersteller_id = in_student_id;

    DELETE FROM GruppenAnfrage
    WHERE student_id = in_student_id;

    DELETE FROM Student
    WHERE id = in_student_id;
END;
//
DELIMITER ;

-- endregion

-- region Notizen

-- endregion
