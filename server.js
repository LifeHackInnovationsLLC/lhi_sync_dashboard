const express = require('express');
const { exec } = require('child_process');
const path = require('path');
const fs = require('fs');

const app = express();
// Port MUST come from environment (set by launch.sh from port_registry)
// Single source of truth: PocketBase port_registry collection
if (!process.env.PORT) {
    console.error('Error: PORT environment variable not set. Use ./launch.sh to start this service.');
    process.exit(1);
}
const PORT = process.env.PORT;

app.use(express.static('public'));
app.use(express.json());

// API endpoint to get sync status
app.get('/api/sync-status', async (req, res) => {
    try {
        const status = await getSyncStatus();
        res.json(status);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

async function getSyncStatus() {
    return new Promise((resolve, reject) => {
        const os = require('os');
        const homeDir = os.homedir();
        const lhiScriptsRoot = process.env.LHI_SCRIPTS_ROOT || path.join(homeDir, 'lhi_scripts');
        
        exec(`cd ${lhiScriptsRoot} && git status --porcelain && git branch --show-current && git log --oneline -5`, 
            (error, stdout, stderr) => {
                if (error) {
                    reject(error);
                    return;
                }
                
                const lines = stdout.split('\n');
                const statusLines = [];
                const branches = [];
                const commits = [];
                
                let currentSection = 'status';
                lines.forEach(line => {
                    if (line.includes('* ')) {
                        currentSection = 'branch';
                        branches.push(line);
                    } else if (line.match(/^[a-f0-9]{7,}/)) {
                        currentSection = 'commits';
                        commits.push(line);
                    } else if (line.trim() && currentSection === 'status') {
                        statusLines.push(line);
                    }
                });
                
                // Detect environment
                const hostname = require('os').hostname();
                const username = require('os').userInfo().username;
                const platform = require('os').platform();
                
                let environment = 'UNKNOWN';
                if (platform === 'darwin') {
                    if (username === 'patrickwatsonlhi' && hostname.includes('LHI-Mac')) {
                        environment = 'MAIN_MAC';
                    } else if (username === 'patrickwatson' && hostname.includes('MyBambu')) {
                        environment = 'MYBAMBU_MAC';
                    } else {
                        environment = 'OTHER_MAC';
                    }
                } else if (platform === 'linux') {
                    if (hostname.includes('devbox') || fs.existsSync('/var/www/lifehackinnovations')) {
                        environment = 'DIGITALOCEAN_LINUX';
                    } else {
                        environment = 'OTHER_LINUX';
                    }
                }
                
                resolve({
                    environment,
                    platform,
                    hostname,
                    username,
                    uncommittedChanges: statusLines.length,
                    changedFiles: statusLines,
                    currentBranch: branches[0] || 'unknown',
                    recentCommits: commits.slice(0, 5),
                    syncStatus: determineSyncStatus(environment, statusLines.length),
                    timestamp: new Date().toISOString()
                });
            });
    });
}

function determineSyncStatus(environment, uncommittedChanges) {
    if (uncommittedChanges > 0) {
        return { status: 'DIRTY', message: 'Has uncommitted changes', color: '#ff6b35' };
    }
    
    // Check if we're on correct branch for environment
    switch (environment) {
        case 'MAIN_MAC':
            return { status: 'SYNCED', message: 'Main development environment ready', color: '#4CAF50' };
        case 'MYBAMBU_MAC':
            return { status: 'SYNCED', message: 'MyBambu environment ready', color: '#4CAF50' };
        case 'DIGITALOCEAN_LINUX':
            return { status: 'PRODUCTION', message: 'Production environment active', color: '#2196F3' };
        default:
            return { status: 'UNKNOWN', message: 'Environment needs verification', color: '#FFC107' };
    }
}

app.listen(PORT, () => {
    console.log(`LHI Sync Dashboard running at http://localhost:${PORT}`);
    console.log('Dashboard shows real-time sync status for all environments');
});