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

DROP PROCEDURE IF EXISTS AccountZuruecksetzen;
DROP PROCEDURE IF EXISTS GruppeLoeschen;
DROP PROCEDURE IF EXISTS GruppenBeitragVerfassen;

DROP FUNCTION IF EXISTS StudentenName;

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

-- endregion

-- region VIEW - Ansichten erstellen

/* INSTEAD OF VIEW TRigger VIEW */
CREATE or replace VIEW studentNachricht AS
SELECT gb.id, gb.nachricht, gb.gruppe_id,gb.student_id, s.name, st.abschluss
from GruppenBeitrag gb , Student s,  Studiengang st
where gb.student_id = s.id
AND UPPER(st.name) LIKE '%INF%';

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

DROP FUNCTION IF EXISTS GruppenAuflistenNachModul;

DELIMITER //
CREATE FUNCTION GruppenAuflistenNachModul
    (in_modul_id INT)
RETURNS JSON
BEGIN
    DECLARE modul_existiert     INT;

    DECLARE gruppe_id           INT;
    DECLARE gruppe_name         VARCHAR(64);

    DECLARE deadline            DATETIME;
    DECLARE gruppe_limit        INT;
    DECLARE mitglieder          INT;

    DECLARE betretbar           CHAR(1);
    DECLARE betretbar_bool      BOOLEAN;

    DECLARE oeffentlich         CHAR(1);
    DECLARE oeffentlich_bool    BOOLEAN;

    DECLARE ersteller_id        INT;
    DECLARE ersteller_name      VARCHAR(64);

    DECLARE ergebnis            JSON;

    DECLARE finished            INT DEFAULT 0;
    DECLARE gruppenCursor       CURSOR
    FOR
        SELECT  id,
                name,
                oeffentlich,
                betretbar,
                g.deadline,
                g.ersteller_id,
                (SELECT name FROM Student s WHERE s.id = g.ersteller_id),
                `limit`,
                (SELECT COUNT(*) FROM Gruppe_Student gs WHERE gs.gruppe_id = g.id)
        FROM Gruppe g
        WHERE g.modul_id = in_modul_id;

    DECLARE                     CONTINUE HANDLER
    FOR SQLSTATE '02000' SET finished = 1;

    SELECT COUNT(*)
    INTO modul_existiert
    FROM Modul
    WHERE id = in_modul_id;

    IF modul_existiert <> 1 THEN
        set @message_text = concat('Modul mit der ID ', in_modul_id, ' existiert nicht.');
        signal sqlstate '20041' set message_text = @message_text;
    END IF;

    SET ergebnis = JSON_ARRAY();

    OPEN gruppenCursor;
        REPEAT
            FETCH gruppenCursor INTO
                gruppe_id,
                gruppe_name,
                oeffentlich,
                betretbar,
                deadline,
                ersteller_id,
                ersteller_name,
                gruppe_limit,
                mitglieder;

            IF NOT finished THEN

                IF betretbar = '0' THEN
                    SET betretbar_bool = 0;
                ELSE
                    SET betretbar_bool = 1;
                END IF;

                IF oeffentlich = '0' THEN
                    SET oeffentlich_bool = 0;
                ELSE
                    SET oeffentlich_bool = 1;
                END IF;

                SELECT
                    JSON_ARRAY_APPEND (
                        ergebnis, -- json_doc
                        '$', -- path
                        JSON_OBJECT ( -- value
                            'id', gruppe_id,
                            'name', gruppe_name,
                            'oeffentlich', oeffentlich_bool,
                            'betretbar', betretbar_bool,
                            'deadline', deadline,
                            'ersteller', JSON_OBJECT (
                                'id', ersteller_id,
                                'name', ersteller_name
                            ),
                            'limit', gruppe_limit,
                            'mitgliederzahl', mitglieder
                        )
                    )
                INTO ergebnis
                FROM DUAL;
            END IF;
        UNTIL finished END REPEAT;
    CLOSE gruppenCursor;

    RETURN ergebnis;
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

DROP  PROCEDURE IF EXISTS LetzterBeitragVonGruppe;

