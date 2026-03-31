from fastapi import FastAPI


app = FastAPI()

@app.get("/")
def root():
    return {"success": True, "data": "KavachNidhi backend is live", "error": None}