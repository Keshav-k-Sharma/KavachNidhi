from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    SUPABASE_URL: str
    SUPABASE_SERVICE_ROLE_KEY: str
    SUPABASE_STORAGE_BUCKET: str = "kyc-documents"

    # Comma-separated E.164 phones allowed to call admin / manual settlement APIs.
    ADMIN_PHONES: str = ""

    RAZORPAY_KEY_ID: str = ""
    RAZORPAY_KEY_SECRET: str = ""
    RAZORPAY_WEBHOOK_SECRET: str = ""

    OPENWEATHERMAP_API_KEY: str = ""
    TOMTOM_API_KEY: str = ""

    USE_MOCK_PAYMENTS: bool = False
    USE_MOCK_WEATHER: bool = False
    USE_MOCK_TRAFFIC: bool = False

    KAVACHBRAIN_INTERVAL_SECONDS: int = 60

    class Config:
        env_file = ".env"


settings = Settings()
