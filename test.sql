-- region DELETE

DELETE FROM GruppenEinladung;
DELETE FROM GruppenAnfrage;
DELETE FROM Gruppe_Student;
DELETE FROM GruppenBeitrag;
DELETE FROM GruppenDienstlink;
DELETE FROM Gruppe;
DELETE FROM StudentWiederherstellung;
DELETE FROM StudentVerifizierung;
DELETE FROM EindeutigeKennung;
DELETE FROM Student;
DELETE FROM Studiengang_Modul;
DELETE FROM Modul;
DELETE FROM Studiengang;
DELETE FROM Fakultaet;

-- endregion


-- Mit * markierte Studenten in der Spalte `TEILNEHMER` sind Gruppenleiter.
CREATE OR REPLACE VIEW view_test_GruppenTeilnehmer AS
SELECT g.name as gruppe, listagg(
    s.name || (CASE WHEN s.id = g.ersteller_id THEN '*' ELSE '' END),
    ', '
) WITHIN GROUP (
    ORDER BY CASE WHEN s.id = g.ersteller_id THEN 0 ELSE 1 END, s.id
) as teilnehmer
FROM Gruppe g
LEFT JOIN Gruppe_Student gs ON g.id = gs.gruppe_id
LEFT JOIN Student s ON s.id = gs.student_id
GROUP BY g.id, g.name
ORDER BY g.id;


-- region [Test-Gruppe] Prozedur AccountZuruecksetzen

INSERT INTO Fakultaet (ID, NAME, STANDORT)
VALUES (1, 'Informatik', 'Gummersbach');

INSERT INTO Studiengang (ID, NAME, FAKULTAET_ID, ABSCHLUSS)
VALUES (1, 'Informatik', 1, 'BSC.INF');

INSERT INTO Modul (ID, NAME, DOZENT, SEMESTER)
VALUES (1, 'Mathematik 1', 'Wolfgang Konen', 1);

COMMIT;


-- region [Test] Gruppe löschen, falls einziger Teilnehmer

INSERT INTO Student (ID, NAME, SMAIL_ADRESSE, PASSWORT_HASH,
                     PROFIL_BESCHREIBUNG, PROFIL_BILD, STUDIENGANG_ID, SEMESTER)
SELECT 1, 'Frank', 'frank@th-koeln.de', 'h', 'Ich mag Informatik.',              NULL, 1, 1 FROM dual;

INSERT INTO Gruppe (ID, MODUL_ID, ERSTELLER_ID, NAME, BETRETBAR)
VALUES (1, 1, 1 /* Frank */, 'Mathe-Boyz', '1');

-- Mit * markierte Studenten in der Spalte `TEILNEHMER` sind Gruppenleiter.

/* [Vorher]
    GRUPPE         TEILNEHMER
    Mathe-Boyz     Frank*
*/
SELECT * FROM view_test_GruppenTeilnehmer;

CALL AccountZuruecksetzen(1 /* Frank */);

/* [Nachher]
    GRUPPE         TEILNEHMER
*/
SELECT * FROM view_test_GruppenTeilnehmer;

ROLLBACK;

-- endregion


-- region [Test] Nächsten Teilnehmer zum Gruppenleiter ernennen.

INSERT INTO Student (ID, NAME, SMAIL_ADRESSE, PASSWORT_HASH,
                     PROFIL_BESCHREIBUNG, PROFIL_BILD, STUDIENGANG_ID, SEMESTER)
SELECT 1, 'Frank', 'frank@th-koeln.de', 'h', 'Ich mag Informatik.',              NULL, 1, 1 FROM dual UNION
SELECT 2, 'Peter', 'peter@th-koeln.de', 'h', 'Ich bin Technologie-begeistert.',  NULL, 1, 1 FROM dual UNION
SELECT 3, 'Hans',   'hans@th-koeln.de', 'h', 'Tortillas sind meine Spezialität', NULL, 1, 1 FROM dual;

INSERT INTO Gruppe (ID, MODUL_ID, ERSTELLER_ID, NAME, BETRETBAR)
VALUES (1, 1, 1 /* Frank */, 'Mathe-Boyz #2', '1');

