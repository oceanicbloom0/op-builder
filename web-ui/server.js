const express = require('express');
const cors = require('cors');
const path = require('path');
const fs = require('fs');
const { Octokit } = require('@octokit/rest');

const app = express();
const PORT = process.env.PORT || 3000;

const octokit = new Octokit({
  auth: process.env.GITHUB_TOKEN
});

app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname)));

app.get('/api/devices', (req, res) => {
    try {
        const configDir = path.join(__dirname, '..', 'configs');
        const devices = [];

        if (fs.existsSync(configDir)) {
            const items = fs.readdirSync(configDir, { withFileTypes: true });

            items.forEach(item => {
                if (item.isDirectory() && item.name !== 'STANDALONE_CONF') {
                    devices.push(item.name);
                }
            });

            const standaloneDir = path.join(configDir, 'STANDALONE_CONF');
            if (fs.existsSync(standaloneDir)) {
                const standaloneItems = fs.readdirSync(standaloneDir, { withFileTypes: true });
                standaloneItems.forEach(item => {
                    if (item.isDirectory()) {
                        devices.push(item.name);
                    }
                });
            }
        }

        res.json(devices.sort());
    } catch (error) {
        console.error('Error loading devices:', error);
        res.status(500).json({ error: '无法加载设备列表' });
    }
});

app.post('/api/build/start', async (req, res) => {
    try {
        const {
            openwrtSource,
            openwrtBranch,
            configPath,
            device,
            enableSSH,
            onlySSH,
            enableCloudflared,
            sshDevice
        } = req.body;

        console.log('Starting build with parameters:', {
            openwrtSource,
            openwrtBranch,
            configPath,
            device,
            enableSSH,
            onlySSH,
            enableCloudflared,
            sshDevice
        });

        if (!process.env.GITHUB_TOKEN) {
            throw new Error('GITHUB_TOKEN environment variable is required');
        }

        const [owner, repo] = process.env.GITHUB_REPOSITORY?.split('/') || ['', ''];

        if (!owner || !repo) {
            throw new Error('GITHUB_REPOSITORY environment variable is required');
        }

        const workflowInputs = {
            openwrt_source: openwrtSource,
            openwrt_source_branch: openwrtBranch,
            app_config_path: configPath,
            ssh: enableSSH.toString(),
            only_ssh: onlySSH.toString(),
            running_ssh_device: sshDevice,
            cloudflared: enableCloudflared.toString()
        };

        const response = await octokit.actions.createWorkflowDispatch({
            owner,
            repo,
            workflow_id: 'build-openwrt_main.yml',
            ref: 'master',
            inputs: workflowInputs
        });

        console.log('Workflow triggered successfully:', response.status);

        res.json({
            message: '编译已启动',
            buildId: Date.now().toString(),
            workflowRunId: response.data.id,
            status: 'triggered'
        });

    } catch (error) {
        console.error('Error triggering workflow:', error);
        res.status(500).json({
            error: '启动编译失败',
            details: error.message
        });
    }
});

app.get('/api/build/logs', async (req, res) => {
    res.setHeader('Content-Type', 'text/plain; charset=utf-8');
    res.setHeader('Cache-Control', 'no-cache');
    res.setHeader('Connection', 'keep-alive');

    const { runId } = req.query;

    if (!runId) {
        res.status(400).send('runId parameter is required');
        return;
    }

    if (!process.env.GITHUB_TOKEN) {
        res.status(500).send('GITHUB_TOKEN environment variable is required');
        return;
    }

    const [owner, repo] = process.env.GITHUB_REPOSITORY?.split('/') || ['', ''];

    try {
        const logs = await octokit.actions.listWorkflowRunLogs({
            owner,
            repo,
            run_id: parseInt(runId)
        });

        if (logs.data.artifacts && logs.data.artifacts.length > 0) {
            const logArtifact = logs.data.artifacts.find(a => a.name.includes('log'));
            if (logArtifact) {
                const logDownload = await octokit.actions.downloadArtifact({
                    owner,
                    repo,
                    artifact_id: logArtifact.id,
                    archive_format: 'zip'
                });

                res.write('下载日志文件...\n');
                res.end();
                return;
            }
        }

        res.write('正在获取实时日志...\n');
        res.write('请稍后查看 GitHub Actions 页面获取完整日志\n');
        res.end();

    } catch (error) {
        console.error('Error fetching logs:', error);
        res.write('无法获取实时日志，请查看 GitHub Actions 页面\n');
        res.end();
    }
});

app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'index.html'));
});

app.listen(PORT, () => {
    console.log(`Web UI server running on http://localhost:${PORT}`);
    console.log('OpenWRT 编译控制台已启动');
});