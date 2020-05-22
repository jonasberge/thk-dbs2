-- region DELETE

DELETE FROM Gruppe_Student;
DELETE FROM GruppenBeitrag;
DELETE FROM GruppenAnfrage;
DELETE FROM Gruppe;
DELETE FROM Student;
DELETE FROM Modul;
DELETE FROM Studiengang;
DELETE FROM Fakultaet;

-- endregion

-- region [Test] Account zurücksetzen

-- region [setup]

CREATE VIEW view_test_AccountZuruecksetzen AS
SELECT g.name as gruppe, group_concat(
    CONCAT(s.name, (IF(s.id = g.ersteller_id, '*', '')))
    ORDER BY IF(s.id = g.ersteller_id, 0, 1), s.id
    SEPARATOR ', '
) as teilnehmer
FROM Gruppe_Student gs
INNER JOIN Gruppe g ON g.id = gs.gruppe_id
INNER JOIN Student s ON s.id = gs.student_id
GROUP BY g.id, g.name
ORDER BY g.id;

INSERT INTO Fakultaet (ID, NAME, STANDORT)
VALUES (1, 'Informatik', 'Gummersbach');

INSERT INTO Studiengang (ID, NAME, FAKULTAET_ID, ABSCHLUSS)
VALUES (1, 'Informatik', 1, 'BSC.INF');

INSERT INTO Modul (ID, NAME, DOZENT, SEMESTER)
VALUES (1, 'Mathematik 1', 'Wolfgang Konen', 1);

INSERT INTO Student (ID, NAME, SMAIL_ADRESSE, PASSWORT_HASH,
                     PROFIL_BESCHREIBUNG, PROFIL_BILD, STUDIENGANG_ID, SEMESTER)
SELECT 1, 'Frank', 'frank@th-koeln.de', 'h', 'Ich mag Informatik.',              NULL, 1, 1 FROM dual UNION
SELECT 2, 'Peter', 'peter@th-koeln.de', 'h', 'Ich bin Technologie-begeistert.',  NULL, 1, 1 FROM dual UNION
SELECT 3, 'Hans',   'hans@th-koeln.de', 'h', 'Tortillas sind meine Spezialität', NULL, 1, 1 FROM dual;

INSERT INTO Gruppe (ID, MODUL_ID, ERSTELLER_ID, NAME, BETRETBAR)
SELECT 1, 1, 1 /* Frank */, 'Mathe-Boyz',    '1' FROM dual UNION
SELECT 2, 1, 1 /* Frank */, 'Mathe-Boyz #2', '1' FROM dual UNION
SELECT 3, 1, 2 /* Peter */, 'Math Rivals',   '1' FROM dual;

-- TODO: Gruppenerstellung in Prozedur auslagern.
-- Die Ersteller einer Gruppe werden auch in Gruppe_Student eingefügt.
INSERT INTO Gruppe_Student (GRUPPE_ID, STUDENT_ID, BEITRITTSDATUM)
SELECT 1, 1, CURRENT_DATE FROM dual UNION
SELECT 2, 1, CURRENT_DATE FROM dual UNION
SELECT 3, 2, CURRENT_DATE FROM dual;

INSERT INTO Gruppe_Student (GRUPPE_ID, STUDENT_ID, BEITRITTSDATUM)
SELECT 2, 2 /* Peter */, STR_TO_DATE('17.05.2020', '%d.%m.%Y') FROM dual UNION
SELECT 2, 3 /* Hans  */, STR_TO_DATE('18.05.2020', '%d.%m.%Y') FROM dual;

INSERT INTO Gruppe_Student (GRUPPE_ID, STUDENT_ID, BEITRITTSDATUM)
VALUES (3, 1, CURRENT_DATE);

-- endregion

/* [Vorher]
    GRUPPE         TEILNEHMER
    Mathe-Boyz     Frank*
    Mathe-Boyz #2  Frank*, Peter, Hans
    Math Rivals    Peter*, Frank
*/
SELECT * FROM view_test_AccountZuruecksetzen;

CALL AccountZuruecksetzen(1 /* Frank */);

/* [Nachher]
    GRUPPE         TEILNEHMER
    Mathe-Boyz #2  Peter*, Hans
    Math Rivals    Peter*
*/
SELECT * FROM view_test_AccountZuruecksetzen;

-- region [teardown]

ROLLBACK;
DROP VIEW view_test_AccountZuruecksetzen;

-- endregion

-- endregion

-- region [Test] Trigger GruppeBeitritt

-- region [setup]

INSERT INTO Fakultaet (ID, NAME, STANDORT)
VALUES (1, 'Informatik', 'Gummersbach');

INSERT INTO Studiengang (ID, NAME, FAKULTAET_ID, ABSCHLUSS)
VALUES (1, 'Informatik', 1, 'BSC.INF');

INSERT INTO Modul (ID, NAME, DOZENT, SEMESTER)
VALUES (1, 'Mathematik 1', 'Wolfgang Konen', 1);

INSERT INTO Student (ID, NAME, SMAIL_ADRESSE, PASSWORT_HASH,
                     PROFIL_BESCHREIBUNG, PROFIL_BILD, STUDIENGANG_ID, SEMESTER)
SELECT 1, 'Frank', 'frank@th-koeln.de', 'h', 'Ich mag Informatik.',              NULL, 1, 1 FROM dual UNION
SELECT 2, 'Peter', 'peter@th-koeln.de', 'h', 'Ich bin Technologie-begeistert.',  NULL, 1, 1 FROM dual UNION
SELECT 3, 'Hans',   'hans@th-koeln.de', 'h', 'Tortillas sind meine Spezialität', NULL, 1, 1 FROM dual;

INSERT INTO Gruppe (ID, MODUL_ID, ERSTELLER_ID, NAME)
SELECT 1, 1, 1 /* Frank */, 'Mathe-Boyz'    FROM dual UNION
SELECT 2, 1, 1 /* Frank */, 'Mathe-Boyz #2' FROM dual UNION
SELECT 3, 1, 2 /* Peter */, 'Math Rivals'   FROM dual;

UPDATE Gruppe SET betretbar = '1' WHERE id = 1;

-- endregion

-- Beitritt nur bei bestätigter Anfrage möglich
INSERT INTO Gruppe_Student (GRUPPE_ID, STUDENT_ID, BEITRITTSDATUM)
SELECT 2, 1, NOW() FROM dual;

INSERT INTO GruppenAnfrage (GRUPPE_ID, STUDENT_ID, BESTAETIGT, DATUM)
SELECT 2, 1, '1', NOW() FROM dual;

INSERT INTO Gruppe_Student (GRUPPE_ID, STUDENT_ID, BEITRITTSDATUM)
SELECT 2, 1, NOW() FROM dual;

-- Beitritt nur vor Deadline möglich
UPDATE Gruppe SET deadline = NOW() - INTERVAL 1 DAY WHERE id = 1;
INSERT INTO Gruppe_Student (GRUPPE_ID, STUDENT_ID, BEITRITTSDATUM)
SELECT 1, 1, NOW() FROM dual;

-- Insert nur möglich wenn Limit an Mitgliedern nicht überschritten wird
UPDATE Gruppe SET betretbar = '1' WHERE id = 3;
UPDATE Gruppe SET `limit` = 2 WHERE id = 3;
INSERT INTO Gruppe_Student (GRUPPE_ID, STUDENT_ID, BEITRITTSDATUM)
SELECT 3, 1, NOW() FROM dual UNION
SELECT 3, 2, NOW() FROM dual UNION
SELECT 3, 3, NOW() FROM dual;

-- region [teardown]

ROLLBACK;

-- endregion

-- endregion
