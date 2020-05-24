
/*****  TESTFALL 1 ***/

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

DROP VIEW view_test_AccountZuruecksetzen;

-- endregion

-- region [Test] Account zurücksetzen

-- region [setup]

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
SELECT 2, 1, SYSDATE FROM dual; -- funktionert nicht da bestätigte Anfrage fehlt

INSERT INTO GruppenAnfrage (GRUPPE_ID, STUDENT_ID, BESTAETIGT, DATUM)
SELECT 2, 1, '1', SYSDATE FROM dual;

INSERT INTO Gruppe_Student (GRUPPE_ID, STUDENT_ID, BEITRITTSDATUM)
SELECT 2, 1, SYSDATE FROM dual;

-- Beitritt nur vor Deadline möglich
UPDATE Gruppe SET deadline = SYSDATE - 1 WHERE id = 2;
INSERT INTO Gruppe_Student (GRUPPE_ID, STUDENT_ID, BEITRITTSDATUM)
SELECT 2, 2, SYSDATE FROM dual; -- deadline liegt ein 1 tag zurück

-- Insert nur möglich wenn Limit an Mitgliedern nicht überschritten wird
UPDATE Gruppe SET betretbar = '1' WHERE id = 3;
UPDATE Gruppe SET limit = 2 WHERE id = 3;
INSERT INTO Gruppe_Student (GRUPPE_ID, STUDENT_ID, BEITRITTSDATUM)
SELECT 3, 1, SYSDATE FROM dual UNION
SELECT 3, 2, SYSDATE FROM dual UNION
SELECT 3, 3, SYSDATE FROM dual; -- limit um 1 überschritten

-- region [teardown]

ROLLBACK;

-- endregion

-- endregion

-- region [Test-Gruppe] Lerngruppen ausgeben


-- region [Test] Gesuchtes Modul existiert nicht

-- Gibt auf der Konsole aus:
-- "Dieses Modul existiert nicht."
CALL LerngruppenAusgeben(1);

-- endregion


-- region [Test] Keine Lerngruppe für Modul gefunden

INSERT INTO Modul (ID, NAME, DOZENT, SEMESTER)
VALUES (1, 'Mathematik 1', 'Wolfgang Konen', 1);

-- [2] Gibt auf der Konsole aus:
-- "Keine Lerngruppen gefunden!"
CALL LerngruppenAusgeben(1);

ROLLBACK;

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

-- [2] Gibt auf der Konsole aus:
-- Gruppenname=Mathe-Boyz,Mitgliederanzahl=0,Ersteller=1,Deadline=
-- Gruppenname=Mathe-Boyz #2,Mitgliederanzahl=0,Ersteller=1,Deadline=
CALL LerngruppenAusgeben(1);

ROLLBACK;

-- endregion


-- endregion


/*****  TESTFALL 2***/

/* Prozedur letzer Beitrag  von einer gruppe anhand von der gruppe_id  ausgeben----- */

DROP VIEW gruppe_Comment;


--------------------Erstellung Fakultaet-----------------------------
INSERT INTO fakultaet values(sequence_Fakultaet.NEXTVAL,'Fakultaet InfoING', 'Gummersbach');
INSERT INTO fakultaet values(sequence_Fakultaet.NEXTVAL,'Fakultaet fuer Fahrzeugsysteme und Produktion', 'Koeln');
INSERT INTO fakultaet values(sequence_Fakultaet.NEXTVAL,' Fakultaet fuer Architektur', 'Koeln');
/*Erstellung Studiangang */

INSERT INTO studiengang values(sequence_Studiengang.NEXTVAL, 'MASCHINENBAU',1, 'BSC.INF');
INSERT INTO studiengang values(sequence_Studiengang.NEXTVAL,'INFORMATIK', 2, 'BSC.ING');
INSERT INTO studiengang values(sequence_Studiengang.NEXTVAL,'ELEKTROTECHNIK', 3, 'BSC.ING');

/*Erstellung Modulen */
INSERT INTO modul values(sequence_Modul.NEXTVAL,  'INFORMATIK','Koenen', 1);
INSERT INTO modul values(sequence_Modul.NEXTVAL, 'INFORMATIK','EISENMANN',  2);
INSERT INTO modul values(sequence_Modul.NEXTVAL, 'Werkstoffe','Mustermann',  3);

/* Erstellung Student */

INSERT INTO student values(sequence_Student.NEXTVAL,'Tobias','help@smail.th-koeln.de',1,2,'xxxa','Lernstube',NULL,SYSDATE);
INSERT INTO student values(sequence_Student.NEXTVAL,'Hermann','test@smail.th-koeln.de',2,4,'ppp','study',NULL,TO_DATE('17/12/2008', 'DD/MM/YYYY'));
INSERT INTO student values(sequence_Student.NEXTVAL,'Luc','luc@smail.th-koeln.de',3,2,'lll','etude',NULL,TO_DATE('09/12/2008', 'DD/MM/YYYY'));
INSERT INTO student values(sequence_Student.NEXTVAL,'Frida','bol@smail.th-koeln.de',2,4,'ppp','pass',NULL,TO_DATE('17/12/2000', 'DD/MM/YYYY'));

