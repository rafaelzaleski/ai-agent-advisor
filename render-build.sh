#!/usr/bin/env bash
# exit on error
set -o errexit

# Initial setup
mix deps.get --only prod
MIX_ENV=prod mix compile

# Install frontend dependencies
npm install --prefix ./assets

# Build frontend assets
npm run deploy --prefix ./assets

# Compile production assets
MIX_ENV=prod mix phx.digest

# Build the release
MIX_ENV=prod mix release

# Run migrations (optional, can be run in a separate job)
_build/prod/rel/ai_agent_advisor/bin/ai_agent_advisor eval "AiAgentAdvisor.Release.migrate"
