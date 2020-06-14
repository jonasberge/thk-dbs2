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
    return render_template('index.html')


@bp.route('/search')
def search():
    form = SearchForm()
    form.module_id.choices = [(-1, 'Alle Module')] + get_all_modules()

    form.module_id.default = request.args.get('module_id')
    form.process()
    form.q.data = request.args.get('q')

    groups = get_groups(request.args.get('module_id'), request.args.get('q'))

    return render_template('search.html', title='Suche', form=form, len=len(groups), Groups=groups)

def add_test_module():
    db = get_db()

    with db.cursor() as cursor:
        cursor.execute(
            """
                INSERT INTO Modul
                (id, name, dozent, semester)
                VALUES (:id, :name, :dozent, :semester)
            """,
            [1, "Mathematik 1", "Wolfgang Konen", 1]
        )

        db.commit()

def add_test_group():
    db = get_db()

    with db.cursor() as cursor:
        cursor.execute(
            """
                INSERT INTO Gruppe
                (id, modul_id, ersteller_id, name, betretbar)
                VALUES (:id, :modul, :ersteller, :name, :betretbar)
            """,
            [1, 1, 1, "Mathe Boyz", 1]
        )

        db.commit()

@cache.cached(timeout=60*60)
def get_all_modules():
    db = get_db()

    with db.cursor() as cursor:
        cursor.execute("""
            SELECT id, name
            FROM Modul
        """)
        return [ (mid, name) for mid, name in cursor ]

def get_groups(module, description):
    db = get_db()

    with db.cursor() as cursor:

        print(module)

        if module != "-1":
            cursor.execute("""
                SELECT id, (SELECT name FROM Modul WHERE modul_id = Modul.id) module, Gruppe.name, Gruppe.limit, oeffentlich, betretbar, deadline, ort
                FROM Gruppe
                WHERE modul_id = :modul AND
                    (Gruppe.name LIKE :bezeichnung OR ort LIKE :bezeichnung)
            """, modul = module, bezeichnung = "%" + description + "%")
        else:
            cursor.execute("""
                SELECT id, (SELECT name FROM Modul WHERE modul_id = Modul.id) module, Gruppe.name, Gruppe.limit, oeffentlich, betretbar, deadline, ort
                FROM Gruppe
                WHERE Gruppe.name LIKE :bezeichnung OR ort = :bezeichnung
        """, bezeichnung = "%" + description + "%")

        cursor.rowfactory = lambda *args: dict(zip([d[0] for d in cursor.description], args))
        return cursor.fetchall()

