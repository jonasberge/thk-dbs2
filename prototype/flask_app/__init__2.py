import os

import cx_Oracle as ora
from flask import Flask
from dotenv import load_dotenv
from flask_login import LoginManager
from flask_sqlalchemy import SQLAlchemy

login_manager = LoginManager()

def create_app(test_config=None):
    # create and configure the app
    app = Flask(__name__, instance_relative_config=True)
    
    login_manager.init_app(app)

    basedir = os.path.join(os.path.dirname(__file__), '..')
    load_dotenv(os.path.join(basedir, '.env'))

    dsn_str = ora.makedsn(os.environ.get('ORACLE_HOST'),
                          os.environ.get('ORACLE_PORT'),
                          os.environ.get('ORACLE_SID'))

    app.config.from_mapping(
        SECRET_KEY = os.environ.get('SECRET_KEY') or 'dev',
        DB_DSN     = dsn_str,
        DB_USER    = os.environ.get('ORACLE_USER'),
        DB_PASS    = os.environ.get('ORACLE_PASS')
    )
    
    with app.app_context():
        from . import login2
        
    if test_config is None:
        # load the instance config, if it exists, when not testing
        app.config.from_pyfile('config.py', silent=True)
    else:
        # load the test config if passed in
        app.config.from_mapping(test_config)

    # ensure the instance folder exists
    try:
        os.makedirs(app.instance_path)
    except OSError:
        pass

    from . import db, cache, test_data
    db.init_app(app)
    test_data.init_app(app)
    cache.init_app(app)

    from . import login, groups
    app.register_blueprint(login.bp)
    app.register_blueprint(groups.bp)

    return app