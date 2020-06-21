import functools

from flask import (
    Blueprint, flash, g, redirect, render_template, request, session, url_for, abort
)
from werkzeug.security import check_password_hash, generate_password_hash
from flask_login import current_user

from flask_app.db import get_db
from flask_app.cache import cache
from flask_app.forms import LoginForm, SearchForm, GroupMessageForm, EditGroupMessageForm

bp = Blueprint('groups', __name__)


@bp.route('/')
def index():
    # if session.get('student_id') is None:
    if not current_user.is_authenticated:
        return redirect('/login')

    recent_messages = get_related_group_messages(current_user.id)
    groups = get_my_groups(current_user.id)

    return render_template('index.html', Groups_len=len(groups), Groups=groups, Messages_len=len(recent_messages), Messages=recent_messages)



def is_group_member(group_id):
    members = get_members(group_id)

    for member in members:
        if member['ID'] == current_user.id:
            return True

    return False




@bp.route('/group/<int:group_id>')
def group(group_id):
    group = get_group(group_id) or abort(404)
    members = get_members(group_id)
    messages = get_messages(group_id)

    is_admin = group['ERSTELLER_ID'] == current_user.id
    is_member = is_admin or is_group_member(group_id)

    message_form = GroupMessageForm()

    return render_template('group.html',
        group_id=group_id, group=group, members=members, messages=messages,
        message_form=message_form, EditGroupMessageForm=EditGroupMessageForm,
        is_admin=is_admin, is_member=is_member)




@bp.route('/group/<int:group_id>/join', methods=('POST',))
def enter_group(group_id):
    group = get_group(group_id) or abort(404)

    if group['BETRETBAR'] == 0:
        raise Exception('You cannnot join this group directly.')
    if is_group_member(group_id):
        raise Exception('You are already member of this group.')

    if insert_group_member(group_id, current_user.id):
        flash('Du bist der Gruppe erfolgreich beigetreten.', category='success')
    else:
        flash('Ein Fehler ist aufgetreten.', category='failure')

    return redirect(url_for('groups.group', group_id=group_id))


def insert_group_member(group_id, student_id):
    db = get_db()

    with db.cursor() as cursor:
        cursor.execute("""
            INSERT INTO Gruppe_Student (gruppe_id, student_id, beitrittsdatum)
            VALUES (:gruppe_id, :student_id, SYSDATE)
        """, gruppe_id=group_id, student_id=student_id)

        if cursor.rowcount == 0:
            return False

    db.commit()
    cache.delete_memoized(get_group)
    cache.delete_memoized(get_groups)
    cache.delete_memoized(get_members)
    cache.delete_memoized(get_messages)

    return True



@bp.route('/group/<int:group_id>/leave', methods=('POST',))
def leave_group(group_id):
    group = get_group(group_id) or abort(404)

    if is_group_member(group_id):
        if delete_group_member(group_id, current_user.id):
            flash('Du hast die Gruppe verlassen', category='success')
        else:
            flash('Ein Fehler ist aufgetreten', category='failure')

    return redirect(url_for('groups.group', group_id=group_id))


def delete_group_member(group_id, student_id):
    db = get_db()

    with db.cursor() as cursor:
        cursor.execute("""
            DELETE FROM Gruppe_Student
            WHERE gruppe_id = :gruppe_id
             AND student_id = :student_id
        """, gruppe_id=group_id, student_id=student_id)

        if cursor.rowcount == 0:
            return False

    db.commit()
    cache.delete_memoized(get_group)
    cache.delete_memoized(get_groups)
    cache.delete_memoized(get_members)
    cache.delete_memoized(get_messages)

    return True





@bp.route('/group/<int:group_id>/message', methods=('POST',))
def group_message(group_id):
    get_group(group_id) or abort(404)

    form = GroupMessageForm()
    if form.validate_on_submit():

        if not is_group_member(group_id):
            raise Exception('You cannot send messages in this group.')

        insert_group_message(group_id, current_user.id, form.message.data)
        flash('Deine Nachricht wurde erfolgreich abgesendet.', category='success')
        return redirect(url_for('groups.group', group_id=group_id))
    abort(500) # this shouldn't happen during normal operation.


def insert_group_message(group_id, student_id, message):
    db = get_db()

    with db.cursor() as cursor:
        cursor.callproc('GruppenBeitragVerfassen',
            [ 'USER', message, group_id, student_id ])

    db.commit()
    cache.delete_memoized(get_messages, group_id)




@bp.route('/group/<int:group_id>/message/<int:message_id>/edit', methods=('POST',))
def edit_group_message(group_id, message_id):
    form = EditGroupMessageForm()
    if form.validate_on_submit():
        message = get_cached_message(group_id, message_id)
        if not message or message['STUDENT_ID'] != current_user.id:
            raise Exception('This message cannot be edited.')

        if update_group_message(group_id, message_id, form.message.data):
            flash('Die Nachricht wurde erfolgreich bearbeitet.', category='success')
        else:
            flash('Ein Fehler ist aufgetreten.', category='failure')
        return redirect(url_for('groups.group', group_id=group_id))
    abort(500) # this shouldn't happen during normal operation.


def update_group_message(group_id, message_id, message):
    db = get_db()

    with db.cursor() as cursor:
        cursor.execute("""
            UPDATE GruppenBeitrag
            SET nachricht = :nachricht
            WHERE id = :beitrag_id
        """, beitrag_id=message_id, nachricht=message)

        if cursor.rowcount == 0:
            return False

    db.commit()
    cache.delete_memoized(get_messages, group_id)
    return True




