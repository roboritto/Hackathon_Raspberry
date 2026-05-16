from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import google.generativeai as genai
import firebase_admin
from firebase_admin import credentials, firestore
import os
from dotenv import load_dotenv
import json
from datetime import datetime # <--- We need this for the time math!

# Load environment variables
load_dotenv()

# Configure the Gemini API
genai.configure(api_key=os.getenv("GEMINI_API_KEY"))

# Configure Firebase
cred = credentials.Certificate("firebase-key.json")
firebase_admin.initialize_app(cred)

# Connect to Firestore Database
db = firestore.client()

app = FastAPI(title="IngatKu AI Backend")

class NotificationInput(BaseModel):
    raw_text: str

class ExtractedData(BaseModel):
    category: str
    location: str
    timestamp: datetime  # <--- Set to datetime so FastAPI processes it correctly
    summary: str

@app.post("/api/parse-notification", response_model=ExtractedData)
async def parse_notification(data: NotificationInput):
    try:
        # 1. Grab the exact time ONLY when a request actually arrives
        current_time_str = datetime.now().strftime("%A, %d %B %Y %H:%M:%S")

        # 2. Define the prompt INSIDE the endpoint so it grabs the fresh time
        system_prompt = f"""
        You are the backend AI for 'IngatKu', a Malaysian accessibility app for the elderly.
        Your job is to read raw smartphone notifications and extract the key information.

        CRITICAL CONTEXT: The current exact date and time is {current_time_str} (Malaysia Time).

        Categorize the notification into one of these: [Appointment, Medication, Bill, Family, Unknown].
        If a detail is missing, return "N/A".

        You MUST respond in pure JSON format with these exact keys:
        - "category": string
        - "location": string
        - "timestamp": string (Calculate the precise future date/time based on the current time provided above. Format strictly as ISO 8601: YYYY-MM-DDTHH:MM:SS)
        - "summary": string (Must explicitly state the event, exact date, and time. Format strictly like this: "[Event Name] [DD/MM/YYYY], pukul [Time]", e.g., "Appointment Ortologi 16/5/2026, pukul 9:00 pagi")
        """

        # 3. Initialize the model with the fresh instructions
        model = genai.GenerativeModel(
            model_name='gemini-2.5-flash',
            system_instruction=system_prompt,
            generation_config={"response_mime_type": "application/json"}
        )
        
        # 4. Generate the AI response
        response = model.generate_content(data.raw_text)
        
        # 5. Parse the JSON string
        result_json = json.loads(response.text)
        
        # 6. Convert the AI string to a real Python datetime object
        result_json["timestamp"] = datetime.fromisoformat(result_json["timestamp"])
        
        # 7. SAVE TO FIREBASE! (Saves as a native Firestore Timestamp)
        db.collection("reminders").add(result_json)
        
        # 8. Return to the Flutter App
        return result_json

    except json.JSONDecodeError:
        raise HTTPException(status_code=500, detail="Gemini did not return valid JSON.")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/")
async def root():
    return {"message": "IngatKu API is running and connected to Firebase!"}
