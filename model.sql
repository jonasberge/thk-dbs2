DROP TABLE Gruppe CASCADE CONSTRAINTS;
DROP TABLE Gruppeneinladung CASCADE CONSTRAINTS;
DROP TABLE Gruppenbeitrag CASCADE CONSTRAINTS;
DROP TABLE Gruppe_Dienslink CASCADE CONSTRAINTS;
DROP TABLE Beitrittsanfrage CASCADE CONSTRAINTS;
DROP TABLE Gruppenzugehörigkeit CASCADE CONSTRAINTS;
DROP TABLE Student CASCADE CONSTRAINTS;
DROP TABLE Modul CASCADE CONSTRAINTS;
DROP TABLE Studiengang CASCADE CONSTRAINTS;
DROP TABLE Fakultat CASCADE CONSTRAINTS;

CREATE TABLE Fakultat (
  FakultatID Integer PRIMARY KEY,
  Name VARCHAR(45) NOT NULL,
  Standort VARCHAR(45) NOT NULL
);

CREATE TABLE Studiengang (
  StudiengangID INTEGER PRIMARY KEY,
  Name VARCHAR(45) NOT NULL,
  FakultatID INTEGER,
  Abcshluss VARCHAR(45),
  CONSTRAINT fk_fakultat FOREIGN KEY (FakultatID)
      REFERENCES Fakultat(FakultatID) 		
);

CREATE TABLE Student (
  StudentID INTEGER PRIMARY KEY,
  S_Mail_Adresse VARCHAR(45) NOT NULL,
  Password VARCHAR(45) NOT NULL,
  Name VARCHAR(45) NOT NULL,
  StudiengangID INTEGER,
  Profilbeschreibung VARCHAR(45),
  Profilbild VARCHAR(45),
  CONSTRAINT fk_Studiengang FOREIGN KEY (StudiengangID)
      REFERENCES Studiengang(StudiengangID)
);

CREATE TABLE Modul (
  ModulID INTEGER PRIMARY KEY,
  Name VARCHAR(45) NOT NULL,
  Dozent VARCHAR(45),
  StudiengangID INTEGER,
  Semester INTEGER,
  CONSTRAINT fk_StudiengangModul FOREIGN KEY (StudiengangID)
      REFERENCES Studiengang(StudiengangID)
);

CREATE TABLE Gruppe (
  GruppeID INTEGER PRIMARY KEY,
  Name VARCHAR(45) NOT NULL ,
  Max_Mitglieder INTEGER,
  Sichtbar VARCHAR(45),
  Ort VARCHAR(45),
  Zeit DATE,
  Beitrittsdeadline DATE,
  ModulID INTEGER,
  StudentID INTEGER,
  CONSTRAINT fk_modulGruppe FOREIGN KEY (ModulID)
      REFERENCES Modul(ModulID),
  CONSTRAINT fk_StudentGruppe FOREIGN KEY (StudentID)
      REFERENCES Student(StudentID)
);

CREATE TABLE Gruppeneinladung (
  GruppeneinladungID INTEGER PRIMARY KEY,
  StudentID INTEGER,
  GruppeID INTEGER,
  Gültig_bis DATE,
  CONSTRAINT fk_StudentGrEinl FOREIGN KEY (StudentID)
      REFERENCES Student(StudentID),
  CONSTRAINT fk_GruppeGreinl FOREIGN KEY (GruppeID)
      REFERENCES Gruppe(GruppeID)
);

CREATE TABLE Beitrittsanfrage (
  StudentID INTEGER,
  GruppeID INTEGER,
  Nachricht VARCHAR(45),
  Genehmigt DATE,
  CONSTRAINT fk_StudentBeitr FOREIGN KEY (StudentID)
      REFERENCES Student(StudentID),
  CONSTRAINT fk_GruppeBeitr FOREIGN KEY (GruppeID)
      REFERENCES Gruppe(GruppeID)
);

CREATE TABLE Gruppenzugehörigkeit (
  StudentID INTEGER,
  GruppeID INTEGER,
  CONSTRAINT fk_StudentGrzug FOREIGN KEY (StudentID)
      REFERENCES Student(StudentID),
  CONSTRAINT fk_GruppeGrzug FOREIGN KEY (GruppeID)
      REFERENCES Gruppe(GruppeID)
);

CREATE TABLE Gruppenbeitrag (
  GruppenbeitragID INTEGER PRIMARY KEY,
  StudentID INTEGER,
  GruppeID INTEGER,
  Nachricht VARCHAR(45),
  Geschrieben_am DATE,
  CONSTRAINT fk_StudentGrBeitr FOREIGN KEY (StudentID)
      REFERENCES Student(StudentID),
  CONSTRAINT fk_GruppeGrBeitr FOREIGN KEY (GruppeID)
      REFERENCES Gruppe(GruppeID)
);

CREATE TABLE Gruppe_Dienslink (
  DienstlinkID INTEGER PRIMARY KEY,
  Link VARCHAR(45),
  GruppeID INTEGER,
  CONSTRAINT fk_GruppeGrLink FOREIGN KEY (GruppeID)
      REFERENCES Gruppe(GruppeID)
);



