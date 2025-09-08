# LHI Sync Dashboard

## Overview
Multi-environment synchronization dashboard for managing the LHI Scripts ecosystem across multiple machines and environments.

## Features
- 🔄 Real-time synchronization status monitoring
- 🖥️ Multi-environment support (Main Mac, MyBambu, DigitalOcean)
- 📦 Submodule tracking and status
- 📋 Manual sync instructions
- 🎨 LHI UI Framework with branding

## Quick Start

### Local Development
```bash
cd lhi_modules/lhi_node_modules/lhi_sync_dashboard
npm install
npm start
```
Access at: http://localhost:7001

### Deploy to DigitalOcean
```bash
# Copy to DigitalOcean
rsync -av ./lhi_sync_dashboard/ user@digitalocean:/var/www/sync-dashboard/

# On DigitalOcean
cd /var/www/sync-dashboard
npm install
npm start
```

## Manual Synchronization Process

### 1. Check Status
```bash
git status                          # Check uncommitted changes
git branch --show-current           # Verify branch
git submodule status                # Check submodules
```

### 2. Commit Changes
```bash
git add [files]                     # Stage changes
git commit -m "Description"         # Commit
```

### 3. Push to Remote
```bash
git push origin develop             # Push main repo
```

### 4. Pull on Other Environments
```bash
git pull origin develop             # Pull latest
git submodule update --init --recursive  # Update submodules
```

### 5. Verify Submodules
```bash
git submodule foreach git status    # Check each submodule
git submodule foreach git pull origin master  # Update to latest
```

## Environment Detection

The dashboard automatically detects:
- **Main Mac**: patrickwatsonlhi @ LHI-Mac
- **MyBambu**: patrickwatson @ MyBambu  
- **DigitalOcean**: Linux with devbox hostname
- **Other**: Unknown environments

## Architecture

- Node.js/Express backend for data collection
- LHI UI Framework for frontend
- Real-time git status monitoring
- Auto-refresh every 30 seconds

## API Endpoints

- `GET /api/sync-status` - Current environment status
- `GET /api/all-environments` - All known environments
- `GET /api/submodules` - Submodule status

## Configuration

Port: 7001 (LHI port range)
Auto-refresh: 30 seconds