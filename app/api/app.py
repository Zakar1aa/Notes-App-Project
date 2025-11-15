from flask import Flask, request, jsonify
from flask_cors import CORS
import psycopg2
from psycopg2.extras import RealDictCursor
import os
import logging

app = Flask(__name__)
CORS(app)

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Database configuration
DB_HOST = os.getenv('DB_HOST', 'notes-db')
DB_PORT = os.getenv('DB_PORT', '5432')
DB_NAME = os.getenv('DB_NAME', 'notesdb')
DB_USER = os.getenv('DB_USER', 'notesuser')
DB_PASS = os.getenv('DB_PASS', 'notespass')

def get_db_connection():
    """Create a database connection"""
    try:
        conn = psycopg2.connect(
            host=DB_HOST,
            port=DB_PORT,
            database=DB_NAME,
            user=DB_USER,
            password=DB_PASS,
            cursor_factory=RealDictCursor
        )
        return conn
    except Exception as e:
        logger.error(f"Database connection error: {e}")
        raise

@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint"""
    return jsonify({"status": "healthy"}), 200

@app.route('/notes', methods=['GET'])
def get_notes():
    """Get all notes"""
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        
        cur.execute("SELECT id, note, created_at FROM notes ORDER BY created_at DESC")
        notes = cur.fetchall()
        
        cur.close()
        conn.close()
        
        return jsonify([dict(note) for note in notes]), 200
    except Exception as e:
        logger.error(f"Error fetching notes: {e}")
        return jsonify({"error": "Failed to fetch notes"}), 500

@app.route('/add', methods=['POST'])
def add_note():
    """Add a new note"""
    try:
        data = request.get_json()
        
        if not data or 'note' not in data:
            return jsonify({"error": "Note content is required"}), 400
        
        note_text = data['note'].strip()
        
        if not note_text:
            return jsonify({"error": "Note cannot be empty"}), 400
        
        conn = get_db_connection()
        cur = conn.cursor()
        
        cur.execute(
            "INSERT INTO notes (note) VALUES (%s) RETURNING id",
            (note_text,)
        )
        
        note_id = cur.fetchone()['id']
        conn.commit()
        
        cur.close()
        conn.close()
        
        logger.info(f"Note added successfully: {note_id}")
        return jsonify({"status": "success", "id": note_id}), 201
    except Exception as e:
        logger.error(f"Error adding note: {e}")
        return jsonify({"error": "Failed to add note"}), 500

@app.route('/delete', methods=['POST'])
def delete_note():
    """Delete a note"""
    try:
        data = request.get_json()
        
        if not data or 'id' not in data:
            return jsonify({"error": "Note ID is required"}), 400
        
        note_id = data['id']
        
        conn = get_db_connection()
        cur = conn.cursor()
        
        cur.execute("DELETE FROM notes WHERE id = %s RETURNING id", (note_id,))
        deleted = cur.fetchone()
        
        conn.commit()
        cur.close()
        conn.close()
        
        if deleted:
            logger.info(f"Note deleted successfully: {note_id}")
            return jsonify({"status": "success"}), 200
        else:
            return jsonify({"error": "Note not found"}), 404
    except Exception as e:
        logger.error(f"Error deleting note: {e}")
        return jsonify({"error": "Failed to delete note"}), 500

if __name__ == '__main__':
    logger.info("Starting NotesApp API...")
    logger.info(f"Database: {DB_HOST}:{DB_PORT}/{DB_NAME}")
    
    # Start Flask app
    app.run(host='0.0.0.0', port=5000, debug=False)