@bp.route('/group/<int:group_id>/message/<int:message_id>/delete', methods=('POST',))
def remove_group_message(group_id, message_id):
    message = get_cached_message(group_id, message_id)
    group = get_group(group_id) or abort(404)

    is_user_message = message['TYP'] == 'USER'
    is_admin = group['ERSTELLER_ID'] == current_user.id

    if not message or not is_user_message or \
            (not is_admin and message['STUDENT_ID'] != current_user.id):
        raise Exception('This message cannot be deleted.')

    if delete_group_message(group_id, message_id):
        flash('Die Nachricht wurde gelöscht.', category='success')
    else:
        flash('Ein Fehler ist aufgetreten.', category='failure')
    return redirect(url_for('groups.group', group_id=group_id))


def delete_group_message(group_id, message_id):
    db = get_db()

    with db.cursor() as cursor:
        cursor.execute("""
            DELETE FROM GruppenBeitrag
            WHERE id = :beitrag_id
        """, beitrag_id=message_id)

        if cursor.rowcount == 0:
            return False

    db.commit()
    cache.delete_memoized(get_messages, group_id)
    return True




@bp.route('/search')
def search():
    form = SearchForm()
    form.module_id.choices = [(-1, 'Alle Module')] + get_all_modules()

    module = request.args.get('module_id', '-1')
    q = request.args.get('q', '')
    free = request.args.get('free', '1')

    form.module_id.default = module
    form.process()
    form.q.data = q
    form.free.data = free

    groups = get_groups(module, q, free)

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

@cache.memoize(timeout=60)
def get_related_group_messages(student_id):
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
            """, student = student_id) # student = session.get('student_id'))

        cursor.rowfactory = lambda *args: dict(zip([d[0] for d in cursor.description], args))
        return cursor.fetchall()

# TODO: invalidate cache when entering a group.
@cache.memoize(timeout=60*10)
def get_my_groups(student_id):
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
            """, student = student_id) # session.get('student_id'))

        cursor.rowfactory = lambda *args: dict(zip([d[0] for d in cursor.description], args))
        return cursor.fetchall()

@cache.memoize(timeout=60*10)
def get_groups(module, description, free):
    db = get_db()

    with db.cursor() as cursor:

        cursor.execute("""
                SELECT  g.id,
                        g.modul_id,
                        m.name as modul,
                        g.name,
                        (SELECT count(ersteller_id) FROM Gruppe WHERE id = g.id AND ersteller_id = :student) ist_ersteller,
                        (SELECT count(student_id) FROM Gruppe_Student WHERE gruppe_id = g.id AND student_id = :student) ist_mitglied,
                        (SELECT count(student_id) FROM Gruppe_Student WHERE gruppe_id = g.id) mitglieder,
                        g.limit,
                        g.betretbar,
                        g.deadline,
                        g.ort
                FROM Gruppe g
                INNER JOIN Modul m ON g.modul_id = m.id
                WHERE   oeffentlich = '1' AND
                        (:modul = -1 OR modul_id = :modul) AND
                        (LOWER(g.name) LIKE LOWER(:bezeichnung) OR LOWER(g.ort) LIKE LOWER(:bezeichnung) OR LOWER(m.name) LIKE LOWER(:bezeichnung)) AND
                        (g.limit IS NULL OR g.limit - (SELECT count(student_id) FROM Gruppe_Student WHERE gruppe_id = g.id) >= :freie)
                ORDER BY ist_mitglied, deadline DESC
            """, student = current_user.id, # session.get('student_id'),
                 modul = module,
                 bezeichnung = "%" + description + "%",
                 freie = free)

        cursor.rowfactory = lambda *args: dict(zip([d[0] for d in cursor.description], args))
        return cursor.fetchall()


@cache.memoize(timeout=60*1)
def get_group(group_id):
    db = get_db()

    with db.cursor() as cursor:

        cursor.execute("""
            SELECT  id,
                    ersteller_id,
                    modul_id,
                    (SELECT name FROM Modul WHERE modul_id = Modul.id) modul,
                    g.name,
                    g.limit,
                    oeffentlich,
                    betretbar,
                    deadline,
                    ort
            FROM Gruppe g
            WHERE g.id = :gruppe_id
        """, gruppe_id = group_id)

        cursor.rowfactory = lambda *args: dict(zip([d[0] for d in cursor.description], args))
        return cursor.fetchone()


@cache.memoize(timeout=60*1)
def get_members(group_id):
    db = get_db()

    with db.cursor() as cursor:

        cursor.execute("""
            SELECT s.id, s.name, (CASE WHEN g.ersteller_id = gs.student_id THEN 1 ELSE 0 END) ist_ersteller
            FROM Gruppe_Student gs
            INNER JOIN Student s ON gs.student_id = s.id
            INNER JOIN Gruppe g ON gs.gruppe_id = g.id
            WHERE gs.gruppe_id = :gruppe_id
        """, gruppe_id = group_id)

        cursor.rowfactory = lambda *args: dict(zip([d[0] for d in cursor.description], args))
        return cursor.fetchall()


@cache.memoize(timeout=60*1)
def get_messages(group_id):
    db = get_db()

    with db.cursor() as cursor:

        cursor.execute("""
            SELECT gb.id, gb.student_id, s.name as student, gb.datum, gb.nachricht, gb.typ
            FROM GruppenBeitrag gb
            LEFT JOIN Student s ON gb.student_id = s.id
            WHERE gb.gruppe_id = :gruppe_id
            ORDER BY gb.datum ASC
        """, gruppe_id = group_id)

        cursor.rowfactory = lambda *args: dict(zip([d[0] for d in cursor.description], args))
        return cursor.fetchall()


# get_messages will always be called before this function.
# thus a call to get_messages will land a cache hit and be really fast.
def get_cached_message(group_id, message_id):
    for message in get_messages(group_id):
        if message['ID'] == message_id:
            return message
    return None