/* PROCEDURE FÜR LETZER BEITRAG EINER GRUPPE */
delimiter //
CREATE PROCEDURE LetzterBeitragVonGruppe(v_gruppe_id INT )
BEGIN
    DECLARE r_comment VARCHAR(250);
    DECLARE v_name VARCHAR(250);
    DECLARE v_start date;
    DECLARE v_date date;
    DECLARE nr INT;
    DECLARE finished INT DEFAULT 0;

    DECLARE kundenCursor CURSOR FOR  SELECT  (b.datum ),e.name, b.Nachricht
    FROM  GruppenBeitrag b INNER JOIN Gruppe e  ON  b.gruppe_id = e.id
    where b.gruppe_id = v_gruppe_id ORDER BY b.datum DESC LIMIT 1;

    DECLARE CONTINUE HANDLER FOR SQLSTATE '02000' SET finished=1;

    /*Eine temporaere Table erzeugen um die Werten abzuspeichern */
    DROP TEMPORARY TABLE IF EXISTS TempTable;
	CREATE TEMPORARY TABLE TempTable( v_date DATE,v_name VARCHAR(250),r_comment VARCHAR(250));

    /*--Die Anzahl von den Beiteagen zu einer gegebenen
    --Gruppe in der Variable nr speicher*/
    SELECT COUNT(gruppe_id) into nr
	FROM GruppenBeitrag where gruppe_id = v_gruppe_id;

    /*---Wenn die anzahl der Beitraegen großer null ist, dann der Cursor öffnen*/
    IF (nr> 0) THEN

    OPEN kundenCursor;
  	forloop:LOOP
		FETCH kundenCursor INTO v_date,v_name ,r_comment ;
			IF finished THEN
				LEAVE forLoop;
			END IF;
        INSERT INTO TempTable (v_date,v_name ,r_comment)
		VALUES ( v_date,v_name ,r_comment);
	END LOOP forLoop;
	SELECT * from TempTable; /*---Ergebnis aus der Tabelle ausgeben*/
    CLOSE kundenCursor;

/*---Eine Fehlermeldung ausgeben, wenn keine Beitrege der Gruppe vorhanden ist.*/
    ELSE
	    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Es liegen keine Beitraegen von deiner Gruppe vor' ;
    END IF;

END //
DELIMITER ;

-- endregion

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

/* ein trigger für deadline um eine Gruppe beizutreten   */
DROP TRIGGER IF EXISTS trigger_Gruppe_deadline;
 DELIMITER //
CREATE TRIGGER trigger_Gruppe_deadline
BEFORE INSERT ON Gruppe
FOR EACH ROW
BEGIN
    IF (NEW.deadline < SYSDATE()) THEN
     SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Deadline darf nicht in der Vergangenheit liegen.';
     END IF;
END//

DELIMITER ;

/* ein trigger, der Gruppendienslink limitiert   */
DROP TRIGGER IF EXISTS trigger_GruppenDienstLink_limitiert ;

DELIMITER //
CREATE TRIGGER trigger_GruppenDienstLink_limitiert
BEFORE INSERT ON GruppenDienstlink
FOR EACH ROW
BEGIN
DECLARE v_limit INTEGER;
DECLARE v_anzahl INTEGER;
SELECT 8 INTO v_limit FROM dual;
SELECT COUNT(gruppe_id) INTO v_anzahl FROM GruppenDienstlink GROUP BY gruppe_id;
IF (v_anzahl > v_limit) THEN
SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Eine Gruppe kann nicht mehr als 5 Dienstlinks haben.';
 END IF;
 END //
DELIMITER ;

-- endregion

-- region Tabellen für Testzwecke mit Daten befüllen
-- ------------------Erstellung Fakultaet-----------------------------
INSERT INTO Fakultaet (name, standort) values('Fakultaet InfoING', 'Gummersbach');
INSERT INTO Fakultaet(name, standort) values('Fakultaet fuer Fahrzeugsysteme und Produktion', 'Koeln');
INSERT INTO Fakultaet (name, standort) values(' Fakultaet fuer Architektur', 'Koeln');
/*Erstellung Studiangang */

INSERT INTO Studiengang values(1,'MASCHINENBAU',1, 'BSC.INF');
INSERT INTO Studiengang values(2,'INFORMATIK', 2, 'BSC.ING');
INSERT INTO Studiengang values(3,'ELEKTROTECHNIK', 3, 'BSC.ING');

/*Erstellung Modulen */
INSERT INTO Modul values(1,  'INFORMATIK','Koenen', 1);
INSERT INTO Modul values(2, 'INFORMATIK','EISENMANN',  2);
INSERT INTO Modul values(3, 'Werkstoffe','Mustermann',  3);

