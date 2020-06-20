from flask_wtf import FlaskForm
from wtforms import ( StringField, PasswordField, BooleanField, SubmitField,
                      DateField, SelectField, TextAreaField, IntegerField )
from wtforms.widgets.html5 import NumberInput
import wtforms.validators as validators
from wtforms.validators import ValidationError, DataRequired, Email, EqualTo, Length


class LoginForm(FlaskForm):
    email = StringField('E-Mail', validators=[validators.required()])
    password = PasswordField('Passwort', validators=[validators.required()])

    stay_logged_in = BooleanField('Eingeloggt bleiben')
    submit = SubmitField('Anmelden')


class SimpleSearchForm(FlaskForm):
    q = StringField('Gruppe Suchen', validators=[validators.required(), validators.length(max=64)],
                    render_kw={"placeholder": "Gruppe Suchen"})


class SearchForm(FlaskForm):
    module_id = SelectField('Modul', coerce=int)
    q = StringField('Suche', validators=[validators.length(max=64)], render_kw={"placeholder": "Suchbegriff"})
    free = IntegerField('Freie Plätze', widget=NumberInput(min=0, max=9), default=1)
    submit = SubmitField('Suche')


class EditProfileForm(FlaskForm):
    about_me = TextAreaField('Beschreibung', render_kw={'maxlength': '255'}, validators=[Length(min=0, max=255)])
    submit = SubmitField('Speichern')
