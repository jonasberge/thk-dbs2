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

SET max_sp_recursion_depth = 7;

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
    modul_id     INT                 NOT NULL,
    ersteller_id INT                 NOT NULL,
    name         VARCHAR(64)         NOT NULL,
    `limit`      TINYINT DEFAULT 8,
    oeffentlich  CHAR(1) DEFAULT '1' NOT NULL,
    betretbar    CHAR(1) DEFAULT '0' NOT NULL
        COMMENT 'Studenten können der Gruppe beitreten ohne erst vom Ersteller angenommen werden zu müssen.',
    deadline     DATETIME,
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
    gruppe_id  INT                    NOT NULL,
    student_id INT, -- Darf NULL sein, falls Nutzer gelöscht wurde.
    datum      DATETIME               NOT NULL,
    nachricht  VARCHAR(1024)          NOT NULL,
    typ        CHAR(8) DEFAULT 'USER' NOT NULL,
    FOREIGN KEY (gruppe_id)
        REFERENCES Gruppe (id),
    FOREIGN KEY (student_id)
        REFERENCES Student (id)
);

ALTER TABLE GruppenBeitrag
    ADD CONSTRAINT check_GruppenBeitrag_typ
        CHECK (typ IN ('USER', 'SYSTEM', 'BIRTHDAY'));

CREATE INDEX index_GruppenBeitrag_gruppe_datum
    ON GruppenBeitrag (gruppe_id, datum);

ALTER TABLE GruppenBeitrag
    ADD CONSTRAINT check_GruppenBeitrag_nachricht
        CHECK (LENGTH(nachricht) > 0);

-- Studenten die in einer Gruppe sind.
CREATE TABLE Gruppe_Student (
    gruppe_id      INT      NOT NULL,
    student_id     INT      NOT NULL,
    beitrittsdatum DATETIME NOT NULL,
    PRIMARY KEY (gruppe_id, student_id),
    FOREIGN KEY (gruppe_id)
        REFERENCES Gruppe (id),
    FOREIGN KEY (student_id)
        REFERENCES Student (id)
);