INSERT INTO Gruppe_Student (GRUPPE_ID, STUDENT_ID, BEITRITTSDATUM)
SELECT 1, 2 /* Peter */, TO_DATE('17.05.2020', 'dd.mm.yyyy') FROM dual UNION
SELECT 1, 3 /* Hans  */, TO_DATE('18.05.2020', 'dd.mm.yyyy') FROM dual;

/* [Vorher]
    GRUPPE         TEILNEHMER
    Mathe-Boyz #2  Frank*, Peter, Hans
*/
SELECT * FROM view_test_GruppenTeilnehmer;

CALL AccountZuruecksetzen(1 /* Frank */);

/* [Nachher]
    GRUPPE         TEILNEHMER
    Mathe-Boyz #2  Peter*, Hans
*/
SELECT * FROM view_test_GruppenTeilnehmer;

ROLLBACK;

-- endregion


-- region [Test] Account aus Gruppen löschen welchen dieser beigetreten ist.

INSERT INTO Student (ID, NAME, SMAIL_ADRESSE, PASSWORT_HASH,
                     PROFIL_BESCHREIBUNG, PROFIL_BILD, STUDIENGANG_ID, SEMESTER)
SELECT 1, 'Frank', 'frank@th-koeln.de', 'h', 'Ich mag Informatik.',              NULL, 1, 1 FROM dual UNION
SELECT 2, 'Peter', 'peter@th-koeln.de', 'h', 'Ich bin Technologie-begeistert.',  NULL, 1, 1 FROM dual;

INSERT INTO Gruppe (ID, MODUL_ID, ERSTELLER_ID, NAME, BETRETBAR)
VALUES (3, 1, 2 /* Peter */, 'Math Rivals', '1');

INSERT INTO Gruppe_Student (GRUPPE_ID, STUDENT_ID, BEITRITTSDATUM)
VALUES (3, 1 /* Frank */, SYSDATE);

/* [Vorher]
    GRUPPE         TEILNEHMER
    Math Rivals    Peter*, Frank
*/
SELECT * FROM view_test_GruppenTeilnehmer;

CALL AccountZuruecksetzen(1 /* Frank */);

/* [Nachher]
    GRUPPE         TEILNEHMER
    Math Rivals    Peter*
*/
SELECT * FROM view_test_GruppenTeilnehmer;

ROLLBACK;

-- endregion


DELETE FROM Modul;
DELETE FROM Studiengang;
DELETE FROM Fakultaet;

-- endregion [Test-Gruppe] Account zurücksetzen


-- region [Test-Gruppe] Trigger GruppenAnfrage

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
VALUES (1, 1, 1 /* Frank */, 'Mathe-Boyz', '1');

COMMIT;


-- region [Test] Anfrage ist nicht erforderlich

-- Wirft Fehler:
-- "Diese Gruppe erfordert keine Anfrage."
INSERT INTO GruppenAnfrage (GRUPPE_ID, STUDENT_ID)
VALUES (1, 1);

-- endregion


UPDATE Gruppe g
SET g.BETRETBAR = '0'
WHERE g.id = 1;

INSERT INTO GruppenAnfrage (GRUPPE_ID, STUDENT_ID)
VALUES (1, 2 /* Peter */);


-- region [Test] Der anfragende Nutzer ist bereits in der Gruppe.

-- Wirft Fehler:
-- "Der anfragende Nutzer ist bereits in dieser Gruppe."
INSERT INTO GruppenAnfrage (GRUPPE_ID, STUDENT_ID)
VALUES (1, 1);

-- endregion


-- region [Test] Eine neue Gruppenanfrage muss unbestätigt sein.

-- Wirft Fehler:
-- "Eine neue Gruppenanfrage muss unbestätigt sein."
INSERT INTO GruppenAnfrage (GRUPPE_ID, STUDENT_ID, BESTAETIGT)
VALUES (1, 3, '1');

-- endregion


-- region [Test] Nur die Nachricht einer Anfrage oder deren Status kann bearbeitet werden.

-- Wirft Fehler:
-- "Nur die Nachricht einer Anfrage oder deren Status kann bearbeitet werden."
UPDATE GruppenAnfrage ga
SET ga.student_id = 3
WHERE ga.GRUPPE_ID = 1 AND ga.student_id = 2;

