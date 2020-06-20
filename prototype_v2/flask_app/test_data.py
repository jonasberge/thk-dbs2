import hashlib

import click
from flask.cli import with_appcontext
from flask_app.db import get_db

def init_app(app):
    app.cli.add_command(add_test_data)

@click.command('test-data')
@with_appcontext
def add_test_data():
    delete_tables()
    add_test_faculties()
    add_test_study_programs()
    add_test_users()
    add_test_modules()
    add_test_groups()
    add_test_group_members()
    add_test_messages()

tables_to_delete = [
    'GruppenEinladung',
    'GruppenAnfrage',
    'Gruppe_Student',
    'GruppenBeitrag',
    'GruppenDienstlink',
    'Gruppe',
    'StudentWiederherstellung',
    'StudentVerifizierung',
    'Student',
    'Studiengang_Modul',
    'Modul',
    'Studiengang',
    'Fakultaet'
]

def delete_tables():
    db = get_db()

    with db.cursor() as cursor:
        for table in tables_to_delete:
            cursor.execute(
                'DELETE FROM ' + table
            )

        db.commit()

test_fakultaet = [
    # (id, name, standort)
    [1, "Informatik", "Gummersbach"]
]

def add_test_faculties():
    db = get_db()

    with db.cursor() as cursor:
        for fakultaet in test_fakultaet:
            cursor.execute(
                """
                    INSERT INTO Fakultaet
                    (id, name, standort)
                    VALUES (:id, :name, :standort)
                """,
                fakultaet
            )

        db.commit()

test_studiengang = [
    # (id, name, fakultaet_id, abschluss)
    [1, "Informatik", 1, "BSC.INF"],
    [2, "Medieninformatik", 1, "BSC.INF"],
    [3, "Wirtschaftsinformatik", 1, "BSC.INF"]
]

def add_test_study_programs():
    db = get_db()

    with db.cursor() as cursor:
        for studiengang in test_studiengang:
            cursor.execute(
                """
                    INSERT INTO Studiengang
                    (id, name, fakultaet_id, abschluss)
                    VALUES (:id, :name, :fakultaet, :abschluss)
                """,
                studiengang
            )

        db.commit()

test_users = [
    # (id, name, smail_adresse, studiengang_id, semester, passwort_hash)
    [1, 'Dieter', 'dieter@smail.th-koeln.de', 1, 1, hashlib.md5("password".encode()).hexdigest()],
    [2, 'Jamie', 'jamie@smail.th-koeln.de', 2, 1, hashlib.md5("password".encode()).hexdigest()],
    [3, 'Frank', 'frank@smail.th-koeln.de', 3, 1, hashlib.md5("password".encode()).hexdigest()],
    [4, 'Andrej', 'andrej@smail.th-koeln.de', 2, 1, hashlib.md5("password".encode()).hexdigest()],
    [5, 'Tom', 'tom@smail.th-koeln.de', 1, 1, hashlib.md5("password".encode()).hexdigest()],
    [6, 'Nuri', 'nuri@smail.th-koeln.de', 3, 1, hashlib.md5("password".encode()).hexdigest()],
    [7, 'Vivian', 'vivian@smail.th-koeln.de', 2, 1, hashlib.md5("password".encode()).hexdigest()],
    [8, 'Hilal', 'hilal@smail.th-koeln.de', 2, 1, hashlib.md5("password".encode()).hexdigest()],
    [9, 'Tayo', 'tayo@smail.th-koeln.de', 1, 1, hashlib.md5("password".encode()).hexdigest()],
    [10, 'Yuri', 'yuri@smail.th-koeln.de', 1, 1, hashlib.md5("password".encode()).hexdigest()]
]

def add_test_users():
    db = get_db()

    with db.cursor() as cursor:
        for user in test_users:
            cursor.execute(
                """
                    INSERT INTO Student
                    (id, name, smail_adresse, studiengang_id, semester, passwort_hash)
                    VALUES (:id, :name, :mail, :studiengang, :semester, :pw)
                """,
                user
            )

        db.commit()

test_modules = [
    # (id, name, dozent, semester)
    [1, "Mathematik 1", "Konen", 1],
    [2, "BWL 1", "Engelen", 1]
]

