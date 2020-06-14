from flask_wtf import FlaskForm
from wtforms import StringField, PasswordField, BooleanField, SubmitField, DateField, SelectField
import wtforms.validators as validators


class LoginForm(FlaskForm):
    email    = StringField   ('E-Mail',   validators=[validators.required()])
    password = PasswordField ('Passwort', validators=[validators.required()])

    stay_logged_in = BooleanField ('Eingeloggt bleiben')
    submit         = SubmitField  ('Anmelden')

class SimpleSearchForm(FlaskForm):
    q   =   StringField ('Gruppe Suchen',   validators=[validators.required(), validators.length(max=64)], render_kw={"placeholder": "Gruppe Suchen"})

class SearchForm(FlaskForm):
    module_id   =   SelectField ('Modul',           coerce=int)
    q           =   StringField ('Suche',     validators=[validators.length(max=64)], render_kw={"placeholder": "Bezeichnung oder Ort"})

    submit         = SubmitField  ('Suche')