-- endregion


DELETE FROM Gruppe_Student;
DELETE FROM GruppenAnfrage;
DELETE FROM Gruppe;
DELETE FROM Student;
DELETE FROM Modul;
DELETE FROM Studiengang;
DELETE FROM Fakultaet;

-- endregion [Test-Gruppe] Trigger GruppenAnfrage


-- region [Test-Gruppe] Trigger GruppeBeitritt

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

COMMIT;


-- region [Test] Beitritt nur bei bestätigter Anfrage möglich.

INSERT INTO Gruppe_Student (GRUPPE_ID, STUDENT_ID, BEITRITTSDATUM)
SELECT 2, 2, SYSDATE FROM dual; -- funktionert nicht da bestätigte Anfrage fehlt

-- endregion


INSERT INTO GruppenAnfrage (GRUPPE_ID, STUDENT_ID, DATUM)
SELECT 2, 2, SYSDATE FROM dual;

UPDATE GruppenAnfrage SET bestaetigt = '1'
WHERE gruppe_id = 2 AND student_id = 2;


-- region [Test] Beitritt bei bestätigter Anfrage möglich.

INSERT INTO Gruppe_Student (GRUPPE_ID, STUDENT_ID, BEITRITTSDATUM)
SELECT 2, 2, SYSDATE FROM dual; -- Funktioniert nun.

-- endregion


UPDATE Gruppe SET deadline = SYSDATE - 1 WHERE id = 2;


-- region [Test] Beitritt nur vor Deadline möglich.

INSERT INTO Gruppe_Student (GRUPPE_ID, STUDENT_ID, BEITRITTSDATUM)
SELECT 2, 2, SYSDATE FROM dual; -- deadline liegt ein 1 tag zurück

-- endregion


UPDATE Gruppe SET betretbar = '1' WHERE id = 3;
UPDATE Gruppe SET limit = 2 WHERE id = 3;


-- region [Test] Insert nur möglich wenn Limit an Mitgliedern nicht überschritten wird.

INSERT INTO Gruppe_Student (GRUPPE_ID, STUDENT_ID, BEITRITTSDATUM)
SELECT 3, 1, SYSDATE FROM dual UNION
SELECT 3, 3, SYSDATE FROM dual; -- limit um 1 überschritten

-- endregion


DELETE FROM GruppenAnfrage;
DELETE FROM Gruppe_Student;
DELETE FROM Gruppe;
DELETE FROM Student;
DELETE FROM Modul;
DELETE FROM Studiengang;
DELETE FROM Fakultaet;

-- endregion


-- region [Test-Gruppe] Trigger GruppeVerlassen

INSERT INTO Fakultaet (ID, NAME, STANDORT)
VALUES (1, 'Informatik', 'Gummersbach');

INSERT INTO Studiengang (ID, NAME, FAKULTAET_ID, ABSCHLUSS)
VALUES (1, 'Informatik', 1, 'BSC.INF');

INSERT INTO Modul (ID, NAME, DOZENT, SEMESTER)
VALUES (1, 'Mathematik 1', 'Wolfgang Konen', 1);

COMMIT;


-- region [Test] Nächsten Teilnehmer zum Gruppenleiter ernennen.

INSERT INTO Student (ID, NAME, SMAIL_ADRESSE, PASSWORT_HASH,
                     PROFIL_BESCHREIBUNG, PROFIL_BILD, STUDIENGANG_ID, SEMESTER)
SELECT 1, 'Frank', 'frank@th-koeln.de', 'h', 'Ich mag Informatik.',              NULL, 1, 1 FROM dual UNION
SELECT 2, 'Peter', 'peter@th-koeln.de', 'h', 'Ich bin Technologie-begeistert.',  NULL, 1, 1 FROM dual UNION
SELECT 3, 'Hans',   'hans@th-koeln.de', 'h', 'Tortillas sind meine Spezialität', NULL, 1, 1 FROM dual;

INSERT INTO Gruppe (ID, MODUL_ID, ERSTELLER_ID, NAME, BETRETBAR)
VALUES (1, 1, 1 /* Frank */, 'Mathe-Boyz #2', '1');

