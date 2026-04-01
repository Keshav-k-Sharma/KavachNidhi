from supabase import create_client, Client
from app.config import settings

# Auth client — used only for OTP and JWT verification
supabase: Client = create_client(settings.SUPABASE_URL, settings.SUPABASE_SERVICE_ROLE_KEY)

# Admin DB client — always uses service role, bypasses RLS for all table operations
db: Client = create_client(settings.SUPABASE_URL, settings.SUPABASE_SERVICE_ROLE_KEY)
