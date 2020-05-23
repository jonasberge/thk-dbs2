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
1	    1	        2	        2015-12-17	            hello world	
2	    2	        1	        2020-06-17	            was lauft..	
3	    1	        2	        2020-07-17	            wann ist naechste ..	
4	    3	        2	        2019-02-01	            Termin wird ..	
5	    3	        2	        2020-05-17	            ich bin heute nicht dabei..	
6	    3	        2	        2020-07-17	            wann ist naechste ..	
..		..			.				..			        ...	
..		..			.				..			        ..	
  */
/*----  mit dem PROCEDURE  lastdatecomment(gruppe ID) lässt sich das 
letze beitrag von einer gruppe  ausgeben-----
*/
CALL lastdateComment(3);

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
3	            wann ist naechste ..	          1	                    2	        Hermann	        BSC.ING	
4	            Termin wird ..	                  3	                    2	        Hermann	        BSC.ING	
5	            ich bin heute nicht dabei..	      3	                    2	        Hermann	        BSC.ING	
6	            wann ist naechste ..	          3	                    2	         Hermann	    BSC.ING	

*/