INSERT INTO Gruppe_Student (GRUPPE_ID, STUDENT_ID, BEITRITTSDATUM)
SELECT 1, 2 /* Peter */, TO_DATE('17.05.2020', 'dd.mm.yyyy') FROM dual UNION
SELECT 1, 3 /* Hans  */, TO_DATE('18.05.2020', 'dd.mm.yyyy') FROM dual;

/* [Vorher]
    GRUPPE         TEILNEHMER
    Mathe-Boyz #2  Frank*, Peter, Hans
*/
SELECT * FROM view_test_GruppenTeilnehmer;

DELETE FROM Gruppe_Student
WHERE gruppe_id = 1 AND student_id = 1;

/* [Nachher]
    GRUPPE         TEILNEHMER
    Mathe-Boyz #2  Peter*, Hans
*/
SELECT * FROM view_test_GruppenTeilnehmer;

ROLLBACK;

-- endregion


-- region [Test] Account aus Gruppen löschen welchen dieser beigetreten ist.

INSERT INTO Student (ID, NAME, SMAIL_ADRESSE, PASSWORT_HASH,
                     PROFIL_BESCHREIBUNG, PROFIL_BILD, STUDIENGANG_ID, SEMESTER)
SELECT 1, 'Frank', 'frank@th-koeln.de', 'h', 'Ich mag Informatik.',              NULL, 1, 1 FROM dual UNION
SELECT 2, 'Peter', 'peter@th-koeln.de', 'h', 'Ich bin Technologie-begeistert.',  NULL, 1, 1 FROM dual;

INSERT INTO Gruppe (ID, MODUL_ID, ERSTELLER_ID, NAME, BETRETBAR)
VALUES (3, 1, 2 /* Peter */, 'Math Rivals', '1');

INSERT INTO Gruppe_Student (GRUPPE_ID, STUDENT_ID, BEITRITTSDATUM)
VALUES (3, 1 /* Frank */, SYSDATE);

/* [Vorher]
    GRUPPE         TEILNEHMER
    Math Rivals    Peter*, Frank
*/
SELECT * FROM view_test_GruppenTeilnehmer;

DELETE FROM Gruppe_Student
WHERE gruppe_id = 3 AND student_id = 1;

/* [Nachher]
    GRUPPE         TEILNEHMER
    Math Rivals    Peter*
*/
SELECT * FROM view_test_GruppenTeilnehmer;

ROLLBACK;

-- endregion


DELETE FROM Modul;
DELETE FROM Studiengang;
DELETE FROM Fakultaet;

-- endregion [Test-Gruppe] Account zurücksetzen


-- region [Test-Gruppe] Lerngruppen ausgeben


-- region [Test] Gesuchtes Modul existiert nicht

-- [1] Gibt auf der *Konsole* aus:
-- "Dieses Modul existiert nicht."
CALL LerngruppenAusgeben(1);

-- endregion


-- region [Test] Keine Lerngruppe für Modul gefunden

INSERT INTO Modul (ID, NAME, DOZENT, SEMESTER)
VALUES (1, 'Mathematik 1', 'Wolfgang Konen', 1);

-- [2] Gibt auf der *Konsole* aus:
-- "Keine Lerngruppen gefunden!"
CALL LerngruppenAusgeben(1);

DELETE FROM Modul;

-- endregion


-- region [Test] Ausgabe gefundener Lerngruppen

INSERT INTO Fakultaet (ID, NAME, STANDORT)
VALUES (1, 'Informatik', 'Gummersbach');

INSERT INTO Studiengang (ID, NAME, FAKULTAET_ID, ABSCHLUSS)
VALUES (1, 'Informatik', 1, 'BSC.INF');

INSERT INTO Modul (ID, NAME, DOZENT, SEMESTER)
VALUES (1, 'Mathematik 1', 'Wolfgang Konen', 1);

INSERT INTO Student (ID, NAME, SMAIL_ADRESSE, PASSWORT_HASH,
                     PROFIL_BESCHREIBUNG, PROFIL_BILD, STUDIENGANG_ID, SEMESTER)
