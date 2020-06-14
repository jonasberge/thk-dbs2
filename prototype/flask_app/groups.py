import functools

from flask import (
    Blueprint, flash, g, redirect, render_template, request, session, url_for
)
from werkzeug.security import check_password_hash, generate_password_hash

from flask_app.db import get_db
from flask_app.cache import cache
from flask_app.forms import LoginForm, SearchForm

bp = Blueprint('groups', __name__)

@bp.route('/')
def index():
    if session.get('student_id') is None:
        return redirect('/login')

    recent_messages = get_related_group_messages()
    groups = get_my_groups()

    return render_template('index.html', Groups_len=len(groups), Groups=groups, Messages_len=len(recent_messages), Messages=recent_messages)


@bp.route('/search')
def search():
    form = SearchForm()
    form.module_id.choices = [(-1, 'Alle Module')] + get_all_modules()

    module = request.args.get('module_id', '-1')
    q = request.args.get('q', '')

    form.module_id.default = module
    form.process()
    form.q.data = q

    groups = get_groups(module, q)

    return render_template('search.html', title='Suche', form=form, len=len(groups), Groups=groups)

@cache.cached(timeout=60*60)
def get_all_modules():
    db = get_db()

    with db.cursor() as cursor:
        cursor.execute("""
            SELECT id, name
            FROM Modul
        """)
        return [ (mid, name) for mid, name in cursor ]

def get_related_group_messages():
    db = get_db()

    with db.cursor() as cursor:

        cursor.execute("""
                SELECT  id,
                        gruppe_id,
                        (SELECT name FROM Gruppe WHERE id = gruppe_id) gruppe,
                        (SELECT name FROM Modul WHERE id = (SELECT modul_id FROM Gruppe WHERE id = gruppe_id)) modul,
                        student_id as ersteller_id,
                        (SELECT name FROM Student WHERE id = gb.student_id) ersteller,
                        nachricht,
                        datum,
                        typ
                FROM GruppenBeitrag gb
                WHERE gruppe_id IN (SELECT gruppe_id FROM Gruppe_Student WHERE student_id = :student)
                ORDER BY datum DESC
                FETCH NEXT 5 ROWS ONLY
            """, student = session.get('student_id'))

        cursor.rowfactory = lambda *args: dict(zip([d[0] for d in cursor.description], args))
        return cursor.fetchall()

def get_my_groups():
    db = get_db()

    with db.cursor() as cursor:

        cursor.execute("""
                SELECT  id,
                        modul_id,
                        (SELECT name FROM Modul WHERE modul_id = Modul.id) modul,
                        g.name,
                        (SELECT count(ersteller_id) FROM Gruppe WHERE id = g.id AND ersteller_id = :student) ist_ersteller,
                        (SELECT count(student_id) FROM Gruppe_Student WHERE gruppe_id = g.id AND student_id = :student) ist_mitglied,
                        (SELECT count(student_id) FROM Gruppe_Student WHERE gruppe_id = g.id) mitglieder,
                        g.limit,
                        oeffentlich,
                        betretbar,
                        deadline,
                        ort
                FROM Gruppe g
                WHERE :student IN (SELECT student_id FROM Gruppe_Student WHERE gruppe_id = g.id)
                ORDER BY ist_mitglied, deadline DESC
            """, student = session.get('student_id'))

        cursor.rowfactory = lambda *args: dict(zip([d[0] for d in cursor.description], args))
        return cursor.fetchall()

def get_groups(module, description):
    db = get_db()

    with db.cursor() as cursor:

        cursor.execute("""
                SELECT  id,
                        modul_id,
                        (SELECT name FROM Modul WHERE modul_id = Modul.id) modul,
                        g.name,
                        (SELECT count(ersteller_id) FROM Gruppe WHERE id = g.id AND ersteller_id = :student) ist_ersteller,
                        (SELECT count(student_id) FROM Gruppe_Student WHERE gruppe_id = g.id AND student_id = :student) ist_mitglied,
                        (SELECT count(student_id) FROM Gruppe_Student WHERE gruppe_id = g.id) mitglieder,
                        g.limit,
                        oeffentlich,
                        betretbar,
                        deadline,
                        ort
                FROM Gruppe g
                WHERE   (:modul = -1 OR modul_id = :modul) AND
                        (g.name LIKE :bezeichnung OR ort LIKE :bezeichnung)
                ORDER BY ist_mitglied, deadline DESC
            """, student = session.get('student_id'), modul = module, bezeichnung = "%" + description + "%")

        cursor.rowfactory = lambda *args: dict(zip([d[0] for d in cursor.description], args))
        return cursor.fetchall()

