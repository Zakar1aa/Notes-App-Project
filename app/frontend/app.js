const API_URL = '/api';

async function loadNotes() {
    const response = await fetch(`${API_URL}/notes`);
    const notes = await response.json();
    // Display notes
}

async function addNote() {
    const note = document.getElementById('note-input').value;
    await fetch(`${API_URL}/add`, {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({note: note})
    });
    loadNotes();
}