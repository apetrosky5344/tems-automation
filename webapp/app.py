from flask import Flask, render_template, request, redirect, url_for, session
import psycopg2
import os
from werkzeug.security import generate_password_hash, check_password_hash

app = Flask(__name__)
app.secret_key = os.getenv("SECRET_KEY", "supersecretkey")

# Load database credentials from environment variables
db_name = os.getenv("DB_NAME", "tems_db")
db_user = os.getenv("DB_USER", "tems_admin")
db_pass = os.getenv("DB_PASS", "securepassword")
db_host = os.getenv("DB_HOST", "10.2.37.63")
db_port = os.getenv("DB_PORT", "5432")

# Establish database connection
def get_db_connection():
    conn = psycopg2.connect(
        dbname=db_name,
        user=db_user,
        password=db_pass,
        host=db_host,
        port=db_port
    )
    return conn

@app.route('/')
def home():
    return render_template('index.html')

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        email = request.form['email']
        password = request.form['password']
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute('SELECT id, password FROM users WHERE email = %s;', (email,))
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
        password = generate_password_hash(request.form['password'])
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute('INSERT INTO users (name, email, password) VALUES (%s, %s, %s);', (name, email, password))
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

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=5000)
