import functools

from flask import (
    Blueprint, flash, g, redirect, render_template, request, session, url_for
)
from werkzeug.security import check_password_hash, generate_password_hash

from flask_app.db import get_db
from flask_app.cache import cache
from flask_app.forms import LoginForm
from flask_login import login_required, logout_user, current_user, login_user

#Login manager will be imported.

import hashlib

bp = Blueprint('login', __name__)


@bp.route('/login', methods=('GET', 'POST'))
def login():
    if current_user.is_authenticated:
        return redirect(url_for('index'))

    form = LoginForm()
    #Validate login attempt
    if form.validate_on_submit():

        #user = auth(form.email.data, hashlib.md5(form.password.data.encode()).hexdigest())

        #if user is not None:
         #   session['student_id'] = user[0]
         #   session['student_name'] = user[1]

         #   flash('Login requested for user {}, stay_logged_in={}'.format(
          #      user[1], form.stay_logged_in.data))
        # Auth will be added here.
        user = User.query.filter_by(email=form.email.data).first()
        if user and user.check_password(password=form.password.data):
            login_user(user)
            next_page = request.args.get('next')
            return redirect(next_page or url_for('index'))
        flash('Ungültige Benutzername und Passwort Kombination')
        return redirect(url_for('auth_bp.login'))
    return render_template('login2.html', title='Anmelden', form=form)


def auth(email, password):
    db = get_db()

    # add_test_user()

    with db.cursor() as cursor:
        cursor.execute("""
            SELECT id, name FROM Student
            WHERE smail_adresse = :mail AND passwort_hash = :pw
        """, [email, password])

        return cursor.fetchone()


@bp.route('/profile')
def profile():
    if not user:
        return redirect(url_for('login'))

    return render_template('profile.html')


@bp.route('/', methods=['GET'])
@login_required
def dashboard():
    return render_template('index.html')


@bp.route('/logout')
def unauthorized():
    # Redirect unauthorized users to Login page.
    flash('Sie müssen angemeldet sein, um diese Seite anzuzeigen.')
    return redirect(url_for('login'))


@login_manager.user_loader
def load_user(user_id):
    # Check if user is logged-in upon page load."""
    if user_id is not None:
        return User.query.get(user_id)
    return None


def logout():
    session.clear()
    print(session.get('logged_in'))
    return redirect('/')
