from fastapi import FastAPI

app = FastAPI(title = "Child Nutrition API")

@app.get("/")
def root():
    return {"message": "Welcome to the Child Nutrition API!, API is running successfully."}

@app.get("/health")
def health():
    return {"status": "okay"}