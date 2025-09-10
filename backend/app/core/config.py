from pydantic_settings import BaseSettings
from typing import List, Optional
import os

class Settings(BaseSettings):
    API_V1_STR: str = "/v1"
    SECRET_KEY: str = os.getenv("SECRET_KEY", "your-secret-key-here")
    
    # Database
    DATABASE_URL: str = os.getenv("DATABASE_URL", "postgresql://postgres:password@localhost/contractor_billing")
    
    # Security
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 8  # 8 days
    ALGORITHM: str = "HS256"
    
    # CORS
    BACKEND_CORS_ORIGINS: List[str] = ["http://localhost:3000", "http://localhost:8080"]
    
    # Auth
    OIDC_CLIENT_ID: Optional[str] = os.getenv("OIDC_CLIENT_ID")
    OIDC_CLIENT_SECRET: Optional[str] = os.getenv("OIDC_CLIENT_SECRET")
    OIDC_ISSUER: Optional[str] = os.getenv("OIDC_ISSUER")
    
    # File Storage
    S3_BUCKET: Optional[str] = os.getenv("S3_BUCKET")
    S3_ACCESS_KEY: Optional[str] = os.getenv("S3_ACCESS_KEY")
    S3_SECRET_KEY: Optional[str] = os.getenv("S3_SECRET_KEY")
    S3_REGION: Optional[str] = os.getenv("S3_REGION", "us-east-1")
    
    # Webhooks
    WEBHOOK_SIGNING_SECRET: str = os.getenv("WEBHOOK_SIGNING_SECRET", "webhook-secret")
    
    # Celery/Redis
    REDIS_URL: str = os.getenv("REDIS_URL", "redis://localhost:6379/0")
    
    class Config:
        env_file = ".env"

settings = Settings()