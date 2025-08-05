#!/bin/bash

# Heroku Staging Deployment Script
# Usage: ./deploy-staging.sh

set -e  # Exit on error

echo "=== AutoPlanner.ai Staging Deployment ==="
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
APP_NAME="autoplanner-staging"
HEROKU_REMOTE="staging"

echo "1. Checking Heroku app status..."
if ! heroku apps:info --app $APP_NAME &> /dev/null; then
    echo "   Creating Heroku app: $APP_NAME"
    heroku create $APP_NAME --region us
    heroku addons:create heroku-postgresql:essential-0 --app $APP_NAME
    heroku addons:create heroku-redis:mini --app $APP_NAME || heroku addons:create heroku-redis:premium-0 --app $APP_NAME
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
echo "3. Setting environment variables..."
heroku config:set RAILS_ENV=production --app $APP_NAME
heroku config:set RACK_ENV=production --app $APP_NAME
heroku config:set RAILS_LOG_TO_STDOUT=enabled --app $APP_NAME
heroku config:set RAILS_SERVE_STATIC_FILES=true --app $APP_NAME
heroku config:set WEB_CONCURRENCY=2 --app $APP_NAME
heroku config:set RAILS_MAX_THREADS=5 --app $APP_NAME

# Generate secret key if not already set
if ! heroku config:get SECRET_KEY_BASE --app $APP_NAME &> /dev/null; then
    echo "   Generating SECRET_KEY_BASE..."
    SECRET_KEY=$(rails secret)
    heroku config:set SECRET_KEY_BASE=$SECRET_KEY --app $APP_NAME
else
    echo "   SECRET_KEY_BASE already set"
fi

# Set application-specific config
heroku config:set APP_DOMAIN="autoplanner-staging.herokuapp.com" --app $APP_NAME
heroku config:set MAILER_HOST="autoplanner-staging.herokuapp.com" --app $APP_NAME

echo ""
echo "4. Installing Heroku buildpacks..."
heroku buildpacks:set heroku/ruby --app $APP_NAME

echo ""
echo "5. Checking for pending migrations locally..."
if ! rails db:migrate:status | grep -q "down"; then
    echo "   No pending migrations"
else
    echo "   Warning: You have pending migrations locally"
    echo "   They will be run on Heroku after deployment"
fi

echo ""
echo "6. Running tests..."
if command -v rspec &> /dev/null; then
    echo "   Running RSpec tests..."
    if ! bundle exec rspec --fail-fast; then
        echo "   Tests failed! Fix them before deploying."
        exit 1
    fi
else
    echo "   Skipping tests (RSpec not found)"
fi

echo ""
echo "7. Checking for uncommitted changes..."
if [[ -n $(git status -s) ]]; then
    echo "   Warning: You have uncommitted changes"
    git status -s
    echo ""
    read -p "   Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "   Deployment cancelled"
        exit 1
    fi
fi

echo ""
echo "8. Deploying to Heroku staging..."
git push $HEROKU_REMOTE main:main

echo ""
echo "9. Running post-deployment tasks..."
heroku run rails db:seed --app $APP_NAME || true  # Don't fail if seeds already exist

echo ""
echo "10. Checking deployment..."
heroku ps --app $APP_NAME
heroku logs --tail --app $APP_NAME &
LOGS_PID=$!

echo ""
echo "=== Deployment Complete! ==="
echo ""
echo "App URL: https://$APP_NAME.herokuapp.com"
echo "To open: heroku open --app $APP_NAME"
echo "To view logs: heroku logs --tail --app $APP_NAME"
echo ""
echo "Press Ctrl+C to stop tailing logs..."

wait $LOGS_PID