VALUES (1, 'Frank', 'frank@th-koeln.de', 'h', 'Ich mag Informatik.', NULL, 1, 1);

INSERT INTO Gruppe (ID, MODUL_ID, ERSTELLER_ID, NAME, BETRETBAR)
SELECT 1, 1, 1 /* Frank */, 'Mathe-Boyz',    '1' FROM dual UNION
SELECT 2, 1, 1 /* Frank */, 'Mathe-Boyz #2', '1' FROM dual;

-- [3] Gibt auf der *Konsole* aus:
-- Gruppenname=Mathe-Boyz,Mitgliederanzahl=0,Ersteller=1,Deadline=NULL
-- Gruppenname=Mathe-Boyz #2,Mitgliederanzahl=0,Ersteller=1,Deadline=NULL
CALL LerngruppenAusgeben(1);

DELETE FROM Gruppe_Student;
DELETE FROM Gruppe;
DELETE FROM Student;
DELETE FROM Modul;
DELETE FROM Studiengang;
DELETE FROM Fakultaet;

-- endregion


-- endregion


-- region [Test-Gruppe] Prozedur LetzterBeitragVonGruppe

INSERT INTO fakultaet values(1,'Fakultaet InfoING', 'Gummersbach');
INSERT INTO fakultaet values(2,'Fakultaet fuer Fahrzeugsysteme und Produktion', 'Koeln');
INSERT INTO fakultaet values(3,' Fakultaet fuer Architektur', 'Koeln');

INSERT INTO studiengang values(1, 'MASCHINENBAU',1, 'BSC.INF');
INSERT INTO studiengang values(2,'INFORMATIK', 2, 'BSC.ING');
INSERT INTO studiengang values(3,'ELEKTROTECHNIK', 3, 'BSC.ING');

INSERT INTO modul values(1,  'INFORMATIK','Koenen', 1);
INSERT INTO modul values(2, 'INFORMATIK','EISENMANN',  2);
INSERT INTO modul values(3, 'Werkstoffe','Mustermann',  3);

INSERT INTO student values(1,'Tobias','help@smail.th-koeln.de',1,2,'xxxa','Lernstube',NULL,SYSDATE);
INSERT INTO student values(2,'Hermann','test@smail.th-koeln.de',2,4,'ppp','study',NULL,TO_DATE('17/12/2008', 'DD/MM/YYYY'));
INSERT INTO student values(3,'Luc','luc@smail.th-koeln.de',3,2,'lll','etude',NULL,TO_DATE('09/12/2008', 'DD/MM/YYYY'));
INSERT INTO student values(4,'Frida','bol@smail.th-koeln.de',2,4,'ppp','pass',NULL,TO_DATE('17/12/2000', 'DD/MM/YYYY'));

INSERT INTO gruppe values(1,1,3,'TEST',5,'1','1',SYSDATE,'Gummersbach');
INSERT INTO gruppe values(2,2,2,'zudy',3,'1','1',TO_DATE('17/06/2021', 'DD/MM/YYYY'),'Gummersbach');
INSERT INTO gruppe values(3,3,1,'PP',3,'1','0',TO_DATE('01/07/2021', 'DD/MM/YYYY'),'Koeln');
INSERT INTO gruppe values(4,3,1,'ALGO',2,'0','1',TO_DATE('01/06/2021', 'DD/MM/YYYY'),'Koeln');

INSERT INTO gruppenBeitrag values(1,1,2,TO_DATE('17/12/2015', 'DD/MM/YYYY'),'hello world');
INSERT INTO gruppenBeitrag values(2,2,1,TO_DATE('17/06/2020', 'DD/MM/YYYY'),'was lauft..');
INSERT INTO gruppenBeitrag values(3,1,2,TO_DATE('17/07/2020', 'DD/MM/YYYY'),'wann ist naechste ..');
INSERT INTO gruppenBeitrag values(4,3,2,TO_DATE('01/02/2019', 'DD/MM/YYYY'),'Termin wird verschoben ..');
INSERT INTO gruppenBeitrag values(5,3,2,TO_DATE('17/05/2020', 'DD/MM/YYYY'),'ich bin heute nicht dabei..');
INSERT INTO gruppenBeitrag values(6,3,2,TO_DATE('17/07/2020', 'DD/MM/YYYY'),'wann ist naechste ..');


