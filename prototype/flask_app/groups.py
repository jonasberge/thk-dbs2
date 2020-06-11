import functools

from flask import (
    Blueprint, flash, g, redirect, render_template, request, session, url_for
)
from werkzeug.security import check_password_hash, generate_password_hash

from flask_app.db import get_db
from flask_app.forms import LoginForm

bp = Blueprint('groups', __name__)

@bp.route('/')
def index():
    return render_template('index.html')
