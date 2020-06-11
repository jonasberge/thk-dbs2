from flask_wtf import FlaskForm
from wtforms import StringField, PasswordField, BooleanField, SubmitField, DateField, SelectField
import wtforms.validators as validators


class LoginForm(FlaskForm):
    email    = StringField   ('E-Mail',   validators=[validators.required()])
    password = PasswordField ('Passwort', validators=[validators.required()])

    stay_logged_in = BooleanField ('Eingeloggt bleiben')
    submit         = SubmitField  ('Anmelden')


class RegisterForm(FlaskForm):
    name      = StringField   ('Name',         validators=[validators.required(), validators.length(max=64)])
    course_id = SelectField   ('Studiengang',  validators=[validators.required()], coerce=int)
    email     = StringField   ('E-Mail',       validators=[validators.required(), validators.length(max=64)])
    password  = PasswordField ('Passwort',     validators=[validators.required(), validators.length(max=32)])
    birthday  = DateField     ('Geburtsdatum', validators=[validators.optional()])

    stay_logged_in = BooleanField ('Eingeloggt bleiben')
    submit         = SubmitField  ('Registrieren')