-- CREATE view comment zum Beispiel for Gruppe mit id = 3--------------------------------
CREATE OR REPLACE VIEW  gruppe_Comment AS
SELECT * FROM gruppenBeitrag gb where gb.gruppe_id = 3;

SELECT * FROM  gruppe_Comment;

/* Ergebnisse vorher
ID   gruppe Id		student Id		DATE		COMMENT
24		3			2				01.02.19	Termin wird verschoben !
23		3			2				17.05.20	ich bin heute nicht dabei !
21		3			2				17.07.20	wann ist naechste ..
..		..			.				..			...
..		..			.				..			..
  */


/*----  mit dem PROCEDURE  LetzterBeitragVonGruppe(gruppe ID) lässt sich das
letze beitrag von einer gruppe  ausgeben-----
*/

CALL LetzterBeitragVonGruppe(3);

/*Ergebnis naher

Deine Gruppe ist sehr aktiv und hier ist das letze Beitrag
DATUM    GruppeName    Nachricht
17.07.20    PP    wann ist naechste ..

*/

CALL LetzterBeitragVonGruppe(4);

/*Ergebnis naher

hier hat noch niemand gescrieben, daher ist letzte nachricht über beitritt vom ersteller.

Deine Gruppe ist sehr aktiv und hier ist das letze Beitrag
DATUM    GruppeName    Nachricht
24.05.20    ALGO    Tobias ist der Gruppe beigetreten.

*/

DELETE FROM gruppenBeitrag;
DELETE FROM gruppe_student;
DELETE FROM gruppe;
DELETE FROM student;
DELETE FROM modul;
DELETE FROM studiengang;
DELETE FROM fakultaet;

-- endregion [Test-Gruppe]


-- region [Test-Gruppe] Prozedure INTEAD OF VIEW testen

INSERT INTO fakultaet values(1,'Fakultaet InfoING', 'Gummersbach');
INSERT INTO fakultaet values(2,'Fakultaet fuer Fahrzeugsysteme und Produktion', 'Koeln');
INSERT INTO fakultaet values(3,' Fakultaet fuer Architektur', 'Koeln');

INSERT INTO studiengang values(1, 'MASCHINENBAU',1, 'BSC.INF');
INSERT INTO studiengang values(2,'INFORMATIK', 2, 'BSC.ING');
INSERT INTO studiengang values(3,'ELEKTROTECHNIK', 3, 'BSC.ING');

INSERT INTO modul values(1,  'INFORMATIK','Koenen', 1);
INSERT INTO modul values(2, 'INFORMATIK','EISENMANN',  2);
INSERT INTO modul values(3, 'Werkstoffe','Mustermann',  3);

INSERT INTO student values(1,'Tobias','help@smail.th-koeln.de',1,2,'xxxa','Lernstube',NULL,SYSDATE);
INSERT INTO student values(2,'Hermann','test@smail.th-koeln.de',2,4,'ppp','study',NULL,TO_DATE('17/12/2008', 'DD/MM/YYYY'));
INSERT INTO student values(3,'Luc','luc@smail.th-koeln.de',3,2,'lll','etude',NULL,TO_DATE('09/12/2008', 'DD/MM/YYYY'));
INSERT INTO student values(4,'Frida','bol@smail.th-koeln.de',2,4,'ppp','pass',NULL,TO_DATE('17/12/2000', 'DD/MM/YYYY'));

INSERT INTO gruppe values(1,1,3,'TEST',5,'1','1',SYSDATE,'Gummersbach');
INSERT INTO gruppe values(2,2,2,'zudy',3,'1','1',TO_DATE('17/06/2021', 'DD/MM/YYYY'),'Gummersbach');
INSERT INTO gruppe values(3,3,1,'PP',3,'1','0',TO_DATE('01/07/2021', 'DD/MM/YYYY'),'Koeln');
INSERT INTO gruppe values(4,3,1,'ALGO',2,'0','1',TO_DATE('01/06/2021', 'DD/MM/YYYY'),'Koeln');

