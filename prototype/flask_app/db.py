import cx_Oracle

from flask import current_app, g

def get_db():
    if 'db' not in g:
        g.db = cx_Oracle.connect(
            user     = current_app.config['DB_USER'],
            password = current_app.config['DB_PASS'],
            dsn      = current_app.config['DB_DSN']
        )
    return g.db

def close_db(self):
    db = g.pop('db', None)

    if db is not None:
        db.close()

def init_app(app):
    app.teardown_appcontext(close_db)
