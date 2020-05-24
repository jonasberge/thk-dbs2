CREATE OR REPLACE TYPE Eindeutige_Kennung AS OBJECT
(
    kennung_id      INTEGER,
    kennung VARCHAR2(40)
)
    NOT INSTANTIABLE
    NOT FINAL;
/

CREATE OR REPLACE TYPE GruppenEinladung_typ
    UNDER Eindeutige_Kennung
(
    gruppe_id    INT,
    ersteller_id INT,
    gueltig_bis  DATE
);
/

DROP TABLE t_GruppenEinladung;
CREATE TABLE t_GruppenEinladung OF GruppenEinladung_typ (
    kennung_id PRIMARY KEY,
    kennung UNIQUE,
    gruppe_id NOT NULL,
    FOREIGN KEY (gruppe_id)
        REFERENCES Gruppe (id),
    FOREIGN KEY (ersteller_id)
        REFERENCES Student (id)
)
OBJECT IDENTIFIER IS SYSTEM GENERATED;


INSERT INTO t_GruppenEinladung (Kennung_id,Kennung, gruppe_id,ersteller_id,gueltig_bis) VALUES (1,'TEST',1,1, SYSDATE);