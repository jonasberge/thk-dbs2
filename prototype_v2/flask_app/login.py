import functools

from flask import (
    Blueprint, flash, g, redirect, render_template, request, session, url_for
)
from werkzeug.security import check_password_hash, generate_password_hash
from flask_login import login_user, logout_user, current_user, login_required, LoginManager, UserMixin
from flask_app.db import get_db
from flask_app.cache import cache
from flask_app.forms import LoginForm
from flask_app.forms import EditProfileForm

import hashlib

bp = Blueprint('login', __name__)

login_manager = LoginManager()


@login_manager.user_loader
def load_user(user_id):
    return User.get(int(user_id))


class User(UserMixin):
    def __init__(self, uid, name, smail_adresse, passwort_hash, profil_beschreibung, profil_bild, geburtsdatum):
        self.id = uid
        self.name = name
        self.smail_adresse = smail_adresse
        self.passwort_hash = passwort_hash
        self.profil_beschreibung = profil_beschreibung
        self.profil_bild = profil_bild
        self.geburtsdatum = geburtsdatum

    @classmethod
    def get(cls, user_id):
        db = get_db()

        with db.cursor() as cursor:
            cursor.execute("""
                SELECT id, name, smail_adresse, passwort_hash, profil_beschreibung, profil_bild, geburtsdatum
                  FROM Student
                 WHERE id = :user_id
            """, [ user_id ])

            fetched = cursor.fetchone()
            if not fetched:
                return None

        return cls(*fetched)

    @classmethod
    def get_by_mail(cls, smail_adresse):
        db = get_db()

        with db.cursor() as cursor:
            cursor.execute("""
                SELECT id, name, smail_adresse, passwort_hash, profil_beschreibung, profil_bild, geburtsdatum
                  FROM Student
                 WHERE LOWER(smail_adresse) = LOWER(:smail_adresse)
            """, [ smail_adresse ])

            fetched = cursor.fetchone()
            if not fetched:
                return None

        return cls(*fetched)

    def save(self):
        db = get_db()

        with db.cursor() as cursor:
            print('mydict', self.__dict__)
            cursor.execute("""
                UPDATE Student
                SET name = :name,
                    smail_adresse = :smail_adresse,
                    passwort_hash = :passwort_hash,
                    profil_beschreibung = :profil_beschreibung,
                    profil_bild = :profil_bild,
                    geburtsdatum = :geburtsdatum
                WHERE id = :id
            """, self.__dict__)

            db.commit()

            return cursor.rowcount != 0

    def check_password(self, password):
        return self.passwort_hash == hash_password(password)


def hash_password(password):
    return hashlib.md5(password).hexdigest()


@bp.route('/login', methods=('GET', 'POST'))
def login():
    form = LoginForm()
    if form.validate_on_submit():
        user = User.get_by_mail(form.email.data)
        if user is None or not user.check_password(form.password.data.encode()):
            flash('Invalid mail address or password')
            return redirect(url_for('login'))
        login_user(user, remember=form.stay_logged_in.data)
        next_page = request.args.get('next')
        if not next_page or url_parse(next_page).netloc != '':
            next_page = url_for('groups.index')
        return redirect(next_page)
    return render_template('login.html', title='Anmelden', form=form)


@bp.route('/profile')
@login_required
def profile():
    return render_template('user.html', user=current_user)


def auth(email, password):
    db = get_db()

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
        # current_user.smail_adresse = form.email.data
        current_user.profil_beschreibung = form.about_me.data
        print('->', current_user.profil_beschreibung)
        if current_user.save():
            flash('Your changes have been saved.')
        else:
            flash('An unknown error occurred')
        return redirect(url_for('login.profile'))
    elif request.method == 'GET':
        # form.email.data = current_user.smail_adresse
        form.about_me.data = current_user.profil_beschreibung
    return render_template('edit_profile.html', title='Profile Bearbeiten',
                           form=form)


@bp.route('/logout')
def logout():
    logout_user()
    return redirect('/')
