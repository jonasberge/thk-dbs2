import functools

from flask import (
    Blueprint, flash, g, redirect, render_template, request, session, url_for
)
from werkzeug.security import check_password_hash, generate_password_hash

from flask_app.db import get_db
from flask_app.forms import LoginForm, RegisterForm


bp = Blueprint('auth', __name__, url_prefix='/auth')


@bp.route('/login', methods=('GET', 'POST'))
def login():
    form = LoginForm()

    if form.validate_on_submit():
        flash('Login requested for user {}, stay_logged_in={}'.format(
            form.email.data, form.stay_logged_in.data))

        return redirect('/')

    return render_template('auth/login.html', title='Anmelden', form=form)


# TODO: cache this. please
def get_all_courses():
    db = get_db()
    cursor = db.cursor()

    cursor.execute("""
        SELECT id, name
        FROM Studiengang
    """)

    return [ (cid, name) for cid, name in cursor ]


@bp.route('register', methods=('GET', 'POST'))
def register():
    form = RegisterForm()
    form.course_id.choices = get_all_courses()

    if form.validate_on_submit():
        flash('Register requested for user {}, stay_logged_in={}, studiengang_id={}'.format(
            form.email.data, form.stay_logged_in.data, form.course_id.data))

        return redirect('/')

    return render_template('auth/register.html', title='Registrieren', form=form)


@bp.route('/logout')
def logout():
    session.clear()
    return redirect(url_for('index'))
