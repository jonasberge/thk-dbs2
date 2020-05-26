import cx_Oracle

from flask import current_app, g

def get_db():
    if 'db' not in g:
        g.db = cx_Oracle.connect(
            current_app.config['DB_USER'],
            current_app.config['DB_PW'],
            current_app.config['DB_URI']
        )
    return g.db

def close_db(self):
    db = g.pop('db', None)

    if db is not None:
        db.close()

def init_app(app):
    app.teardown_appcontext(close_db)