INSERT INTO gruppenBeitrag values(1,1,2,TO_DATE('17/12/2015', 'DD/MM/YYYY'),'hello world');
INSERT INTO gruppenBeitrag values(2,2,1,TO_DATE('17/06/2020', 'DD/MM/YYYY'),'was lauft..');
INSERT INTO gruppenBeitrag values(3,1,2,TO_DATE('17/07/2020', 'DD/MM/YYYY'),'wann ist naechste ..');
INSERT INTO gruppenBeitrag values(4,3,2,TO_DATE('01/02/2019', 'DD/MM/YYYY'),'Termin wird verschoben ..');
INSERT INTO gruppenBeitrag values(5,3,2,TO_DATE('17/05/2020', 'DD/MM/YYYY'),'ich bin heute nicht dabei..');
INSERT INTO gruppenBeitrag values(6,3,2,TO_DATE('17/07/2020', 'DD/MM/YYYY'),'wann ist naechste ..');


/*Eine view von dem studenten mit ID = 2 als Beispiel erstellen */

SELECT * FROM studentNachricht WHERE  student_id = 2;
/*
 ID         	Nachricht					Gruppe_id		student_id			Name			ABSCHLUSS
(Beitrag_id)
21				wann ist naechste ..		    3				2				Hermann			BSC.ING
23				ich bin heute nicht dabei !	    3				2				Hermann			BSC.ING
24				Termin wird verschoben !	    3				2				Hermann			BSC.ING
1				hello world					    1				2				Hermann			BSC.ING
3				wann ist naechste ..		    1				2				Hermann			BSC.ING

*/

/* INSTEAD OF VIEW deactivieren  damit der Test fehl schlaegt*/

ALTER TRIGGER BeitragVonStudent DISABLE;

---Test functioniert nicht wenn man zum Beispiel anhand der view eine bestimtes beitrag von dem studenten ändern möchtet

update studentNachricht set nachricht = 'findet nicht mehr statt' where id = 1 ;

/* Fehlermeldung
SQL Error: ORA-01779: cannot modify a column which maps to a non key-preserved table
01779. 00000 -  "cannot modify a column which maps to a non key-preserved table"
*Cause:    An attempt was made to insert or update columns of a join view which
           map to a non-key-preserved table.
*Action:   Modify the underlying base tables directly.

*/

/* INSTEAD OF VIEW JETZT activieren  t*/

ALTER TRIGGER BeitragVonStudent ENABLE;

/* der test wird wiederholt und klappt jetz */

/* ergebnis Voher

 ID         	Nachricht					Gruppe_id		student_id			Name			ABSCHLUSS
(Beitrag_id)
1	            hello world	                1	            2	                Hermann	        BSC.ING
3	            wann ist naechste ..	    1	            2	                Hermann	        BSC.ING
4	            Termin wird verschoben ..	3	            2	                Hermann	        BSC.ING
5	            ich bin heute nicht dabei..	3	            2	                Hermann	        BSC.ING
6	            wann ist naechste ..	    3	            2	                Hermann	        BSC.ING


*/

update studentNachricht set nachricht = 'findet nicht mehr statt' where id = 1 ; --- Beitrag mit ID 1 wird angepasst

SELECT * FROM studentNachricht WHERE  student_id = 2;

/* Ergebnis naher in der view (Nachricht mit ID =24 wird angepasst)

 ID         	Nachricht					Gruppe_id		student_id			Name			ABSCHLUSS
(Beitrag_id)
1	            findet nicht mehr statt	    1	            2	                Hermann	        BSC.ING
3	            wann ist naechste ..	    1	            2	                Hermann	        BSC.ING
4	            Termin wird verschoben ..	3	            2	                Hermann	        BSC.ING
5	            ich bin heute nicht dabei..	3	            2	                Hermann	        BSC.ING
6	            wann ist naechste ..	    3	            2	                Hermann	        BSC.ING

*/


DELETE FROM gruppenBeitrag;
DELETE FROM gruppe_student;
DELETE FROM gruppe;
DELETE FROM student;
DELETE FROM modul;
DELETE FROM studiengang;
DELETE FROM fakultaet;

-- endregion

