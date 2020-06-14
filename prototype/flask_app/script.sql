DELETE FROM GruppenEinladung;
DELETE FROM GruppenAnfrage;
DELETE FROM Gruppe_Student;
DELETE FROM GruppenBeitrag;
DELETE FROM GruppenDienstlink;
DELETE FROM Gruppe;
DELETE FROM StudentWiederherstellung;
DELETE FROM StudentVerifizierung;
DELETE FROM Student;
DELETE FROM Studiengang_Modul;
DELETE FROM Modul;
DELETE FROM Studiengang;
DELETE FROM Fakultaet;

INSERT INTO Fakultaet (ID, NAME, STANDORT)
VALUES (1, 'Informatik', 'Gummersbach');

INSERT INTO Studiengang (ID, NAME, FAKULTAET_ID, ABSCHLUSS)
VALUES (1, 'Informatik', 1, 'BSC.INF');

INSERT INTO Modul (ID, NAME, DOZENT, SEMESTER)
VALUES (1, 'Mathematik 1', 'Wolfgang Konen', 1);

INSERT INTO Student (ID, NAME, SMAIL_ADRESSE, PASSWORT_HASH,
                     PROFIL_BESCHREIBUNG, STUDIENGANG_ID, SEMESTER, GEBURTSDATUM)
SELECT 1, 'Frank', 'frank@th-koeln.de', 'h', 'Ich mag Informatik.', 1, 1, SYSDATE FROM dual;

INSERT INTO Gruppe (ID, MODUL_ID, ERSTELLER_ID, NAME, BETRETBAR)
VALUES (1, 1, 1, 'Mathe-Boyz', '1');
