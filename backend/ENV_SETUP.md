# Environment Configuration for Alpha

## Quick Setup

For development, copy the development environment file:
```bash
cp development.env .env
```

For production, copy and configure the production environment file:
```bash
cp production.env .env
# Then edit .env with your actual production values
```

## Environment Files

- `development.env` - Development environment template
- `production.env` - Production environment template (requires configuration)
- `.env` - Active environment (not tracked by git)

## Required Environment Variables

### Database
- `DATABASE_URL` - PostgreSQL connection string
- `REDIS_URL` - Redis connection string

### Security
- `SECRET_KEY` - JWT signing secret (generate new for production)
- `WEBHOOK_SIGNING_SECRET` - Webhook validation secret

### Optional: Authentication (Auth0)
- `OIDC_CLIENT_ID` - Auth0 client ID
- `OIDC_CLIENT_SECRET` - Auth0 client secret
- `OIDC_ISSUER` - Auth0 issuer URL

### Optional: File Storage (S3)
- `S3_BUCKET` - S3 bucket name
- `S3_ACCESS_KEY` - S3 access key
- `S3_SECRET_KEY` - S3 secret key
- `S3_REGION` - S3 region (default: us-east-1)

## Security Notes

⚠️ **Never commit actual credentials to git**
- Environment files ending in `.env` are excluded from git
- Always use placeholder values in template files
- Generate strong secrets for production
- Rotate secrets regularly

## Development vs Production

**Development (`development.env`)**:
- Uses local PostgreSQL and Redis
- Debug mode enabled
- Relaxed CORS settings

**Production (`production.env`)**:
- Uses managed database services
- Debug mode disabled
- Strict security settings
- All secrets must be configured