-- Anfrage eines Studenten um einer Gruppe beizutreten.
CREATE TABLE GruppenAnfrage (
    gruppe_id  INT                        NOT NULL,
    student_id INT                        NOT NULL,
    datum      DATETIME     DEFAULT NOW() NOT NULL,
    nachricht  VARCHAR(256) DEFAULT NULL,
    bestaetigt CHAR(1)      DEFAULT '0'   NOT NULL,
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
    gueltig_bis  DATETIME,
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

-- Alternative Version der Prozedur `LerngruppenAusgeben` !

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

-- Der Trigger zum Senden einer Geburtstags-Nachricht wurde hier in die Prozedur verlegt.

DELIMITER //
CREATE PROCEDURE GruppenBeitragVerfassen
    (IN in_typ        CHAR(8),
     IN in_nachricht  VARCHAR(1024),
     IN in_gruppe_id  INTEGER,
     IN in_student_id INTEGER)
this_procedure: BEGIN
    DECLARE heute_geburtstag   INTEGER;
    DECLARE bereits_gratuliert INTEGER;

    DECLARE v_gruppe_id        INTEGER;
    DECLARE v_student_id       INTEGER;
    DECLARE v_datum            DATETIME;
    DECLARE v_student_name     VARCHAR(64);

    INSERT INTO GruppenBeitrag (gruppe_id, student_id, datum, nachricht, typ)
    VALUES (in_gruppe_id, in_student_id, NOW(), in_nachricht, in_typ);

    IF in_typ <> 'USER' THEN
        LEAVE this_procedure;
    END IF;

    -- Nur wer fleißig in die Gruppe schreibt bekommt ein Happy Birthday!

    SELECT CASE -- TODO: use COUNT(1) and put the condition into the WHERE clause.
        WHEN DATE_FORMAT(geburtsdatum, '%m-%d') = DATE_FORMAT(NOW(), '%m-%d') THEN 1 ELSE 0
    END INTO heute_geburtstag
    FROM Student s WHERE s.id = in_student_id;

    IF heute_geburtstag = 0 THEN
        LEAVE this_procedure;
    END IF;

    SELECT gruppe_id, student_id, s.name, datum
    INTO v_gruppe_id, v_student_id, v_student_name, v_datum
    FROM GruppenBeitrag gb
    LEFT JOIN Student s ON s.id = gb.student_id
    WHERE gb.id = in_gruppe_id;

    -- Überprüfe ob bereits eine Gratulation vorliegt.
    SELECT COUNT(1) INTO bereits_gratuliert
    FROM GruppenBeitrag
    WHERE typ = 'BIRTHDAY'
      AND student_id = v_student_id
      AND DATE_FORMAT(datum, '%Y') = DATE_FORMAT(CURRENT_DATE, '%Y');

    IF bereits_gratuliert = 0 THEN
        -- Nachrichten vom Typ 'BIRTHDAY' können beim Client speziell formatiert werden.
        -- Die student_id ist hier nicht der Autor, sondern der Student welcher Geburtstag hat.
        -- Mit dieser ID können dann später Informationen wie der Name des Studenten abgefragt werden.
        CALL GruppenBeitragVerfassen('BIRTHDAY', '.', v_gruppe_id, v_student_id);
    END IF;
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

DROP PROCEDURE IF EXISTS LerngruppenAusgeben;

CREATE PROCEDURE LerngruppenAusgeben(modul_id INTEGER)
BEGIN
    DECLARE v_name         VARCHAR(64);
    DECLARE v_ersteller_id INTEGER;
    DECLARE v_gruppe_id    INTEGER;
    DECLARE v_mitglieder   INTEGER;
    DECLARE v_deadline     DATETIME;
    DECLARE komma          CHAR(1) DEFAULT ',';

    DECLARE modul_existiert INTEGER;
    DECLARE done INT DEFAULT FALSE;

    DECLARE gruppe_cursor CURSOR FOR
        SELECT name, ersteller_id, deadline, id
        FROM Gruppe;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;


    SELECT COUNT(id) INTO modul_existiert
    FROM Modul WHERE Modul.id = modul_id;

    IF modul_existiert = 0 THEN
        signal sqlstate '20131' set message_text = 'Dieses Modul existiert nicht.';
    END IF;

    OPEN gruppe_cursor;

    this_loop: LOOP
        FETCH gruppe_cursor
            INTO v_name, v_ersteller_id, v_deadline, v_gruppe_id;

        IF done THEN
            IF FOUND_ROWS() = 0 THEN
                signal sqlstate '20132' set message_text = 'Keine Lerngruppen gefunden!';
            END IF;
            LEAVE this_loop;
        END IF;

        SELECT COUNT(student_id) INTO v_mitglieder
        FROM Gruppe_Student
        WHERE Gruppe_Student.gruppe_id = v_gruppe_id;

        SELECT CONCAT(
            'Gruppenname=', v_name, komma,
            'Mitgliederanzahl=', CAST(v_mitglieder AS CHAR), komma,
            'Ersteller=', CAST(v_ersteller_id AS CHAR), komma,
            'Deadline=', IFNULL(DATE_FORMAT(v_deadline, '%d.%m.%Y %H:%i:%s'), 'NULL')
        );
    END LOOP;
    CLOSE gruppe_cursor;
END;

DROP  PROCEDURE IF EXISTS LetzterBeitragVonGruppe;

/* PROCEDURE FÜR LETZER BEITRAG EINER GRUPPE */
delimiter //
CREATE PROCEDURE LetzterBeitragVonGruppe(v_gruppe_id INT )
BEGIN
    DECLARE r_comment VARCHAR(250);
    DECLARE v_name VARCHAR(250);
    DECLARE v_start datetime;
    DECLARE v_date datetime;
    DECLARE nr INT;
    DECLARE finished INT DEFAULT 0;

    DECLARE kundenCursor CURSOR FOR  SELECT  (b.datum ),e.name, b.Nachricht
    FROM  GruppenBeitrag b INNER JOIN Gruppe e  ON  b.gruppe_id = e.id
    where b.gruppe_id = v_gruppe_id ORDER BY b.datum DESC LIMIT 1;

    DECLARE CONTINUE HANDLER FOR SQLSTATE '02000' SET finished=1;

    /*Eine temporaere Table erzeugen um die Werten abzuspeichern */
    DROP TEMPORARY TABLE IF EXISTS TempTable;
	CREATE TEMPORARY TABLE TempTable( v_date DATETIME,v_name VARCHAR(250),r_comment VARCHAR(250));

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

DROP TRIGGER IF EXISTS trigger_Gruppe;

DELIMITER //
CREATE TRIGGER trigger_Gruppe
AFTER INSERT ON Gruppe
FOR EACH ROW
BEGIN
    INSERT INTO Gruppe_Student (gruppe_id, student_id, beitrittsdatum)
    VALUES (NEW.id, NEW.ersteller_id, NOW());
END //
DELIMITER ;

DROP TRIGGER IF EXISTS trigger_GruppenAnfrage_insert;

DELIMITER //
CREATE TRIGGER trigger_GruppenAnfrage_insert
BEFORE INSERT ON GruppenAnfrage
FOR EACH ROW
BEGIN
    DECLARE gruppe_betretbar INTEGER;
    DECLARE bereits_in_gruppe INTEGER;
    DECLARE anfrage_existiert INTEGER;

    SELECT g.betretbar INTO gruppe_betretbar
    FROM Gruppe g
    WHERE g.id = new.gruppe_id;

    IF gruppe_betretbar = '1' THEN
        signal sqlstate '20032' set message_text = 'Diese Gruppe erfordert keine Anfrage.';
    END IF;

    SELECT COUNT(1) INTO bereits_in_gruppe
    FROM Gruppe_Student gs
    WHERE gs.gruppe_id = new.gruppe_id AND gs.student_id = new.student_id;

    IF bereits_in_gruppe = 1 THEN
        signal sqlstate '20033' set message_text = 'Der anfragende Nutzer ist bereits in dieser Gruppe.';
    END IF;

    SELECT COUNT(1) INTO anfrage_existiert
    FROM GruppenAnfrage ga
    WHERE ga.gruppe_id = new.gruppe_id AND ga.student_id = new.student_id;

    IF anfrage_existiert = 1 THEN
        signal sqlstate '20034' set message_text = 'Es existiert bereits eine Anfrage für diesen Nutzer.';
    END IF;

    IF new.bestaetigt = '1' THEN
        signal sqlstate '20035' set message_text = 'Eine neue Gruppenanfrage muss unbestätigt sein.';
    END IF;

    SET new.datum := NOW(); -- Stelle sicher dass das Datum aktuell ist.
END //
DELIMITER ;

DROP TRIGGER IF EXISTS trigger_GruppenAnfrage_update;

DELIMITER //
CREATE TRIGGER trigger_GruppenAnfrage_update
BEFORE UPDATE ON GruppenAnfrage
FOR EACH ROW
BEGIN
    IF OLD.gruppe_id != NEW.gruppe_id
           OR OLD.student_id != NEW.student_id
           OR OLD.datum != NEW.datum THEN
        signal sqlstate '20031' set message_text = 'Nur die Nachricht einer Anfrage oder deren Status kann bearbeitet werden.';
    END IF;
END //
DELIMITER ;

DROP TRIGGER IF EXISTS trigger_GruppeBeitreten;

DELIMITER // -- delimiter setzen
CREATE TRIGGER trigger_GruppeBeitreten
BEFORE INSERT ON Gruppe_Student
FOR EACH ROW
BEGIN
    DECLARE g_limit TINYINT;
    DECLARE g_betretbar CHAR(1);
    DECLARE g_deadline DATETIME;
    DECLARE g_ersteller_id INTEGER;

    DECLARE anzahl_mitglieder INT;
    DECLARE anfrage_bestaetigt INT;

    SELECT `limit`, betretbar, deadline
    INTO g_limit, g_betretbar, g_deadline
    FROM Gruppe g
    WHERE g.id = NEW.gruppe_id;

    SELECT COUNT(student_id) + 1 -- addiere 1, da aktueller Nutzer noch nicht eingefügt.
    INTO anzahl_mitglieder
    FROM Gruppe_Student
    WHERE gruppe_id = NEW.gruppe_id;

    -- Bei MySQL kein Mutating Table Problem bei Select
    -- Wert bleibt aber bei jeder Zeile gleich (Zustand vor dem Insert)
    -- Limit Abfrage greift nur wenn Gruppe zu Beginn schon zu viele Mitglieder hat
    -- Daher Lösung außerhalb des Triggers hierfür nötig

    IF anzahl_mitglieder > g_limit THEN
        set @message_text = CONCAT(
            'Insert in Gruppe ', NEW.gruppe_id,
            ' überschreitet mit ', anzahl_mitglieder,
            ' Mitgliedern das Limit von ', g_limit
        );
        signal sqlstate '20001' set message_text = @message_text;
    END IF;

    IF g_deadline IS NOT NULL AND g_deadline < NOW() THEN
        signal sqlstate '20002' set message_text = 'Beitritt nicht mehr möglich, Deadline überschritten.';
    END IF;

    SELECT ersteller_id INTO g_ersteller_id
    FROM Gruppe g WHERE g.id = NEW.gruppe_id;

    -- Eine bestätigte Anfrage muss nur vorliegen falls
    -- der einzufügende Student nicht der Ersteller ist.
    IF g_betretbar = '0' AND NEW.student_id <> g_ersteller_id THEN
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

    CALL GruppenBeitragVerfassen('SYSTEM',
        CONCAT(StudentenName(NEW.student_id), ' ist der Gruppe beigetreten.'),
        NEW.gruppe_id, NULL
    );
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

    CALL GruppenBeitragVerfassen('SYSTEM',
        concat(StudentenName(old.student_id), ' hat die Gruppe verlassen.'),
        old.gruppe_id, NULL
    );

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

    CALL GruppenBeitragVerfassen('SYSTEM',
        concat(StudentenName(neuer_besitzer_id), ' wurde zum neuen Gruppenleiter erwählt.'),
        old.gruppe_id, NULL
    );
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
SELECT COUNT(gruppe_id) INTO v_anzahl FROM GruppenDienstlink WHERE gruppe_id = NEW.gruppe_id;
IF (v_anzahl > v_limit) THEN
SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Eine Gruppe kann nicht mehr als 5 Dienstlinks haben.';
 END IF;
 END //
DELIMITER ;

-- endregion

-- region Notizen

-- TODO [Trigger] Einfügen überlappender Treffzeiten zusammenführen.
-- Falls ein einzufügender Zeitintervall mit einem anderen überlappt
-- sollte der existierende geupdated werden anstatt einen Fehler zu werden.
-- -> { von: MIN(:old.von, :new.von), bis: MAX(:old.bis, :new.bis) }

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
