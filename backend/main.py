import json
import os
import pymupdf
import requests
import time
from dotenv import load_dotenv
from fastapi import FastAPI, File, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware

load_dotenv()

GEMINI_KEY = os.getenv("GEMINI_API_KEY")
SERPAPI_KEY = os.getenv("SERPAPI_KEY")
GEMINI_MODEL = os.getenv("GEMINI_MODEL", "gemini-3.1-flash-lite")

GEMINI_URL = (
    f"https://generativelanguage.googleapis.com/v1beta/"
    f"models/{GEMINI_MODEL}:generateContent"
)

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


def ask_gemini(prompt):
    body = {
        "contents": [{"parts": [{"text": prompt}]}],
        "generationConfig": {"responseMimeType": "application/json"},
    }

    for attempt in range(4):
        response = requests.post(
            GEMINI_URL, json=body, headers={"x-goog-api-key": GEMINI_KEY}, timeout=90
        )
        if response.status_code not in (429, 503):
            break
        time.sleep(3)

    if response.status_code != 200:
        print(response.status_code, response.text)
        raise HTTPException(502, "Gemini error: " + response.text[:150])

    try:
        text = response.json()["candidates"][0]["content"]["parts"][0]["text"]
        return json.loads(text)
    except Exception:
        raise HTTPException(502, "Invalid response from Gemini")


def search_patents(query):
    response = requests.get(
    "https://www.searchapi.io/api/v1/search",
    params={
        "engine": "google_patents",
        "q": query,
    },
    headers={
        "Authorization": f"Bearer {SERPAPI_KEY}"
    },
    timeout=60,
)
    if response.status_code != 200:
        print(response.status_code, response.text)
        return []

    patents = []
    for item in response.json().get("organic_results", [])[:5]:
        patent_id = item.get("patent_id", "")
        patents.append(
            {
                "id": item.get("publication_number") or patent_id,
                "title": item.get("title", ""),
                "snippet": item.get("snippet", ""),
                "link": "https://patents.google.com/" + patent_id,
            }
        )
    return patents


@app.get("/")
def home():
    return {"message": "API is running"}


@app.post("/analyze")
def analyze(file: UploadFile = File(...)):
    data = file.file.read()
    if not data.startswith(b"%PDF"):
        raise HTTPException(400, "Only PDF files are allowed")

    try:
        doc = pymupdf.open(stream=data, filetype="pdf")
    except Exception:
        raise HTTPException(400, "Could not open PDF")

    text = ""
    for page in doc:
        text += page.get_text()
    doc.close()

    if not text.strip():
        raise HTTPException(400, "No text found in PDF")

    info = ask_gemini(
        "Read this invention document and return only JSON with the keys: "
        '"title" (string), "summary" (3 sentences), '
        '"search_queries" (list of 2 short English queries for Google Patents).\n\n'
        + text[:30000]
    )

    patents = []
    for query in info.get("search_queries", [])[:2]:
        patents += search_patents(query)

    result = ask_gemini(
        "You are a patent examiner assistant. Compare the invention with the "
        "prior art and estimate its patentability. Return only JSON with the keys: "
        '"score" (0-100), "novelty" (0-100), "inventive_step" (0-100), '
        '"verdict" ("Low", "Medium" or "High"), "reasoning" (4 sentences), '
        '"recommendations" (list of 3 short strings).\n\n'
        "Invention: " + json.dumps(info) + "\n\n"
        "Prior art: " + json.dumps(patents)
    )

    return {
        "title": info.get("title", ""),
        "summary": info.get("summary", ""),
        "score": int(result.get("score", 0)),
        "novelty": int(result.get("novelty", 0)),
        "inventive_step": int(result.get("inventive_step", 0)),
        "verdict": result.get("verdict", ""),
        "reasoning": result.get("reasoning", ""),
        "recommendations": result.get("recommendations", []),
        "similar_patents": patents[:5],
    }