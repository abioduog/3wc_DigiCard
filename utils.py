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
TEL;TYPE=CELL:{card.phone}
EMAIL;TYPE=PREF,INTERNET:{card.email}
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
