from flask_wtf import FlaskForm
from wtforms import StringField, TextAreaField, SelectField, BooleanField, FileField, SubmitField
from wtforms.validators import DataRequired

class CardForm(FlaskForm):
    fname = StringField('First Name', validators=[DataRequired()])
    lname = StringField('Last Name', validators=[DataRequired()])
    pronouns = StringField('Gender Pronouns')
    title = StringField('Job Title')
    biz = StringField('Business Name')
    addr = TextAreaField('Business Address')
    desc = TextAreaField('Business Description')
    key = TextAreaField('OpenPGP Public Key')
    tracker = TextAreaField('Tracking Code')
    font_link = TextAreaField('Web Font Embed Code')
    font_css = StringField('Web Font CSS Rule')
    hosted_url = StringField('Hosted Card URL')
    footer_credit = BooleanField('Enable Footer Credit')
    logo = FileField('Add Logo')
    photo = FileField('Add Profile Photo')
    cover = FileField('Add Cover Photo')
    submit = SubmitField('Create Your Own')
