class BuildController {
    constructor() {
        this.buildSteps = [
            '环境初始化',
            '源码检出',
            '依赖安装',
            '配置生成',
            '编译准备',
            '核心编译',
            '软件包编译',
            '固件生成',
            '打包完成'
        ];

        this.currentStep = 0;
        this.isBuilding = false;

        this.initializeEventListeners();
        this.loadAvailableDevices();
    }

    initializeEventListeners() {
        const form = document.getElementById('buildForm');
        const enableSSH = document.getElementById('enableSSH');
        const onlySSH = document.getElementById('onlySSH');
        const sshDeviceGroup = document.getElementById('sshDeviceGroup');

        form.addEventListener('submit', (e) => this.startBuild(e));

        enableSSH.addEventListener('change', () => {
            sshDeviceGroup.style.display = enableSSH.checked ? 'block' : 'none';
        });

        onlySSH.addEventListener('change', () => {
            if (onlySSH.checked) {
                enableSSH.checked = true;
                sshDeviceGroup.style.display = 'block';
            }
        });
    }

    async loadAvailableDevices() {
        try {
            const response = await fetch('/api/devices');
            const devices = await response.json();

            const select = document.getElementById('device');
            devices.forEach(device => {
                const option = document.createElement('option');
                option.value = device;
                option.textContent = device;
                select.appendChild(option);
            });
        } catch (error) {
            this.log('无法加载设备列表，请确保后端服务正常运行');
        }
    }

    async startBuild(e) {
        e.preventDefault();

        if (this.isBuilding) {
            this.log('编译正在进行中，请等待完成');
            return;
        }

        const formData = {
            openwrtSource: document.getElementById('openwrtSource').value,
            openwrtBranch: document.getElementById('openwrtBranch').value,
            configPath: document.getElementById('configPath').value,
            device: document.getElementById('device').value,
            enableSSH: document.getElementById('enableSSH').checked,
            onlySSH: document.getElementById('onlySSH').checked,
            enableCloudflared: document.getElementById('enableCloudflared').checked,
            sshDevice: document.getElementById('sshDevice').value
        };

        if (!formData.device) {
            this.log('请选择目标设备');
            return;
        }

        this.isBuilding = true;
        this.currentStep = 0;
        this.updateStatus('编译中');
        document.getElementById('startBuild').disabled = true;

        this.log('开始编译流程...');
        this.initializeProgress();

        try {
            const response = await fetch('/api/build/start', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify(formData)
            });

            const result = await response.json();

            if (!response.ok) {
                throw new Error(result.error || '启动编译失败');
            }

            this.log('编译工作流已触发，ID: ' + result.workflowRunId);
            this.log('查看详细进度: https://github.com/' + window.location.hostname + '/actions/runs/' + result.workflowRunId);

            this.startProgressSimulation();
            this.startLogStreaming(result.workflowRunId);

        } catch (error) {
            this.log('编译启动失败: ' + error.message);
            this.isBuilding = false;
            document.getElementById('startBuild').disabled = false;
            this.updateStatus('失败');
        }
    }

    initializeProgress() {
        const progressSteps = document.getElementById('progressSteps');
        progressSteps.innerHTML = '';

        this.buildSteps.forEach((step, index) => {
            const stepElement = document.createElement('div');
            stepElement.className = 'step';
            stepElement.id = `step-${index}`;
            stepElement.textContent = step;
            progressSteps.appendChild(stepElement);
        });

        document.getElementById('progressBar').style.width = '0%';
    }

    startProgressSimulation() {
        const totalSteps = this.buildSteps.length;
        const interval = setInterval(() => {
            if (this.currentStep >= totalSteps) {
                clearInterval(interval);
                this.completeBuild();
                return;
            }

            this.updateStep(this.currentStep, 'active');
            this.updateProgressBar((this.currentStep / totalSteps) * 100);

            setTimeout(() => {
                this.updateStep(this.currentStep, 'completed');
                this.currentStep++;
            }, 2000);

        }, 2500);
    }

    async startLogStreaming(workflowRunId) {
        try {
            const response = await fetch(`/api/build/logs?runId=${workflowRunId}`);

            if (response.ok) {
                const logs = await response.text();
                this.log(logs);
            } else {
                this.log('无法获取实时日志');
            }
        } catch (error) {
            this.log('日志获取失败: ' + error.message);
        }
    }

    updateStep(stepIndex, status) {
        const stepElement = document.getElementById(`step-${stepIndex}`);
        if (stepElement) {
            stepElement.className = `step ${status}`;
        }
    }

    updateProgressBar(percentage) {
        document.getElementById('progressBar').style.width = percentage + '%';
    }

    completeBuild() {
        this.isBuilding = false;
        document.getElementById('startBuild').disabled = false;
        this.updateStatus('完成');
        this.log('编译完成！');
    }

    log(message) {
        const logOutput = document.getElementById('logOutput');
        const timestamp = new Date().toLocaleTimeString();
        logOutput.innerHTML += `[${timestamp}] ${message}\n`;
        logOutput.scrollTop = logOutput.scrollHeight;
    }

    updateStatus(status) {
        const statusElement = document.getElementById('status');
        statusElement.textContent = status;

        switch(status) {
            case '编译中':
                statusElement.style.background = '#f39c12';
                break;
            case '完成':
                statusElement.style.background = '#27ae60';
                break;
            case '失败':
                statusElement.style.background = '#e74c3c';
                break;
            default:
                statusElement.style.background = '#27ae60';
        }
    }
}

document.addEventListener('DOMContentLoaded', () => {
    new BuildController();
});