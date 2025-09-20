# OpenWRT Builder Web UI

基于 Web 的 OpenWRT 编译控制台，提供图形化界面来管理和监控编译流程。

## 功能特性

- 📱 响应式 Web 界面
- ⚡ 实时编译状态监控
- 📊 可视化编译进度
- 🔧 灵活的编译配置
- 🌐 Cloudflare Tunnel 集成
- 📋 实时日志输出

## 安装和运行

### 前置要求

- Node.js 16+
- npm 或 yarn

### 安装依赖

```bash
cd web-ui
npm install
```

### 环境配置

1. 复制环境变量模板：
```bash
cp .env.example .env
```

2. 编辑 `.env` 文件，配置以下参数：
   - `GITHUB_TOKEN`: GitHub Personal Access Token（需要 repo 和 workflow 权限）
   - `GITHUB_REPOSITORY`: 你的仓库名称（格式：username/repository）

### 启动服务

```bash
# 开发模式
npm run dev

# 生产模式
npm start
```

服务将在 http://localhost:3000 启动

## API 接口

### 获取可用设备列表

```
GET /api/devices
```

### 启动编译

```
POST /api/build/start
Content-Type: application/json

{
  "openwrtSource": "https://github.com/coolsnowwolf/lede.git",
  "openwrtBranch": "master",
  "configPath": "configs/app.config",
  "device": "x86-64",
  "enableSSH": true,
  "onlySSH": false,
  "enableCloudflared": true,
  "sshDevice": "x86-64"
}
```

### 获取实时日志

```
GET /api/build/logs
```

## 配置说明

### 编译参数

- **openwrtSource**: OpenWRT 源码仓库地址
- **openwrtBranch**: 源码分支
- **configPath**: 应用配置文件路径
- **device**: 目标设备架构
- **enableSSH**: 是否启用 SSH
- **onlySSH**: 是否仅运行 SSH
- **enableCloudflared**: 是否启用 Cloudflare Tunnel
- **sshDevice**: SSH 运行设备名称

### 环境变量

- `PORT`: 服务端口（默认: 3000）

## 开发

### 项目结构

```
web-ui/
├── index.html          # 主页面
├── style.css           # 样式文件
├── script.js           # 前端逻辑
├── server.js           # Express 服务器
├── package.json        # 依赖配置
└── README.md          # 说明文档
```

### 扩展功能

1. **真实编译集成**: 连接实际的 GitHub Actions API
2. **用户认证**: 添加登录和权限控制
3. **历史记录**: 保存编译历史和结果
4. **邮件通知**: 编译完成通知
5. **多语言支持**: 国际化界面

## 部署

### 使用 PM2（推荐）

```bash
npm install -g pm2
pm2 start server.js --name "op-builder-webui"
```

### 使用 Docker

```dockerfile
FROM node:16-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 3000
CMD ["npm", "start"]
```

## 许可证

MIT License