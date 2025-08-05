# Deployment Guide for AutoPlanner.ai

This guide covers deploying the application to Heroku for both staging and production environments.

## Prerequisites

1. **Heroku CLI**: Install from https://devcenter.heroku.com/articles/heroku-cli
2. **Git**: Ensure your code is committed to git
3. **Heroku Account**: Sign up at https://heroku.com

## Initial Setup

1. **Login to Heroku**:
   ```bash
   heroku login
   ```

2. **Prepare the codebase**:
   ```bash
   # Ensure Gemfile.lock is up to date
   bundle install
   
   # Commit any changes
   git add .
   git commit -m "Prepare for deployment"
   ```

## Staging Deployment

### Quick Deploy
```bash
./deploy-staging.sh
```

### Manual Staging Setup
If you prefer to set up manually:

```bash
# Create staging app
heroku create autoplanner-staging --region us

# Add PostgreSQL and Redis
heroku addons:create heroku-postgresql:mini --app autoplanner-staging
heroku addons:create heroku-redis:mini --app autoplanner-staging

# Set environment variables
heroku config:set RAILS_ENV=production --app autoplanner-staging
heroku config:set SECRET_KEY_BASE=$(rails secret) --app autoplanner-staging

# Deploy
git push staging main

# Run migrations
heroku run rails db:migrate --app autoplanner-staging
```

## Production Deployment

### Quick Deploy
```bash
./deploy-production.sh
```

### Manual Production Setup
For manual setup:

```bash
# Create production app
heroku create autoplanner-production --region us

# Add PostgreSQL and Redis (larger instances)
heroku addons:create heroku-postgresql:standard-0 --app autoplanner-production
heroku addons:create heroku-redis:premium-0 --app autoplanner-production

# Enable production features
heroku features:enable preboot --app autoplanner-production
heroku pg:backups:schedule DATABASE_URL --at '02:00 America/Chicago' --app autoplanner-production

# Set environment variables
heroku config:set RAILS_ENV=production --app autoplanner-production
heroku config:set SECRET_KEY_BASE=$(rails secret) --app autoplanner-production

# Deploy
git push production main

# Run migrations
heroku run rails db:migrate --app autoplanner-production
```

## Environment Variables

### Required for both environments:
- `SECRET_KEY_BASE`: Rails secret key (auto-generated)
- `DATABASE_URL`: PostgreSQL connection (auto-set by Heroku)
- `REDIS_URL`: Redis connection (auto-set by Heroku)

### Application-specific:
```bash
# Staging
heroku config:set APP_DOMAIN=autoplanner-staging.herokuapp.com --app autoplanner-staging

# Production
heroku config:set APP_DOMAIN=autoplanner.ai --app autoplanner-production
```

### Optional (for future features):
```bash
# Email service
heroku config:set SENDGRID_API_KEY=your_key --app autoplanner-production

# SMS service
heroku config:set TWILIO_ACCOUNT_SID=your_sid --app autoplanner-production
heroku config:set TWILIO_AUTH_TOKEN=your_token --app autoplanner-production

# File storage
heroku config:set AWS_ACCESS_KEY_ID=your_key --app autoplanner-production
heroku config:set AWS_SECRET_ACCESS_KEY=your_secret --app autoplanner-production
heroku config:set AWS_BUCKET=your_bucket --app autoplanner-production
```

## Custom Domain Setup (Production)

1. **Add custom domain**:
   ```bash
   heroku domains:add autoplanner.ai --app autoplanner-production
   heroku domains:add www.autoplanner.ai --app autoplanner-production
   ```

2. **Configure DNS**:
   - Add CNAME record: `www` → `autoplanner-production.herokuapp.com`
   - Add ALIAS/ANAME record: `@` → `autoplanner-production.herokuapp.com`

3. **Enable SSL**:
   ```bash
   heroku certs:auto:enable --app autoplanner-production
   ```

## Database Management

### Backups
```bash
# Create manual backup
heroku pg:backups:capture --app autoplanner-production

# Download backup
heroku pg:backups:download --app autoplanner-production

# List backups
heroku pg:backups --app autoplanner-production
```

### Migrations
```bash
# Run pending migrations
heroku run rails db:migrate --app autoplanner-production

# Check migration status
heroku run rails db:migrate:status --app autoplanner-production
```

### Database Reset (STAGING ONLY!)
```bash
heroku pg:reset DATABASE_URL --app autoplanner-staging --confirm autoplanner-staging
heroku run rails db:migrate --app autoplanner-staging
heroku run rails db:seed --app autoplanner-staging
```

## Monitoring

### Logs
```bash
# Tail logs
heroku logs --tail --app autoplanner-production

# View recent logs
heroku logs -n 1000 --app autoplanner-production
```

### Performance
```bash
# View dyno status
heroku ps --app autoplanner-production

# Scale dynos
heroku ps:scale web=2 --app autoplanner-production
```

### Metrics
```bash
# Open metrics dashboard
heroku addons:open librato --app autoplanner-production
```

## Troubleshooting

### Application Errors
1. Check logs: `heroku logs --tail --app autoplanner-production`
2. Run console: `heroku run rails console --app autoplanner-production`
3. Check config: `heroku config --app autoplanner-production`

### Database Issues
1. Check connections: `heroku pg:info --app autoplanner-production`
2. Run diagnostics: `heroku pg:diagnose --app autoplanner-production`

### Performance Issues
1. Check memory: `heroku ps --app autoplanner-production`
2. Review metrics: `heroku metrics --app autoplanner-production`

## Rollback Procedure

If deployment causes issues:

```bash
# View releases
heroku releases --app autoplanner-production

# Rollback to previous version
heroku rollback --app autoplanner-production

# Or rollback to specific version
heroku rollback v123 --app autoplanner-production
```

## Security Checklist

- [ ] SECRET_KEY_BASE is unique per environment
- [ ] Force SSL is enabled in production
- [ ] Database backups are scheduled
- [ ] Error monitoring is configured
- [ ] Performance monitoring is active
- [ ] Custom domain SSL is enabled

## Deployment Checklist

Before each deployment:
- [ ] All tests pass locally
- [ ] Database migrations are tested
- [ ] Environment variables are set
- [ ] Recent database backup exists
- [ ] Team is notified of deployment

After deployment:
- [ ] Application loads correctly
- [ ] User can sign in
- [ ] Core features work
- [ ] No errors in logs
- [ ] Performance is acceptable