from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import google.generativeai as genai
import firebase_admin
from firebase_admin import credentials, firestore
import os
from dotenv import load_dotenv
import json

# Load environment variables
load_dotenv()

# Configure the Gemini API
genai.configure(api_key=os.getenv("GEMINI_API_KEY"))

# Configure Firebase
# This looks for the JSON key file you just downloaded
cred = credentials.Certificate("firebase-key.json")
firebase_admin.initialize_app(cred)

# Connect to Firestore Database
db = firestore.client()

# Define the system prompt
system_prompt = """
You are the backend AI for 'IngatKu', a Malaysian accessibility app for the elderly.
Your job is to read raw smartphone notifications and extract the key information.

Categorize the notification into one of these: [Appointment, Medication, Bill, Family, Unknown].
If a detail is missing, return "N/A" for that field.
Keep the summary under 10 words, using simple language (mix of simple English/Malay is okay).

You MUST respond in pure JSON format with these exact keys: "category", "location", "time", "summary".
"""

# Initialize the Gemini model
model = genai.GenerativeModel(
    model_name='gemini-2.5-flash',
    system_instruction=system_prompt,
    generation_config={"response_mime_type": "application/json"}
)

app = FastAPI(title="IngatKu AI Backend")

class NotificationInput(BaseModel):
    raw_text: str

class ExtractedData(BaseModel):
    category: str
    location: str
    time: str
    summary: str

@app.post("/api/parse-notification", response_model=ExtractedData)
async def parse_notification(data: NotificationInput):
    try:
        # 1. Call the Gemini model
        response = model.generate_content(data.raw_text)
        
        # 2. Parse the JSON string
        result_json = json.loads(response.text)
        
        # 3. SAVE TO FIREBASE!
        # This creates a new collection called "reminders" (if it doesn't exist)
        # and adds a new document with the AI's extracted data.
        db.collection("reminders").add(result_json)
        
        # 4. Return the result to the frontend
        return result_json

    except json.JSONDecodeError:
        raise HTTPException(status_code=500, detail="Gemini did not return valid JSON.")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/")
async def root():
    return {"message": "IngatKu API is running and connected to Firebase!"}