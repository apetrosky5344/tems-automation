from flask import Flask, render_template, request, redirect, url_for, session
import psycopg2
import os
from werkzeug.security import generate_password_hash, check_password_hash

app = Flask(__name__)

# Load SECRET_KEY from environment or fall back to a default
app.secret_key = os.getenv("SECRET_KEY", "supersecretkey")

# Database configuration from environment variables
db_name = os.getenv("DB_NAME", "tems_db")
db_user = os.getenv("DB_USER", "tems_admin")
db_pass = os.getenv("DB_PASS", "securepassword")
db_host = os.getenv("DB_HOST", "127.0.0.1")
db_port = os.getenv("DB_PORT", "5432")

def get_db_connection():
    """Creates a new PostgreSQL connection using environment variables."""
    return psycopg2.connect(
        dbname=db_name,
        user=db_user,
        password=db_pass,
        host=db_host,
        port=db_port
    )

@app.route('/')
def home():
    return render_template('index.html')

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        email = request.form['email']
        password = request.form['password']

        # Query the database for matching user
        conn = get_db_connection()
        cur = conn.cursor()
        # Make sure to select user_id and password_hash from the schema
        cur.execute('SELECT user_id, password_hash FROM users WHERE email = %s', (email,))
        user = cur.fetchone()
        cur.close()
        conn.close()

        if user and check_password_hash(user[1], password):
            session['user_id'] = user[0]
            return redirect(url_for('dashboard'))
        else:
            return "Invalid credentials", 403
    return render_template('login.html')

@app.route('/register', methods=['GET', 'POST'])
def register():
    if request.method == 'POST':
        name = request.form['name']
        email = request.form['email']
        raw_password = request.form['password']
        password_hash = generate_password_hash(raw_password)
        member_number = request.form.get('member_number')  # Optional field

        # Insert the new user into the DB, associating the member number if provided
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute('''
            INSERT INTO users (name, email, password_hash, member_id)
            VALUES (%s, %s, %s, %s)
            RETURNING user_id
        ''', (name, email, password_hash, member_number if member_number and member_number.strip() else None))
        new_user_id = cur.fetchone()[0]
        conn.commit()
        cur.close()
        conn.close()

        return redirect(url_for('login'))
    return render_template('register.html')

@app.route('/dashboard')
def dashboard():
    if 'user_id' not in session:
        return redirect(url_for('login'))
    return render_template('dashboard.html')

@app.route('/logout')
def logout():
    session.pop('user_id', None)
    return redirect(url_for('home'))

if __name__ == '__main__':
    # For local testing only. In production, use Gunicorn or another WSGI server.
    app.run(host='0.0.0.0', port=5000, debug=True)
