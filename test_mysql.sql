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

INSERT INTO Gruppe (ID, MODUL_ID, BETRETBAR, ERSTELLER_ID, NAME)
    SELECT 1, 1, '1', 1 /* Frank */, 'Mathe-Boyz'    FROM dual UNION
    SELECT 2, 1, '0', 1 /* Frank */, 'Mathe-Boyz #2' FROM dual UNION
    SELECT 3, 1, '1', 2 /* Peter */, 'Math Rivals'   FROM dual;

-- endregion

/* [Vorher]
    GRUPPE          ID      BETRETBAR   DEADLINE   MITGLIEDER
    Mathe-Boyz      1       ja          keine       /
    Mathe-Boyz #2   2       auf Anfrage keine       /
    Math Rivals     3       ja          keine       /

    STUDENT ID
    Frank   1
    Peter   2
    Hans    3
*/

-- Beitritt nur bei bestätigter Anfrage möglich
INSERT INTO Gruppe_Student (GRUPPE_ID, STUDENT_ID, BEITRITTSDATUM)
VALUES (2, 1, NOW()); -- Erster Beitrittsversuch gelingt nicht

INSERT INTO GruppenAnfrage (GRUPPE_ID, STUDENT_ID, BESTAETIGT, DATUM)
VALUES (2, 1, '1', NOW()); -- Gruppenanfrage gestellt und bestätigt

INSERT INTO Gruppe_Student (GRUPPE_ID, STUDENT_ID, BEITRITTSDATUM)
VALUES (2, 1, NOW()); -- Erneuter Beitrittsversuch erfolgreich

-- Beitritt nur vor Deadline möglich
-- Für Gruppe 1 Deadline in Vergangenheit setzen
UPDATE Gruppe SET deadline = NOW() - INTERVAL 1 DAY WHERE id = 1;
INSERT INTO Gruppe_Student (GRUPPE_ID, STUDENT_ID, BEITRITTSDATUM)
    SELECT 1, 1, NOW() FROM dual; -- Beitritt nicht mehr möglich

-- Insert nur möglich wenn Limit an Mitgliedern nicht überschritten wird
-- Funktioniert bei unserem MySQL Trigger nicht, muss außerhalb der DB gelöst werden
UPDATE Gruppe SET `limit` = 1 WHERE id = 3; -- Für Gruppe 3 Limit auf 1 setzen

INSERT INTO Gruppe_Student (GRUPPE_ID, STUDENT_ID, BEITRITTSDATUM)
    SELECT 3, 1, NOW() FROM dual UNION
    SELECT 3, 2, NOW() FROM dual; -- Nun 2 Mitglieder drin obwohl Limit 1

-- region [teardown]

ROLLBACK;

-- endregion

-- endregion

-- region [Test] Funktion GruppenAuflistenNachModul

-- region [setup]
INSERT INTO Fakultaet (ID, NAME, STANDORT)
VALUES (1, 'Informatik', 'Gummersbach');

INSERT INTO Studiengang (ID, NAME, FAKULTAET_ID, ABSCHLUSS)
VALUES (1, 'Informatik', 1, 'BSC.INF');

INSERT INTO Modul (ID, NAME, DOZENT, SEMESTER)
VALUES (1, 'Mathematik 1', 'Wolfgang Konen', 1);

INSERT INTO Modul (ID, NAME, DOZENT, SEMESTER)
VALUES (2, 'AP2', 'Christian Kohls', 2);

INSERT INTO Student (ID, NAME, SMAIL_ADRESSE, PASSWORT_HASH,
                     PROFIL_BESCHREIBUNG, PROFIL_BILD, STUDIENGANG_ID, SEMESTER)
    SELECT 1, 'Frank', 'frank@th-koeln.de', 'h', 'Ich mag Informatik.',              NULL, 1, 1 FROM dual UNION
    SELECT 2, 'Peter', 'peter@th-koeln.de', 'h', 'Ich bin Technologie-begeistert.',  NULL, 1, 1 FROM dual UNION
    SELECT 3, 'Hans',   'hans@th-koeln.de', 'h', 'Tortillas sind meine Spezialität', NULL, 1, 1 FROM dual;

INSERT INTO Gruppe (ID, MODUL_ID, BETRETBAR, ERSTELLER_ID, NAME)
    SELECT 1, 1, '1', 1 /* Frank */, 'Mathe-Boyz'    FROM dual UNION
    SELECT 2, 1, '0', 1 /* Frank */, 'Mathe-Boyz #2' FROM dual UNION
    SELECT 3, 1, '1', 2 /* Peter */, 'Math Rivals'   FROM dual;

INSERT INTO Gruppe (ID, MODUL_ID, BETRETBAR, ERSTELLER_ID, NAME)
    SELECT 4, 2, '1', 1 /* Frank */, 'AP2-Masters'    FROM dual UNION
    SELECT 5, 2, '0', 1 /* Frank */, 'AP2-Masters #2' FROM dual UNION
    SELECT 6, 2, '1', 2 /* Peter */, 'AP2 Crew'   FROM dual;

INSERT INTO Gruppe_Student (GRUPPE_ID, STUDENT_ID, BEITRITTSDATUM)
    SELECT 1, 1, CURRENT_DATE FROM dual UNION
    SELECT 2, 1, CURRENT_DATE FROM dual UNION
    SELECT 3, 2, CURRENT_DATE FROM dual;