/* Erstellung Student */

INSERT INTO Student values(1,'Tobias','help@smail.th-koeln.de',1,2,'xxxa','Lernstube',NULL,SYSDATE());
INSERT INTO Student values(2,'Hermann','test@smail.th-koeln.de',2,4,'ppp','study',NULL,DATE_FORMAT('17/12/2008', 'DD/MM/YYYY'));
INSERT INTO Student values(3,'Luc','luc@smail.th-koeln.de',3,2,'lll','etude',NULL,DATE_FORMAT('09/12/2008', 'DD/MM/YYYY'));
INSERT INTO Student values(4,'Frida','bol@smail.th-koeln.de',2,4,'ppp','pass',NULL,DATE_FORMAT('17/12/2000', 'DD/MM/YYYY'));

/*Erstellung Gruppe */
INSERT INTO Gruppe values(1,1,3,'TEST',5,'1','1',DATE_FORMAT('17/06/2020', 'DD/MM/YYYY'),'Gummersbach');
INSERT INTO Gruppe values(2,2,2,'zudy',3,'1','1',DATE_FORMAT('17/06/2020', 'DD/MM/YYYY'),'Gummersbach');
INSERT INTO Gruppe values(3,3,1,'PP',3,'1','0',DATE_FORMAT('01/07/2020', 'DD/MM/YYYY'),'Koeln');
INSERT INTO Gruppe values(4,3,1,'ALGO',2,'0','1',DATE_FORMAT('01/06/2020', 'DD/MM/YYYY'),'Koeln');

/* Erstellung Gruppenbeitrag */

INSERT INTO GruppenBeitrag values(1,1,2,'2015-12-17','hello world');
INSERT INTO GruppenBeitrag values(2,2,1,'2020-06-17','was lauft..');
INSERT INTO GruppenBeitrag values(3,1,2,'2020-07-17' ,'wann ist naechste ..');
INSERT INTO GruppenBeitrag values(4,3,2,'2019-02-01','Termin wird verschoben ..');
INSERT INTO GruppenBeitrag values(5,3,2,'2020-05-17','ich bin heute nicht dabei..');
INSERT INTO GruppenBeitrag values(6,3,2,'2020-07-17','wann ist naechste ..');

/*Erstellung gruppeDiensLink */

INSERT INTO GruppenDienstlink values('1','https://ggogleTrst');
INSERT INTO GruppenDienstlink values('2','https://google.de');
INSERT INTO GruppenDienstlink values('4','https://test.de');

/*Erstellung beitrittsAnfrage */

INSERT INTO GruppenAnfrage values(1,2,SYSDATE(),'hello, ich wuerde gerne..', '1');
INSERT INTO GruppenAnfrage values(3,1,ifnull(DATE_FORMAT('17/12/2015', 'DD/MM/YYYY'), ''),'hello, ich wuerde gerne..','1');
INSERT INTO GruppenAnfrage values(2,3,ifnull(DATE_FORMAT('17/12/2019', 'DD/MM/YYYY'), ''),'hello, ich wuerde gerne..','0');
COMMIT;

-- endregion

-- region Notizen

-- TODO Anstatt eines Triggers welcher das Datum des erstellten Beitrags
--      überprüft, wäre eine Prozedur welche einen Beitrag erstellt sinnvoller.
/*/
-- FIXME: Trigger wurde einfach nur von `trigger_Gruppe_deadline` kopiert.
CREATE TRIGGER trigger_GruppenBeitrag_datum
    BEFORE INSERT
    ON GruppenBeitrag
    FOR EACH ROW
BEGIN
    IF (:NEW.datum < SYSDATE)
    THEN
        RAISE_APPLICATION_ERROR(
            -20002,
            'Datum darf nicht in der Vergangenheit liegen.' ||
                to_char(:NEW.datum, 'YYYY-MM-DD HH24:MI:SS')
        );
    END IF;
END;
/
/**/

-- TODO [Trigger] Einfügen überlappender Treffzeiten zusammenführen.
-- Falls ein einzufügender Zeitintervall mit einem anderen überlappt
-- sollte der existierende geupdated werden anstatt einen Fehler zu werden.
-- -> { von: MIN(:old.von, :new.von), bis: MAX(:old.bis, :new.bis) }

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

-- TODO [Tabelle] Treffzeiten nach Wochentag.

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
