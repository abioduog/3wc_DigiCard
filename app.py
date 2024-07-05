import os
from flask import Flask, render_template, request, redirect, url_for, flash, send_file, jsonify
from flask_sqlalchemy import SQLAlchemy
from sqlalchemy import inspect
from werkzeug.utils import secure_filename
from forms import CardForm
from utils import generate_vcard, create_zip

basedir = os.path.abspath(os.path.dirname(__file__))

app = Flask(__name__)
app.secret_key = 'your_secret_key'
UPLOAD_FOLDER = 'static/uploads'
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///' + os.path.join(basedir, 'instance', 'cards.db')
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
db = SQLAlchemy(app)

class BusinessCard(db.Model):
    __tablename__ = 'business_card'
    id = db.Column(db.Integer, primary_key=True)
    fname = db.Column(db.String(100), nullable=False)
    lname = db.Column(db.String(100), nullable=False)
    pronouns = db.Column(db.String(50))
    title = db.Column(db.String(100))
    biz = db.Column(db.String(100))
    addr = db.Column(db.Text)
    desc = db.Column(db.Text)
    key = db.Column(db.Text)
    tracker = db.Column(db.Text)
    font_link = db.Column(db.Text)
    font_css = db.Column(db.String(200))
    hosted_url = db.Column(db.String(200))
    footer_credit = db.Column(db.Boolean)
    logo = db.Column(db.String(100))
    photo = db.Column(db.String(100))
    cover = db.Column(db.String(100))

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/create_card', methods=['GET', 'POST'])
def create_card():
    form = CardForm()
    if form.validate_on_submit():
        # Handle file uploads
        logo_filename = handle_file_upload(form.logo.data, 'logo')
        cover_filename = handle_file_upload(form.cover.data, 'cover')
        photo_filename = handle_file_upload(form.photo.data, 'photo')

        new_card = BusinessCard(
            fname=form.fname.data,
            lname=form.lname.data,
            pronouns=form.pronouns.data,
            title=form.title.data,
            biz=form.biz.data,
            addr=form.addr.data,
            desc=form.desc.data,
            key=form.key.data,
            tracker=form.tracker.data,
            font_link=form.font_link.data,
            font_css=form.font_css.data,
            hosted_url=form.hosted_url.data,
            footer_credit=form.footer_credit.data,
            logo=logo_filename,
            photo=photo_filename,
            cover=cover_filename
        )
        db.session.add(new_card)
        db.session.commit()

        card_url = url_for('view_card', card_id=new_card.id, _external=True)
        return jsonify({'success': True, 'url': card_url})
    
    if form.errors:
        return jsonify({'success': False, 'errors': form.errors}), 400
    
    return render_template('create_card.html', form=form)

def handle_file_upload(file_data, prefix):
    if file_data:
        filename = secure_filename(f"{prefix}_{file_data.filename}")
        file_path = os.path.join(app.config['UPLOAD_FOLDER'], filename)
        file_data.save(file_path)
        return filename
    return None

@app.route('/card/<int:card_id>')
def view_card(card_id):
    card = BusinessCard.query.get_or_404(card_id)
    return render_template('view_card.html', card=card)

@app.route('/preview_card/<int:card_id>')
def preview_card(card_id):
    card = BusinessCard.query.get_or_404(card_id)
    return render_template('preview.html', card=card)

@app.route('/download_vcard/<int:card_id>')
def download_vcard(card_id):
    card = BusinessCard.query.get_or_404(card_id)
    vcard_content = generate_vcard(card)
    return send_file(vcard_content, as_attachment=True, download_name="business_card.vcf")

@app.route('/download_package/<int:card_id>')
def download_package(card_id):
    card = BusinessCard.query.get_or_404(card_id)
    zip_content = create_zip(card, app.config['UPLOAD_FOLDER'])
    return send_file(zip_content, as_attachment=True, download_name="business_card_package.zip")

def init_db():
    """Initialize the database."""
    if not os.path.exists(os.path.join(basedir, 'instance')):
        os.makedirs(os.path.join(basedir, 'instance'))
    db_path = os.path.join(basedir, 'instance', 'cards.db')
    if not os.path.exists(db_path):
        with app.app_context():
            db.create_all()
        print(f"Database created at {db_path}")
    else:
        print(f"Database already exists at {db_path}")

    with app.app_context():
        inspector = inspect(db.engine)
        if not inspector.has_table(BusinessCard.__tablename__):
            db.create_all()
            print(f"Table '{BusinessCard.__tablename__}' created.")
        else:
            print(f"Table '{BusinessCard.__tablename__}' already exists.")

if __name__ == '__main__':
    init_db()
    app.run(debug=True)
else:
    # This block will run when the app is started with 'flask run'
    init_db()