# hackathon1.py — COMPLETE SINGLE FILE

from flask import Flask, request, jsonify
from flask_cors import CORS
from dotenv import load_dotenv
import firebase_admin
from firebase_admin import credentials, firestore, messaging as fcm
import google.generativeai as genai
from apscheduler.schedulers.background import BackgroundScheduler
from datetime import datetime, timedelta
import json
import os

load_dotenv()

# ─── Firebase Setup ────────────────────────────────────────
cred = credentials.Certificate("C:/Users/edenz/Downloads/ingatku-bc503-firebase-adminsdk-fbsvc-0345addc88.json")
firebase_admin.initialize_app(cred)
db = firestore.client()

# ─── Gemini Setup ──────────────────────────────────────────
genai.configure(api_key=os.getenv('GEMINI_API_KEY'))
model = genai.GenerativeModel('gemini-1.5-flash')

# ─── Flask Setup ───────────────────────────────────────────
app = Flask(__name__)
CORS(app)

# ─── AI Function ───────────────────────────────────────────
def extract_reminder_from_text(text: str) -> dict:
    prompt = f"""
        You are a reminder extraction assistant for elderly Malaysians.
        Extract reminder info from this notification text.

        Notification: "{text}"

        Reply ONLY in JSON format, no extra text, no markdown:
        {{
            "isReminder": true or false,
            "type": "appointment/medication/bill/other",
            "title": "short title",
            "description": "brief description in simple BM or English",
            "datetime": "ISO datetime string or null"
        }}
    """
    response = model.generate_content(prompt)
    raw      = response.text
    clean    = raw.replace('```json', '').replace('```', '').strip()
    return json.loads(clean)

# ─── Scheduler Function ────────────────────────────────────
def check_reminders():
    now  = datetime.now()
    soon = now + timedelta(minutes=5)

    docs = db.collection('reminders').where('acknowledged', '==', False).stream()

    for doc in docs:
        r    = doc.to_dict()
        r_dt = r.get('datetime')

        if r_dt and now <= r_dt <= soon:
            user  = db.collection('users').document(r['userId']).get().to_dict()
            token = user.get('fcmToken')

            if token:
                message = fcm.Message(
                    notification=fcm.Notification(
                        title=f"⏰ Peringatan: {r['title']}",
                        body=r.get('description', '')
                    ),
                    token=token,
                )
                fcm.send(message)
                print(f"✅ Notified: {r['title']}")

# ─── Routes: Users ─────────────────────────────────────────
@app.route('/api/users', methods=['POST'])
def create_user():
    try:
        data    = request.json
        user    = {
            'name':      data['name'],
            'age':       data['age'],
            'language':  data.get('language', 'BM'),
            'familyId':  data.get('familyId', None),
            'fcmToken':  data.get('fcmToken', None),
            'createdAt': datetime.now()
        }
        doc_ref = db.collection('users').add(user)
        return jsonify({'success': True, 'id': doc_ref[1].id})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


@app.route('/api/users/<user_id>/fcm-token', methods=['PATCH'])
def update_fcm(user_id):
    try:
        db.collection('users').document(user_id).update({
            'fcmToken': request.json['fcmToken']
        })
        return jsonify({'success': True})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

# ─── Routes: Reminders ─────────────────────────────────────
@app.route('/api/reminders/<user_id>', methods=['GET'])
def get_reminders(user_id):
    try:
        docs      = (
            db.collection('reminders')
            .where('userId', '==', user_id)
            .where('acknowledged', '==', False)
            .stream()
        )
        reminders = [{'id': doc.id, **doc.to_dict()} for doc in docs]
        return jsonify({'success': True, 'reminders': reminders})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


@app.route('/api/reminders', methods=['POST'])
def create_reminder():
    try:
        data     = request.json
        reminder = {
            'userId':       data['userId'],
            'type':         data['type'],
            'title':        data['title'],
            'description':  data['description'],
            'datetime':     datetime.fromisoformat(data['datetime']),
            'acknowledged': False,
            'createdFrom':  'manual',
            'createdAt':    datetime.now()
        }
        doc_ref  = db.collection('reminders').add(reminder)
        return jsonify({'success': True, 'id': doc_ref[1].id})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


@app.route('/api/reminders/<reminder_id>/acknowledge', methods=['PATCH'])
def acknowledge(reminder_id):
    try:
        db.collection('reminders').document(reminder_id).update({
            'acknowledged': True
        })
        return jsonify({'success': True})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

# ─── Routes: Medications ───────────────────────────────────
@app.route('/api/medications/<user_id>', methods=['GET'])
def get_medications(user_id):
    try:
        docs = (
            db.collection('medications')
            .where('userId', '==', user_id)
            .stream()
        )
        meds = [{'id': doc.id, **doc.to_dict()} for doc in docs]
        return jsonify({'success': True, 'medications': meds})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


@app.route('/api/medications', methods=['POST'])
def add_medication():
    try:
        data    = request.json
        med     = {
            'userId':    data['userId'],
            'name':      data['name'],
            'dosage':    data['dosage'],
            'schedule':  data['schedule'],
            'streak':    0,
            'lastTaken': None,
            'createdAt': datetime.now()
        }
        doc_ref = db.collection('medications').add(med)
        return jsonify({'success': True, 'id': doc_ref[1].id})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


@app.route('/api/medications/<med_id>/taken', methods=['PATCH'])
def mark_taken(med_id):
    try:
        med_ref = db.collection('medications').document(med_id)
        med     = med_ref.get().to_dict()
        med_ref.update({
            'lastTaken': datetime.now(),
            'streak':    med.get('streak', 0) + 1
        })
        return jsonify({'success': True, 'message': 'Medication marked as taken'})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

# ─── Routes: Notifications ─────────────────────────────────
@app.route('/api/notifications/process', methods=['POST'])
def handle_notification():
    try:
        data      = request.json
        user_id   = data['userId']
        raw_text  = f"{data['notificationTitle']} — {data['notificationText']}"
        extracted = extract_reminder_from_text(raw_text)

        if extracted.get('isReminder'):
            db.collection('reminders').add({
                'userId':       user_id,
                'type':         extracted.get('type'),
                'title':        extracted.get('title'),
                'description':  extracted.get('description'),
                'datetime':     datetime.fromisoformat(extracted['datetime'])
                                if extracted.get('datetime') else None,
                'acknowledged': False,
                'createdFrom':  'notification',
                'createdAt':    datetime.now()
            })

        return jsonify({'success': True, 'result': extracted})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

# ─── Start Everything ──────────────────────────────────────
if __name__ == '__main__':
    scheduler = BackgroundScheduler()
    scheduler.add_job(check_reminders, 'interval', minutes=1)
    scheduler.start()
    print("✅ Scheduler started")
    app.run(debug=True, port=3000)