import functools
import cx_Oracle
import os

from flask import (
    Blueprint, flash, g, redirect, render_template, request, session, url_for
)
from werkzeug.security import check_password_hash, generate_password_hash

from flask_app.db import get_db
from flask_app.cache import cache
from flask_app.forms import SearchForm

bp = Blueprint('search', __name__)

@bp.route('/search')
def search():
    form = SearchForm()

    form.module_id.data = request.args.get('module_id')
    form.q.data = request.args.get('q')

    groups = get_groups()

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

@cache.cached(timeout=60*60)
def get_groups():
    db = get_db()

    with db.cursor() as cursor:
        cursor.execute("""
            SELECT id, (SELECT name FROM Modul WHERE modul_id = Modul.id) module, Gruppe.name, Gruppe.limit, oeffentlich, betretbar, deadline, ort
            FROM Gruppe
        """)
        cursor.rowfactory = lambda *args: dict(zip([d[0] for d in cursor.description], args))
        return cursor.fetchall()

def run_sql_script():
    db = get_db()
    f = open(os.path.join(os.path.dirname(__file__), 'script.sql'))
    full_sql = f.read()
    sql_commands = full_sql.split(';')

    try:
       with db.cursor() as cursor:
            for sql_command in sql_commands:
                print(sql_command)
                cursor.execute(sql_command)

            db.commit()
    except cx_Oracle.Error as error:
        print('Error occurred:')
        print(error)
