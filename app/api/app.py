from flask import Flask, request, jsonify
from flask_cors import CORS
import psycopg2
import os

app = Flask(__name__)
CORS(app)

DB_HOST = os.getenv('DB_HOST', 'notes-db')
DB_NAME = os.getenv('DB_NAME', 'notesdb')
DB_USER = os.getenv('DB_USER', 'notesuser')
DB_PASS = os.getenv('DB_PASS', 'notespass')

def get_db():
    return psycopg2.connect(
        host=DB_HOST, database=DB_NAME, 
        user=DB_USER, password=DB_PASS
    )

@app.route('/notes', methods=['GET'])
def get_notes():
    conn = get_db()
    cur = conn.cursor()
    cur.execute("SELECT id, note FROM notes")
    notes = [{"id": row[0], "note": row[1]} for row in cur.fetchall()]
    cur.close()
    conn.close()
    return jsonify(notes)

@app.route('/add', methods=['POST'])
def add_note():
    data = request.json
    conn = get_db()
    cur = conn.cursor()
    cur.execute("INSERT INTO notes (note) VALUES (%s)", (data['note'],))
    conn.commit()
    cur.close()
    conn.close()
    return jsonify({"status": "success"})

@app.route('/delete', methods=['POST'])
def delete_note():
    data = request.json
    conn = get_db()
    cur = conn.cursor()
    cur.execute("DELETE FROM notes WHERE id = %s", (data['id'],))
    conn.commit()
    cur.close()
    conn.close()
    return jsonify({"status": "success"})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)