/*Erstellung Gruppe */
INSERT INTO gruppe values(sequence_Gruppe.NEXTVAL,1,3,'TEST',5,'1','1',SYSDATE,'Gummersbach');
INSERT INTO gruppe values(sequence_Gruppe.NEXTVAL,2,2,'zudy',3,'1','1',TO_DATE('17/06/2020', 'DD/MM/YYYY'),'Gummersbach');
INSERT INTO gruppe values(sequence_Gruppe.NEXTVAL,3,1,'PP',3,'1','0',TO_DATE('01/07/2020', 'DD/MM/YYYY'),'Koeln');
INSERT INTO gruppe values(sequence_Gruppe.NEXTVAL,3,1,'ALGO',2,'0','1',TO_DATE('01/06/2020', 'DD/MM/YYYY'),'Koeln');

/* Erstellung Gruppenbeitrag */

INSERT INTO gruppenBeitrag values(sequence_GruppenBeitrag.NEXTVAL,1,2,TO_DATE('17/12/2015', 'DD/MM/YYYY'),'hello world');
INSERT INTO gruppenBeitrag values(sequence_GruppenBeitrag.NEXTVAL,2,1,TO_DATE('17/06/2020', 'DD/MM/YYYY'),'was lauft..');
INSERT INTO gruppenBeitrag values(sequence_GruppenBeitrag.NEXTVAL,1,2,TO_DATE('17/07/2020', 'DD/MM/YYYY'),'wann ist naechste ..');
INSERT INTO gruppenBeitrag values(sequence_GruppenBeitrag.NEXTVAL,3,2,TO_DATE('01/02/2019', 'DD/MM/YYYY'),'Termin wird verschoben ..');
INSERT INTO gruppenBeitrag values(sequence_GruppenBeitrag.NEXTVAL,3,2,TO_DATE('17/05/2020', 'DD/MM/YYYY'),'ich bin heute nicht dabei..');
INSERT INTO gruppenBeitrag values(sequence_GruppenBeitrag.NEXTVAL,3,2,TO_DATE('17/07/2020', 'DD/MM/YYYY'),'wann ist naechste ..');

------CREATE view vomment zum Beispiel for gruppe with id = 3--------------------------------
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
ROLLBACK;


/*****  TESTFALL 3 ***/

/* Prozedure INTEAD OF VIEW testen */

--- Complexe View erstellen : alle beitragen von den Studenten mit Studiengang INFORMATIK
CREATE or replace VIEW studentNachricht AS
SELECT gb.id, gb.nachricht, gb.gruppe_id,gb.student_id, s.name, st.abschluss
from gruppenBeitrag gb , student s,  studiengang st
where gb.student_id = s.id
AND UPPER(st.name) LIKE '%INF%';

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

update studentNachricht set nachricht = 'findet nicht mehr statt' where id =24 ;

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
21				wann ist naechste ..		3					2				Hermann			BSC.ING
23				ich bin heute nicht dabei !	3					2				Hermann			BSC.ING
24				Termin wird verschoben !	3					2				Hermann			BSC.ING
1				hello world					1					2				Hermann			BSC.ING
3				wann ist naechste ..		1					2				Hermann			BSC.ING

*/

update studentNachricht set nachricht = 'findet nicht mehr statt' where id =24 ; --- Beitrag mit ID 24 wird angepasst

/* Ergebnis naher in der view (Nachricht mit ID =24 wird angepasst)


 ID         	Nachricht					Gruppe_id		student_id			Name			ABSCHLUSS
(Beitrag_id)
21				wann ist naechste ..		3					2				Hermann			BSC.ING
23				ich bin heute nicht dabei !	3					2				Hermann			BSC.ING
24				findet nicht mehr statt !	3					2				Hermann			BSC.ING ---Nachricht wurde angepasst
1				hello world					1					2				Hermann			BSC.ING
3				wann ist naechste ..		1					2				Hermann			BSC.ING

*/

/* Ergebnis naher in der Tabelle gruppen beitrag

 ID       Gruppe_id		student_id			Datum			Nachricht
21				3			2				17.07.20		wann ist naechste ..
23				3			2				17.05.20		ich bin heute nicht dabei !
24				3			2				01.02.19		findet nicht mehr statt -------Nachricht wurde in der Tabelle auch angepasst
1				1			2				17.12.15		hello world
3				1			2				17.07.20		wann ist naechste ..

*/
ROLLBACK;













