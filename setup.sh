#!/bin/bash

# Create project directories
echo "Creating project directories..."
mkdir -p static/uploads
mkdir -p static/css
mkdir -p static/js
mkdir -p templates
mkdir -p instance

# Create virtual environment
echo "Creating virtual environment..."
python3 -m venv venv

# Activate virtual environment
echo "Activating virtual environment..."
source venv/bin/activate

# Install required packages
echo "Installing required packages..."
pip install flask flask-wtf flask-sqlalchemy

# Create app.py
echo "Creating app.py..."
cat > app.py << EOL
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
EOL

# Create forms.py
echo "Creating forms.py..."
cat > forms.py << EOL
from flask_wtf import FlaskForm
from wtforms import StringField, TextAreaField, BooleanField, FileField, SubmitField
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
EOL

# Create utils.py
echo "Creating utils.py..."
cat > utils.py << EOL
import os
import zipfile
from io import BytesIO
from flask import render_template

def generate_vcard(card):
    vcard = f"""
BEGIN:VCARD
VERSION:3.0
N:{card.lname};{card.fname}
FN:{card.fname} {card.lname}
ORG:{card.biz}
TITLE:{card.title}
END:VCARD
    """
    return BytesIO(vcard.encode('utf-8'))

def create_zip(card, upload_folder):
    buffer = BytesIO()
    with zipfile.ZipFile(buffer, 'w') as z:
        z.writestr('index.html', render_template('download.html', card=card))
        for filename in os.listdir(upload_folder):
            z.write(os.path.join(upload_folder, filename), filename)
    buffer.seek(0)
    return buffer
EOL

# Create HTML templates
echo "Creating HTML templates..."
cat > templates/base.html << EOL
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{% block title %}3wc_DigiCard{% endblock %}</title>
    <link rel="stylesheet" href="{{ url_for('static', filename='css/style.css') }}">
</head>
<body>
    {% block content %}{% endblock %}
    {% block footer %}
    <footer>
        <p>&copy; 2024 3wc_DigiCard</p>
    </footer>
    {% endblock %}
    <script src="{{ url_for('static', filename='js/script.js') }}"></script>
</body>
</html>
EOL

cat > templates/index.html << EOL
{% extends "base.html" %}

{% block content %}
<header>
    <h1>3wc_DigiCard</h1>
</header>
<section class="hero">
    <div class="hero-content">
        <h2>Create Your Own Digital Business Card</h2>
        <p>Showcase your brand, connect instantly with a tap <br> and generate profitable leads.</p>
        <a href="{{ url_for('create_card') }}" class="cta-button">Get Started</a>
    </div>
</section>
<section class="features">
    <h2>Key Features</h2>
    <div class="card-container">
        <div class="feature-card">
            <h3>Customizable Templates</h3>
            <p>Choose from a variety of professionally designed templates.</p>
        </div>
        <div class="feature-card">
            <h3>Interactive Elements</h3>
            <p>Add social media links, contact forms, and more.</p>
        </div>
        <div class="feature-card">
            <h3>Easy Sharing</h3>
            <p>Share your digital card via SMS, Whatsapp, <br> QR code, email, or social media.</p>
        </div>
    </div>
</section>
{% endblock %}
EOL

cat > templates/create_card.html << EOL
{% extends "base.html" %}

{% block content %}
<div class="container">
    <div class="preview-container">
        <div id="previewWrapper">
            <div id="generatedUrl" style="display: none;">
                <p>Your card URL:</p>
                <a href="" id="cardLink" target="_blank"></a>
            </div>
            <h2>LIVE PREVIEW</h2>
            <div id="cardPreview" class="business-card">
                <!-- Preview content will be dynamically updated here -->
            </div>
        </div>
    </div>
    <div class="form-container">
        <h1>Create Your Digital Business Card</h1>
        <form id="cardForm" method="POST" enctype="multipart/form-data">
            {{ form.hidden_tag() }}
            
            <h2>Header attachments</h2>
            <div class="form-group">
                {{ form.logo.label }} {{ form.logo }}
                <small>suggested format: svg, png or gif</small>
            </div>
            <div class="form-group">
                {{ form.cover.label }} {{ form.cover }}
                <small>suggested format: svg, jpeg, png or gif</small>
            </div>
            <small>Recommended cover photo size is 960 x 640 pixels, with an aspect ratio of 3:2</small>

            <h2>Contact information</h2>
            <div class="form-group">
                {{ form.photo.label }} {{ form.photo }}
                <small>suggested format: jpeg, png or gif</small>
            </div>
            <small>Recommended profile photo size is 320 x 320 pixels, with an aspect ratio of 1:1</small>

            {% for field in form if field.name not in ['logo', 'cover', 'photo', 'submit'] %}
            <div class="form-group">
                {{ field.label }} {{ field }}
            </div>
            {% endfor %}

            <div class="form-group">
                {{ form.submit(class="btn btn-primary") }}
            </div>
        </form>
    </div>
