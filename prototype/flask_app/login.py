import functools

from flask import (
    Blueprint, flash, g, redirect, render_template, request, session, url_for
)
from werkzeug.security import check_password_hash, generate_password_hash

from flask_app.db import get_db
from flask_app.cache import cache
from flask_app.forms import LoginForm

import hashlib

bp = Blueprint('login', __name__)


@bp.route('/login', methods=('GET', 'POST'))
def login():
    form = LoginForm()

    if session.get('student_id') is not None:
        # Already logged in
        return redirect('/')

    if form.validate_on_submit():
        user = auth(form.email.data, hashlib.md5(form.password.data.encode()).hexdigest())

        if user is not None:
            session['student_id'] = user[0]
            session['student_name'] = user[1]

            flash('Login requested for user {}, stay_logged_in={}'.format(
                user[1], form.stay_logged_in.data))

            return redirect('/')
        else:
            flash('User not found')

    return render_template('login.html', title='Anmelden', form=form)

def auth(email, password):
    db = get_db()

    #add_test_user()

    with db.cursor() as cursor:
        cursor.execute("""
            SELECT id, name FROM Student
            WHERE smail_adresse = :mail AND passwort_hash = :pw
        """, [email, password])

        return cursor.fetchone()

@bp.route('/logout')
def logout():
    session.clear()
    print(session.get('logged_in'))
    return redirect('/')

def add_test_user():
    db = get_db()

    with db.cursor() as cursor:
        cursor.execute(
            """
                INSERT INTO Fakultaet
                (id, name, standort)
                VALUES (:id, :name, :standort)
            """,
            [1, "Informatik", "Gummersbach"]
        )

        cursor.execute(
            """
                INSERT INTO Studiengang
                (id, name, fakultaet_id, abschluss)
                VALUES (:id, :name, :fakultaet, :abschluss)
            """,
            [1, "Informatik", 1, "BSC.INF"]
        )

        db.commit()

        cursor.execute("""
                INSERT INTO Student
                (id, name, smail_adresse, studiengang_id, semester, passwort_hash)
                VALUES (:id, :name, :mail, :studiengang, :semester, :pw)
        """, [1, 'Dieter', 'dieter@smail.th-koeln.de', 1, 1, hashlib.md5("password".encode()).hexdigest()])

        db.commit()
