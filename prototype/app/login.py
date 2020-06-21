import functools

from flask import (
    Blueprint, flash, g, redirect, render_template, request, session, url_for
)
from werkzeug.security import check_password_hash, generate_password_hash
from flask_login import login_user, logout_user, current_user, login_required, LoginManager, UserMixin
from app.db import get_db
from app.cache import cache
from app.forms import LoginForm
from app.forms import EditProfileForm

import hashlib

bp = Blueprint('login', __name__)

login_manager = LoginManager()


@login_manager.user_loader
@cache.memoize(timeout=60*60)
def load_user(user_id):
    return User.get(int(user_id))


class User(UserMixin):
    def __init__(self, uid, name, smail_adresse, passwort_hash, profil_beschreibung,
                 profil_bild, geburtsdatum, studiengang_id, studiengang_name, abschluss,
                 fakultaet_id, fakultaet_name, fakultaet_standort, *args):

        self.id = uid
        self.name = name
        self.smail_adresse = smail_adresse
        self.passwort_hash = passwort_hash
        self.profil_beschreibung = profil_beschreibung
        self.profil_bild = profil_bild
        self.geburtsdatum = geburtsdatum
        self.studiengang_id = studiengang_id

        self.studiengang_name = studiengang_name
        self.abschluss = abschluss
        self.fakultaet_id = fakultaet_id
        self.fakultaet_name = fakultaet_name
        self.fakultaet_standort = fakultaet_standort

    @classmethod
    def get(cls, user_id):
        db = get_db()

        with db.cursor() as cursor:
            cursor.execute("""
                SELECT s.id, s.name, s.smail_adresse, s.passwort_hash,
                       s.profil_beschreibung, s.profil_bild, s.geburtsdatum,
                       s.studiengang_id, sg.name as studiengang_name,
                       sg.abschluss, sg.fakultaet_id, f.name as fakultaet_name,
                       f.standort as fakultaet_standort
                  FROM Student s
            INNER JOIN Studiengang sg ON s.studiengang_id = sg.id
            INNER JOIN Fakultaet f ON sg.fakultaet_id = f.id
                 WHERE s.id = :user_id
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
                SELECT s.id, s.name, s.smail_adresse, s.passwort_hash,
                       s.profil_beschreibung, s.profil_bild, s.geburtsdatum,
                       s.studiengang_id, sg.name as studiengang_name,
                       sg.fakultaet_id, sg.abschluss, f.name as fakultaet_name,
                       f.standort as fakultaet_standort
                  FROM Student s
            INNER JOIN Studiengang sg ON s.studiengang_id = sg.id
            INNER JOIN Fakultaet f ON sg.fakultaet_id = f.id
                 WHERE LOWER(s.smail_adresse) = LOWER(:smail_adresse)
            """, [ smail_adresse ])

            fetched = cursor.fetchone()
            if not fetched:
                return None

        return cls(*fetched)

    def save(self):
        db = get_db()

        with db.cursor() as cursor:
            cursor.execute("""
                UPDATE Student
                SET name = :name,
                    smail_adresse = :smail_adresse,
                    passwort_hash = :passwort_hash,
                    profil_beschreibung = :profil_beschreibung,
                    profil_bild = :profil_bild,
                    geburtsdatum = :geburtsdatum,
                    studiengang_id = :studiengang_id
                WHERE id = :id
            """, { k: self.__dict__[k] for k in [
                'id', 'name', 'smail_adresse', 'passwort_hash',
                'profil_beschreibung', 'profil_bild', 'geburtsdatum',
                'studiengang_id'
            ] })

            db.commit()

            return cursor.rowcount != 0

    def check_password(self, password):
        return self.passwort_hash == hash_password(password)


# FIXME: insecure.
def hash_password(password):
    return hashlib.md5(password).hexdigest()


@bp.route('/login', methods=('GET', 'POST'))
def login():
    form = LoginForm()
    if form.validate_on_submit():
        user = User.get_by_mail(form.email.data)
        if user is None or not user.check_password(form.password.data.encode()):
            flash('Ungültige Mail-Adresse oder Passwort', category='failure')
            return redirect(url_for('login.login'))
        login_user(user, remember=form.stay_logged_in.data)
        next_page = request.args.get('next')
        if not next_page or url_parse(next_page).netloc != '':
            next_page = url_for('groups.index')
        return redirect(next_page)
    return render_template('login.html', title='Anmelden', form=form)


@bp.route('/profile')
@login_required
def profile():
    return render_template('profile.html', user=current_user)


@bp.route('/profile/<int:user_id>')
@login_required
def other_profile(user_id):
    user = load_user(user_id)
    if not user:
        abort(404)

    return render_template('profile.html', user=user)


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


@bp.route('/profile/edit', methods=['GET', 'POST'])
@login_required
def edit_profile():
    form = EditProfileForm()
    if form.validate_on_submit():
        # current_user.smail_adresse = form.email.data
        current_user.profil_beschreibung = form.about_me.data
        if current_user.save():
            flash('Deine Änderungen wurden gespeichert.', category='success')
        else:
            flash('Ein unbekannter Fehler ist aufgetreten.', category='failure')

        # TODO: user_id=current_user.id does not work for some reason.
        cache.delete_memoized(load_user)

        return redirect(url_for('login.profile'))
    elif request.method == 'GET':
        # form.email.data = current_user.smail_adresse
        form.about_me.data = current_user.profil_beschreibung
    return render_template('profile/edit.html', title='Profile Bearbeiten',
                           user=current_user, form=form)


@bp.route('/logout')
def logout():
    logout_user()
    return redirect('/')
