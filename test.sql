-- region DELETE

DELETE FROM Gruppe_Student;
DELETE FROM Gruppe;
DELETE FROM Student;
DELETE FROM Modul;
DELETE FROM Studiengang;
DELETE FROM Fakultaet;

DROP VIEW view_test_AccountZuruecksetzen;

-- endregion

-- region [Test] Account zurücksetzen

CREATE VIEW view_test_AccountZuruecksetzen AS
SELECT g.name as gruppe, listagg(
    s.name || (CASE WHEN s.id = g.ersteller_id THEN '*' ELSE '' END),
    ', '
) WITHIN GROUP (
    ORDER BY CASE WHEN s.id = g.ersteller_id THEN 0 ELSE 1 END, s.id
) as teilnehmer
FROM Gruppe_Student gs
INNER JOIN Gruppe g ON g.id = gs.gruppe_id
INNER JOIN Student s ON s.id = gs.student_id
GROUP BY g.id, g.name
ORDER BY g.id;

-- region Test-Daten einfügen

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

-- TODO: Gruppenerstellung in Prozedur auslagern.
-- Die Ersteller einer Gruppe werden auch in Gruppe_Student eingefügt.
INSERT INTO Gruppe_Student (GRUPPE_ID, STUDENT_ID, BEITRITTSDATUM)
SELECT 1, 1, SYSDATE FROM dual UNION
SELECT 2, 1, SYSDATE FROM dual UNION
SELECT 3, 2, SYSDATE FROM dual;

INSERT INTO Gruppe_Student (GRUPPE_ID, STUDENT_ID, BEITRITTSDATUM)
SELECT 2, 2 /* Peter */, TO_DATE('17.05.2020', 'dd.mm.yyyy') FROM dual UNION
SELECT 2, 3 /* Hans  */, TO_DATE('18.05.2020', 'dd.mm.yyyy') FROM dual;

INSERT INTO Gruppe_Student (GRUPPE_ID, STUDENT_ID, BEITRITTSDATUM)
VALUES (3, 1, SYSDATE);

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

ROLLBACK;
DROP VIEW view_test_AccountZuruecksetzen;

-- endregion