</div>

<script>
document.addEventListener('DOMContentLoaded', function() {
    const form = document.getElementById('cardForm');
    const preview = document.getElementById('cardPreview');
    const generatedUrl = document.getElementById('generatedUrl');
    const cardLink = document.getElementById('cardLink');

    function updatePreview() {
        const formData = new FormData(form);
        preview.innerHTML = \`
            <h2>\${formData.get('fname') || 'First'} \${formData.get('lname') || 'Last'}</h2>
            \${formData.get('pronouns') ? \`<p>\${formData.get('pronouns')}</p>\` : ''}
            \${formData.get('title') ? \`<p>\${formData.get('title')}</p>\` : ''}
            \${formData.get('biz') ? \`<p>\${formData.get('biz')}</p>\` : ''}
            \${formData.get('addr') ? \`<p>\${formData.get('addr')}</p>\` : ''}
            \${formData.get('desc') ? \`<p>\${formData.get('desc')}</p>\` : ''}
        \`;
    }

    form.addEventListener('input', updatePreview);
    updatePreview(); // Initial preview

    form.addEventListener('submit', function(e) {
        e.preventDefault();
        const formData = new FormData(form);
        
        fetch('/create_card', {
            method: 'POST',
            body: formData
        })
        .then(response => response.json())
        .then(data => {
            if (data.success) {
                cardLink.href = data.url;
                cardLink.textContent = data.url;
                generatedUrl.style.display = 'block';
            }
        });
    });
});
</script>
{% endblock %}
EOL

cat > templates/view_card.html << EOL
{% extends "base.html" %}

{% block content %}
<div class="container">
    <div class="business-card">
        <h2>{{ card.fname }} {{ card.lname }}</h2>
        {% if card.pronouns %}
        <p>{{ card.pronouns }}</p>
        {% endif
        <p>{{ card.title }}</p>
        <p>{{ card.biz }}</p>
        <p>{{ card.addr }}</p>
        <p>{{ card.desc }}</p>
        {% if card.logo %}
        <img src="{{ url_for('static', filename='uploads/' + card.logo) }}" alt="Logo">
        {% endif %}
        {% if card.photo %}
        <img src="{{ url_for('static', filename='uploads/' + card.photo) }}" alt="Photo">
        {% endif %}
        {% if card.cover %}
        <img src="{{ url_for('static', filename='uploads/' + card.cover) }}" alt="Cover">
        {% endif %}
    </div>
</div>
{% endblock %}
EOL

cat > templates/preview.html << EOL
{% extends "base.html" %}

{% block content %}
    <h1>Preview Your Digital Business Card</h1>
    <div class="preview-container">
        <div class="business-card">
            <h2>{{ card.fname }} {{ card.lname }}</h2>
            <p>{{ card.title }}</p>
            <p>{{ card.biz }}</p>
            <p>{{ card.addr }}</p>
            <p>{{ card.desc }}</p>
            {% if card.logo %}
            <img src="{{ url_for('static', filename='uploads/' + card.logo) }}" alt="Logo">
            {% endif %}
            {% if card.photo %}
            <img src="{{ url_for('static', filename='uploads/' + card.photo) }}" alt="Profile Photo">
            {% endif %}
            {% if card.cover %}
            <img src="{{ url_for('static', filename='uploads/' + card.cover) }}" alt="Cover Photo">
            {% endif %}
        </div>
    </div>
{% endblock %}
EOL

cat > templates/download.html << EOL
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{ card.fname }} {{ card.lname }}'s Business Card</title>
    <link rel="stylesheet" href="style.min.css">
</head>
<body>
    <div class="business-card">
        <h2>{{ card.fname }} {{ card.lname }}</h2>
        <p>{{ card.title }}</p>
        <p>{{ card.biz }}</p>
        <p>{{ card.addr }}</p>
        <p>{{ card.desc }}</p>
        {% if card.logo %}
        <img src="logo.png" alt="Logo">
        {% endif %}
        {% if card.photo %}
        <img src="photo.png" alt="Profile Photo">
        {% endif %}
        {% if card.cover %}
        <img src="cover.png" alt="Cover Photo">
        {% endif %}
    </div>
</body>
</html>
EOL

# Create static files
echo "Creating static files..."
cat > static/css/style.css << EOL
body {
    font-family: Arial, sans-serif;
    line-height: 1.6;
    margin: 0;
    padding: 0;
    background-color: #1c1e26;
    color: #ffffff;
}

.container {
    width: 95%;
    max-width: 1200px;
    margin: auto;
    overflow: hidden;
    padding: 20px;
    display: flex;
    flex-direction: row-reverse;
}

.form-container {
    width: 60%;
    padding-right: 20px;
}

.preview-container {
    width: 40%;
    position: relative;
}

#previewWrapper {
    position: sticky;
    top: 20px;
    background-color: #2a2e3a;
    border-radius: 10px;
    padding: 20px;
    margin-bottom: 20px;
}

.business-card {
    background-color: #ffffff;
    border-radius: 10px;
    box-shadow: 0 4px 6px rgba(0,0,0,0.1);
    padding: 20px;
    margin-bottom: 20px;
    color: #333;
}

h1, h2 {
    color: #ffffff;
    margin-bottom: 20px;
}

.form-group {
    margin-bottom: 15px;
}

.form-group label {
    display: block;
    margin-bottom: 5px;
    color: #a0a0a0;
}

.form-group input[type="text"],
.form-group input[type="file"],
.form-group textarea {
    width: 100%;
    padding: 8px;
    border: 1px solid #3a3f4b;
    border-radius: 4px;
    background-color: #2a2e3a;
    color: #ffffff;
}

.btn {
    display: inline-block;
    background: #4caf50;
    color: #ffffff;
    padding: 10px 20px;
    border: none;
    border-radius: 5px;
    cursor: pointer;
    text-decoration: none;
    font-size: 15px;
}

.btn:hover {
    background: #45a049;
}

small {
    color: #a0a0a0;
    display: block;
    margin-top: 5px;
}

#generatedUrl {
    background-color: #2a2e3a;
    border-radius: 5px;
    padding: 10px;
    margin-bottom: 10px;
}

#generatedUrl p {
    margin: 0;
    color: #a0a0a0;
}

#generatedUrl a {
    color: #4caf50;
    text-decoration: none;
}

#generatedUrl a:hover {
    text-decoration: underline;
}

/* Styling for file input buttons */
input[type="file"] {
    border: none;
    background-color: #3a3f4b;
    color: #ffffff;
    padding: 10px;
    border-radius: 5px;
    cursor: pointer;
}

input[type="file"]::-webkit-file-upload-button {
    visibility: hidden;
}

input[type="file"]::before {
    content: 'Select file';
    display: inline-block;
    background: #4caf50;
    border-radius: 3px;
    padding: 5px 8px;
    outline: none;
    white-space: nowrap;
    -webkit-user-select: none;
    cursor: pointer;
    font-weight: 700;
    font-size: 10pt;
}

input[type="file"]:hover::before {
    background: #45a049;
}

/* New styles for the home page */
header {
    background-color: #2a2e3a;
    padding: 20px;
    text-align: center;
}

header h1 {
    margin: 0;
    color: #4caf50;
}

.hero {
    background-color: #1c1e26;
    color: #ffffff;
    text-align: center;
    padding: 50px 20px;
}

.hero-content h2 {
    font-size: 2.5em;
    margin-bottom: 20px;
}

.hero-content p {
    font-size: 1.2em;
    margin-bottom: 30px;
}

.cta-button {
    display: inline-block;
    background-color: #4caf50;
    color: white;
    padding: 10px 20px;
    text-decoration: none;
    border-radius: 5px;
    font-size: 1.1em;
    transition: background-color 0.3s;
}

.cta-button:hover {
    background-color: #45a049;
}

.features {
    padding: 50px 20px;
    background-color: #2a2e3a;
}

.features h2 {
    text-align: center;
    margin-bottom: 30px;
}

.card-container {
    display: flex;
    justify-content: space-around;
    flex-wrap: wrap;
}

.feature-card {
    background-color: #1c1e26;
    border-radius: 10px;
    padding: 20px;
    margin: 10px;
    width: calc(33.333% - 20px);
    box-sizing: border-box;
}

.feature-card h3 {
    color: #4caf50;
    margin-bottom: 10px;
}

footer {
    background-color: #1c1e26;
    color: #ffffff;
    text-align: center;
    padding: 20px;
    position: relative;
    bottom: 0;
    width: 100%;
}

/* Responsive design */
@media (max-width: 768px) {
    .container {
        flex-direction: column;
    }
    
    .form-container,
    .preview-container {
        width: 100%;
        padding-right: 0;
    }
    
    #previewWrapper {
        position: static;
    }

    .feature-card {
        width: calc(50% - 20px);
    }
}

@media (max-width: 480px) {
    .feature-card {
        width: 100%;
    }
}
EOL

cat > static/js/script.js << EOL
// Add any custom JavaScript here
console.log('Script loaded');
EOL

# Initialize the database
echo "Initializing the database..."
python3 << EOL
from app import app, db
with app.app_context():
    db.create_all()
print("Database initialized successfully.")
EOL

echo "Setup complete. To run the Flask app, execute the following commands:"
echo "source venv/bin/activate"
echo "flask run"