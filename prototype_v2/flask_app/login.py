import functools

from flask import (
    Blueprint, flash, g, redirect, render_template, request, session, url_for
)
from werkzeug.security import check_password_hash, generate_password_hash
from flask_login import login_user, logout_user, current_user, login_required
from flask_app.db import get_db
from flask_app.cache import cache
from flask_app.forms import LoginForm
from flask_app.forms import EditProfileForm

import hashlib

bp = Blueprint('login', __name__)


@bp.route('/login', methods=('GET', 'POST'))
def login():
    form = LoginForm()
    if form.validate_on_submit():
        user = auth(form.email.data, hashlib.md5(form.password.data.encode()).hexdigest())
        if user is None or not user.check_password(form.password.data):
            flash('Invalid username or password')
            return redirect(url_for('login'))
        login_user(user, remember=form.remember_me.data)
        next_page = request.args.get('next')
        if not next_page or url_parse(next_page).netloc != '':
            next_page = url_for('index')
        return redirect(next_page)
    return render_template('login.html', title='Anmelden', form=form)


@bp.route('/profile')
@login_required
def profile():
    return render_template('user.html')


def auth(email, password):
    db = get_db()

    # add_test_user()

    with db.cursor() as cursor:
        cursor.execute("""
            SELECT id, name FROM Student
            WHERE smail_adresse = :mail AND passwort_hash = :pw
        """, [email, password])

        return cursor.fetchone()


#@bp.route('here') // fill me
#@login_required
#def dashboard():
#    return render_template('index.html')


@bp.route('/edit_profile', methods=['GET', 'POST'])
@login_required
def edit_profile():
    form = EditProfileForm()
    if form.validate_on_submit():
        current_user.email = form.email.data
        current_user.about_me = form.about_me.data  # add about me col.
        db.session.commit()
        flash('Your changes have been saved.')
        return redirect(url_for('edit_profile'))
    elif request.method == 'GET':
        form.email.data = current_user.email
        form.about_me.data = current_user.about_me
    return render_template('edit_profile.html', title='Profile Bearbeiten',
                           form=form)


@bp.route('/logout')
def logout():
    session.clear()
    print(session.get('logged_in'))
    return redirect('/')
