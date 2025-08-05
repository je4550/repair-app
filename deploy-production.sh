#!/bin/bash

# Heroku Production Deployment Script
# Usage: ./deploy-production.sh

set -e  # Exit on error

echo "=== AutoPlanner.ai PRODUCTION Deployment ==="
echo ""

# Check if we're in the right directory
if [ ! -f "Gemfile" ]; then
    echo "Error: Must run from Rails app root directory"
    exit 1
fi

# Check if heroku CLI is installed
if ! command -v heroku &> /dev/null; then
    echo "Error: Heroku CLI not found. Please install it first:"
    echo "https://devcenter.heroku.com/articles/heroku-cli"
    exit 1
fi

# Configuration
APP_NAME="autoplanner-production"
HEROKU_REMOTE="production"
STAGING_APP="autoplanner-staging"

# Safety check - confirm production deployment
echo "⚠️  WARNING: You are about to deploy to PRODUCTION!"
echo ""
read -p "Are you sure you want to continue? Type 'DEPLOY PRODUCTION' to confirm: " -r
echo
if [[ ! $REPLY == "DEPLOY PRODUCTION" ]]; then
    echo "Deployment cancelled"
    exit 1
fi

echo ""
echo "1. Checking Heroku app status..."
if ! heroku apps:info --app $APP_NAME &> /dev/null; then
    echo "   Creating Heroku app: $APP_NAME"
    heroku create $APP_NAME --region us
    
    # Production uses larger resources
    heroku addons:create heroku-postgresql:essential-2 --app $APP_NAME  # $20/month for production
    heroku addons:create heroku-redis:premium-0 --app $APP_NAME
else
    echo "   App $APP_NAME already exists"
fi

echo ""
echo "2. Setting up Git remote..."
if ! git remote | grep -q "^${HEROKU_REMOTE}$"; then
    heroku git:remote -a $APP_NAME -r $HEROKU_REMOTE
    echo "   Added remote: $HEROKU_REMOTE"
else
    echo "   Remote $HEROKU_REMOTE already exists"
fi

echo ""
echo "3. Checking staging deployment..."
if heroku apps:info --app $STAGING_APP &> /dev/null; then
    STAGING_RELEASE=$(heroku releases --app $STAGING_APP --num 1 --json | grep -o '"version":[0-9]*' | grep -o '[0-9]*')
    echo "   Staging is at release v$STAGING_RELEASE"
    
    # Get staging commit hash
    STAGING_COMMIT=$(heroku releases:info v$STAGING_RELEASE --app $STAGING_APP --json | grep -o '"commit":"[^"]*"' | cut -d'"' -f4)
    echo "   Staging commit: $STAGING_COMMIT"
    
    # Check if current branch matches staging
    CURRENT_COMMIT=$(git rev-parse HEAD)
    if [[ "$CURRENT_COMMIT" != "$STAGING_COMMIT"* ]]; then
        echo ""
        echo "   ⚠️  Warning: Your current commit doesn't match staging!"
        echo "   Current: $CURRENT_COMMIT"
        echo "   Staging: $STAGING_COMMIT"
        echo ""
        read -p "   Deploy anyway? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "   Deployment cancelled"
            exit 1
        fi
    fi
else
    echo "   Warning: Staging app not found. Proceeding anyway..."
fi

echo ""
echo "4. Setting environment variables..."
heroku config:set RAILS_ENV=production --app $APP_NAME
heroku config:set RACK_ENV=production --app $APP_NAME
heroku config:set RAILS_LOG_TO_STDOUT=enabled --app $APP_NAME
heroku config:set RAILS_SERVE_STATIC_FILES=true --app $APP_NAME
heroku config:set WEB_CONCURRENCY=3 --app $APP_NAME
heroku config:set RAILS_MAX_THREADS=5 --app $APP_NAME

# Production-specific settings
heroku config:set RAILS_LOG_LEVEL=info --app $APP_NAME
heroku config:set DATABASE_POOL=25 --app $APP_NAME

# Generate secret key if not already set
if ! heroku config:get SECRET_KEY_BASE --app $APP_NAME &> /dev/null; then
    echo "   Generating SECRET_KEY_BASE..."
    SECRET_KEY=$(rails secret)
    heroku config:set SECRET_KEY_BASE=$SECRET_KEY --app $APP_NAME
else
    echo "   SECRET_KEY_BASE already set"
fi

# Set application-specific config (UPDATE THESE!)
heroku config:set APP_DOMAIN="autoplanner.ai" --app $APP_NAME
heroku config:set MAILER_HOST="autoplanner.ai" --app $APP_NAME

echo ""
echo "5. Installing Heroku buildpacks..."
heroku buildpacks:set heroku/ruby --app $APP_NAME

echo ""
echo "6. Enabling production features..."
# Enable preboot for zero-downtime deploys
heroku features:enable preboot --app $APP_NAME || true

# Set up automated backups
heroku pg:backups:schedule DATABASE_URL --at '02:00 America/Chicago' --app $APP_NAME || true

echo ""
echo "7. Creating database backup before deployment..."
heroku pg:backups:capture --app $APP_NAME || echo "   No existing database to backup"

echo ""
echo "8. Final confirmation..."
echo ""
echo "You are about to deploy to PRODUCTION!"
echo "App: $APP_NAME"
echo "Domain: autoplanner.ai"
echo ""
read -p "Type 'YES' to proceed with deployment: " -r
echo
if [[ ! $REPLY == "YES" ]]; then
    echo "Deployment cancelled"
    exit 1
fi

echo ""
echo "9. Deploying to Heroku production..."
git push $HEROKU_REMOTE main:main

echo ""
echo "10. Running post-deployment tasks..."
# Run migrations
heroku run rails db:migrate --app $APP_NAME

# Clear cache
heroku run rails tmp:cache:clear --app $APP_NAME || true

echo ""
echo "11. Checking deployment..."
heroku ps --app $APP_NAME

echo ""
echo "12. Running health check..."
sleep 10  # Give app time to start

# Check if app is responding
APP_URL="https://$APP_NAME.herokuapp.com"
if curl -s -o /dev/null -w "%{http_code}" $APP_URL | grep -q "200\|301\|302"; then
    echo "   ✅ App is responding successfully!"
else
    echo "   ⚠️  Warning: App may not be responding correctly"
    echo "   Check logs: heroku logs --tail --app $APP_NAME"
fi

echo ""
echo "=== Production Deployment Complete! ==="
echo ""
echo "App URL: https://$APP_NAME.herokuapp.com"
echo "Custom Domain: https://autoplanner.ai (configure DNS separately)"
echo ""
echo "Post-deployment checklist:"
echo "  □ Test user login"
echo "  □ Test critical features"
echo "  □ Monitor error rates: heroku logs --tail --app $APP_NAME"
echo "  □ Check performance: heroku ps --app $APP_NAME"
echo "  □ Verify database: heroku pg:info --app $APP_NAME"
echo ""
echo "To rollback if needed: heroku rollback --app $APP_NAME"