def add_test_modules():
    db = get_db()

    with db.cursor() as cursor:
        for module in test_modules:
            cursor.execute(
                """
                    INSERT INTO Modul
                    (id, name, dozent, semester)
                    VALUES (:id, :name, :dozent, :semester)
                """,
                module
            )

        db.commit()

test_groups = [
    # (id, modul_id, ersteller_id, name, betretbar)
    [1, 1, 1, "Mathe Boyz", 1], # MA1, Gruppenersteller Dieter
    [2, 2, 8, "BWL Masterz", 1], # BWL1, Gruppenersteller Hilal
    [3, 2, 3, "Hustler Crew", 1], # BWL1, Gruppenersteller Frank
    [4, 2, 5, "Fast Money", 1], # BWL1, Gruppenersteller Tom
    [5, 1, 2, "The Calculators", 1], # MA1, Gruppenersteller Jamie
    [6, 1, 8, "Die Mathematiker", 1] # MA1, Gruppenersteller Hilal
]

def add_test_groups():
    db = get_db()

    with db.cursor() as cursor:
        for module in test_groups:
            cursor.execute(
                """
                    INSERT INTO Gruppe
                    (id, modul_id, ersteller_id, name, betretbar)
                    VALUES (:id, :modul, :ersteller, :name, :betretbar)
                """,
                module
            )

        db.commit()

test_group_members = [
    # (group_id, student_id)

    #Gruppenersteller (automatisch hinzugefügt)
    #[1, 1], # Mathe Boyz, Dieter
    #[2, 8], # BWL Masterz, Hilal
    #[3, 3], # Hustler Crew, Frank
    #[4, 5], # Fast Money, Tom
    #[5, 2], # The Calculators, Jamie
    #[6, 8], # Die Mathematiker, Hilal

    # Mitglieder
    [1, 4], # Mathe Boyz, Andrej
    [1, 3], # Mathe Boyz, Frank

    [2, 10], # BWL Masterz, Yuri
    [2, 7], # BWL Masterz, Vivian

    [3, 9], # Huster Crew, Tayo

    [6, 7], # Die Mathematiker, Vivian
]

def add_test_group_members():
    db = get_db()

    with db.cursor() as cursor:
        for member in test_group_members:
            cursor.execute(
                """
                    INSERT INTO Gruppe_Student
                    (gruppe_id, student_id, beitrittsdatum)
                    VALUES (:gruppe, :student, SYSDATE)
                """,
                member
            )

        db.commit()

import datetime
from datetime import timedelta

test_messages = [
    # (id, gruppe_id, student_id, datum, nachricht)

    [1, 1, 3, datetime.datetime.now() + timedelta(seconds=1), "Ganz schön leer hier, lass noch jemand einladen"],
    [2, 1, 4, datetime.datetime.now() + timedelta(seconds=2), "Nee, lass mal lassen"],
    [3, 1, 1, datetime.datetime.now() + timedelta(seconds=3), "Vielleicht später Frank"],

    [4, 2, 10, datetime.datetime.now() + timedelta(seconds=1), "Hi ihr beiden"],
    [5, 2, 7, datetime.datetime.now() + timedelta(seconds=2), "Hey"],
    [6, 2, 8, datetime.datetime.now() + timedelta(seconds=3), "Hi"],
    [7, 2, 10, datetime.datetime.now() + timedelta(seconds=4), "Möchten wir uns nach der nächsten Vorlesung mal irgendwo zusammensetzen?"],
    [8, 2, 7, datetime.datetime.now() + timedelta(seconds=5), "Gerne"],
    [9, 2, 8, datetime.datetime.now() + timedelta(seconds=6), "Gerne. Vielleicht in der Kaffeteria? Kann aber erst 20 Minuten nach der Vorlesung da sein."]
]

def add_test_messages():
    db = get_db()

    with db.cursor() as cursor:
        for message in test_messages:
            cursor.execute(
                """
                    INSERT INTO GruppenBeitrag
                    (id, gruppe_id, student_id, datum, nachricht)
                    VALUES (:id, :gruppe, :student, :datum, :nachricht)
                """,
                message
            )

        db.commit()