INSERT INTO Gruppe_Student (GRUPPE_ID, STUDENT_ID, BEITRITTSDATUM)
    SELECT 2, 2 /* Peter */, STR_TO_DATE('17.05.2020', '%d.%m.%Y') FROM dual UNION
    SELECT 2, 3 /* Hans  */, STR_TO_DATE('18.05.2020', '%d.%m.%Y') FROM dual;

INSERT INTO Gruppe_Student (GRUPPE_ID, STUDENT_ID, BEITRITTSDATUM)
VALUES (3, 1, CURRENT_DATE);

INSERT INTO Gruppe_Student (GRUPPE_ID, STUDENT_ID, BEITRITTSDATUM)
    SELECT 4, 1, CURRENT_DATE FROM dual UNION
    SELECT 5, 1, CURRENT_DATE FROM dual UNION
    SELECT 6, 2, CURRENT_DATE FROM dual;

INSERT INTO Gruppe_Student (GRUPPE_ID, STUDENT_ID, BEITRITTSDATUM)
    SELECT 5, 2 /* Peter */, STR_TO_DATE('17.05.2020', '%d.%m.%Y') FROM dual UNION
    SELECT 4, 3 /* Hans  */, STR_TO_DATE('18.05.2020', '%d.%m.%Y') FROM dual;

INSERT INTO Gruppe_Student (GRUPPE_ID, STUDENT_ID, BEITRITTSDATUM)
    SELECT 4, 2 /* Peter */, STR_TO_DATE('17.05.2020', '%d.%m.%Y') FROM dual UNION
    SELECT 5, 3 /* Hans  */, STR_TO_DATE('18.05.2020', '%d.%m.%Y') FROM dual UNION
    SELECT 6, 1 /* Peter */, STR_TO_DATE('17.05.2020', '%d.%m.%Y') FROM dual;

-- endregion

-- Liste alle Mathe1-Gruppen auf
SELECT GruppenAuflistenNachModul(1) FROM DUAL;
-- Liste alle AP2-Gruppen auf
SELECT GruppenAuflistenNachModul(2) FROM DUAL;
-- Zähle AP2-Gruppen
SELECT JSON_LENGTH(GruppenAuflistenNachModul(2)) FROM DUAL;

-- region [teardown]

ROLLBACK;

-- endregion

-- endregion
/*****  TESTFALL ***/

delete fakultaet;
delete studiengang;
delete modul;
delete student;
delete gruppe;
delete gruppenBeitrag;
DROP VIEW gruppe_Comment;

/* Prozedur letzer Beitrag  von einer gruppe anhand von der gruppe_id  ausgeben----- */
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
INSERT INTO GruppenDienstLink values('1','https://ggogleTrst');
INSERT INTO GruppenDienstLink values('2','https://google.de');
INSERT INTO GruppenDienstLink values('4','https://test.de');

/*Erstellung beitrittsAnfrage */
INSERT INTO GruppenAnfrage values(1,2,SYSDATE(),'hello, ich wuerde gerne..', '1');
INSERT INTO GruppenAnfrage values(3,1,ifnull(DATE_FORMAT('17/12/2015', 'DD/MM/YYYY'), ''),'hello, ich wuerde gerne..','1');
INSERT INTO GruppenAnfrage values(2,3,ifnull(DATE_FORMAT('17/12/2019', 'DD/MM/YYYY'), ''),'hello, ich wuerde gerne..','0');


------CREATE view vomment zum Beispiel for gruppe mit id = 3--------------------------------
CREATE OR REPLACE VIEW  gruppe_Comment AS
SELECT * FROM gruppenBeitrag gb where gb.gruppe_id = 3;

SELECT * FROM  gruppe_Comment;

/* Ergebnisse vorher
id	gruppe_id	student_id	        datum	            nachricht

4	    3	        2	        2019-02-01	            Termin wird ..
5	    3	        2	        2020-05-17	            ich bin heute nicht dabei..
6	    3	        2	        2020-07-17	            wann ist naechste ..
..		..			.				..			        ...
..		..			.				..			        ..
  */
/*----  mit dem PROCEDURE  LetzterBeitragVonGruppe(gruppe ID) lässt sich das
letze beitrag von einer gruppe  ausgeben-----
*/
CALL LetzterBeitragVonGruppe(3);

/*Ergebnis naher

DATUM    GruppeName    Nachricht
17.07.20    PP    wann ist naechste ..

*/

--- Complexe View erstellen : alle beitragen von den Studenten mit Studiengang INFORMATIK
CREATE or replace VIEW studentNachricht AS
SELECT gb.id, gb.nachricht, gb.gruppe_id,gb.student_id, s.name, st.abschluss
from gruppenBeitrag gb , student s,  studiengang st
where gb.student_id = s.id
AND UPPER(st.name) LIKE '%INF%';

/*Eine view von dem studenten mit ID = 2 als Beispiel erstellen */

SELECT * FROM studentNachricht WHERE  student_id = 2;
/*
id	            nachricht	                    gruppe_id	        student_id	     name	        abschluss
1	            hello world	                      1	                    2	        Hermann     	BSC.ING
3	            wann ist naechste ..	            1	                    2	        Hermann	      BSC.ING
4	            Termin wird ..	                  3	                    2	        Hermann	      BSC.ING
5	            ich bin heute nicht dabei..	      3	                    2	        Hermann	      BSC.ING
6	            wann ist naechste ..	            3	                    2	        Hermann	      BSC.ING

*/


