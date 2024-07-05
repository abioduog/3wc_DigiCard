# 3wc_DigiCard

## Digital Business Card Creator

3wc_DigiCard is a web application that allows users to create, customize, and share digital business cards. Built with Flask, this project aims to provide a modern, eco-friendly alternative to traditional paper business cards.

![3wc_DigiCard Screenshot](path_to_screenshot.png)

## Table of Contents

1. [Features](#features)
2. [Prerequisites](#prerequisites)
3. [Installation](#installation)
4. [Usage](#usage)
5. [Project Structure](#project-structure)
6. [Technologies Used](#technologies-used)
7. [Contributing](#contributing)
8. [License](#license)
9. [Contact](#contact)

## Features

- Create customizable digital business cards
- Upload logo, cover photo, and profile picture
- Real-time preview of the business card
- Generate shareable links for created cards
- Responsive design for various devices
- Dark mode user interface

## Prerequisites

Before you begin, ensure you have met the following requirements:

- Python 3.7 or higher
- pip (Python package installer)
- Git

## Installation

To install 3wc_DigiCard, follow these steps:

1. Clone the repository:
   ```
   git clone https://github.com/abioduog/3wc_DigiCard.git
   ```

2. Navigate to the project directory:
   ```bash
   cd 3wc_DigiCard
   ```

3. Run the setup script:
   ```bash
   chmod +x setup.sh
   ./setup.sh
   ```

   This script will:
   - Create necessary directories
   - Set up a virtual environment
   - Install required packages
   - Initialize the database

## Usage

To use 3wc_DigiCard, follow these steps:

1. Activate the virtual environment:
   ```bash
   source venv/bin/activate
   ```

2. Start the Flask application:
   ```bash
   flask run
   ```

3. Open a web browser and navigate to `http://127.0.0.1:5000/`

4. Click on "Get Started" to create your digital business card

5. Fill out the form with your information and upload images as desired

6. Click "Create Your Own" to generate your digital business card

7. Share the provided link to distribute your digital business card

## Project Structure

```
3wc_DigiCard/
│
├── static/
│   ├── css/
│   │   └── style.css
│   ├── js/
│   │   └── script.js
│   └── uploads/
│
├── templates/
│   ├── base.html
│   ├── index.html
│   ├── create_card.html
│   ├── view_card.html
│   ├── preview.html
│   └── download.html
│
├── instance/
│   └── cards.db
│
├── app.py
├── forms.py
├── utils.py
├── setup.sh
└── requirements.txt
```

## Technologies Used

- [Flask](https://flask.palletsprojects.com/): Web framework
- [SQLite](https://www.sqlite.org/): Database
- [Flask-SQLAlchemy](https://flask-sqlalchemy.palletsprojects.com/): ORM for database operations
- [Flask-WTF](https://flask-wtf.readthedocs.io/): Form handling
- HTML/CSS/JavaScript: Front-end development

## Contributing

Contributions to 3wc_DigiCard are welcome! Here's how you can contribute:

1. Fork the repository
2. Create a new branch: `git checkout -b feature-branch-name`
3. Make your changes and commit them: `git commit -m 'Add some feature'`
4. Push to the branch: `git push origin feature-branch-name`
5. Create a pull request

Please make sure to update tests as appropriate and adhere to the project's code style.

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.

## Contact

If you want to contact me, you can reach me at `your.email@example.com`.

Project Link: [https://github.com/abioduog/3wc_DigiCard](https://github.com/abioduog/3wc_DigiCard)
