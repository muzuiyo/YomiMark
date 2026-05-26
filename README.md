# YomiMark - 日语注音工具

一个完整的日语注音解决方案，包括Web应用、API服务和字幕编辑插件。为日文文本自动添加振假名（furigana）、送假名（okurigana）或罗马字标注。

## 项目概述

YomiMark 是一个全栈应用，为日语学习者和内容创作者提供便捷的注音工具。无论您是编辑字幕、学习日语还是处理日文文本，YomiMark 都能帮您快速生成精确的读音标注。

## 项目架构

```
YomiMark/
├── backend/          # Cloudflare Workers API 服务
├── frontend/         # React Web 应用
├── plugin/          # Aegisub 字幕编辑插件
└── README.md        # 此文件
```

## 功能特性

### 三种注音模式

- **振假名 (Furigana)** - 在汉字上方添加平假名注音，输出为 HTML `<ruby>` 标签
- **送假名 (Okurigana)** - 仅为动词和形容词的变位部分添加注音
- **罗马字 (Romaji)** - 转换为拉丁字母罗马字标注

### 三种输出格式

- **平假名 (Hiragana)** - 默认输出格式
- **片假名 (Katakana)** - 用于外来词和拟声词
- **罗马字 (Romaji)** - 拉丁字母标注（护照式罗马字系统）

## 快速开始

### 前置要求

- Node.js 18.0 或更高版本
- pnpm 10.28.0（可选，也可使用 npm 或 yarn）

### 安装依赖

```bash
# 安装 backend 依赖
cd backend
npm install

# 安装 frontend 依赖
cd ../frontend
npm install
```

### 本地开发

#### 启动 Backend API

```bash
cd backend
npm run dev
```

API 服务将在 `http://localhost:8787` 启动

#### 启动 Frontend Web 应用

```bash
cd frontend
npm run dev
```

Web 应用将在 `http://localhost:5173` 启动

#### 使用应用

1. 打开浏览器访问 `http://localhost:5173`
2. 在文本框中输入日文文本
3. 选择所需的注音模式（振假名、送假名或罗马字）
4. 点击"解析"按钮
5. 查看结果并复制到剪贴板

## 部署

### Backend 部署到 Cloudflare Workers

```bash
cd backend
npm run deploy
```

部署前请确保已配置 Wrangler CLI 和 Cloudflare 账户。

### Frontend 部署

```bash
cd frontend
npm run build
```

生成的静态文件位于 `dist/` 目录，可部署到任何静态文件服务器。

部署时需设置环境变量 `VITE_API_URL` 指向后端 API 服务。

## API 文档

### 端点

**POST** `/`

### 请求体

```json
{
  "text": "日本語のテキスト",
  "mode": "furigana",
  "to": "hiragana"
}
```

**参数说明：**

| 参数 | 类型 | 必需 | 默认值 | 描述 |
|------|------|------|--------|------|
| `text` | string | ✓ | - | 要处理的日文文本 |
| `mode` | string | ✗ | `furigana` | 注音模式：`furigana` / `okurigana` / `romaji` |
| `to` | string | ✗ | `hiragana` | 输出格式：`hiragana` / `katakana` / `romaji` |

### 响应示例

**成功响应 (200)**

```json
{
  "result": "<ruby>日<rt>に</rt></ruby><ruby>本<rt>ほん</rt></ruby><ruby>語<rt>ご</rt></ruby>"
}
```

**错误响应 (4xx/5xx)**

```json
{
  "error": "错误信息描述"
}
```

### 错误处理

- **400** - 请求参数无效
- **405** - 仅支持 POST 请求
- **500** - 服务器内部错误

### CORS 支持

API 支持跨域请求（CORS），可从任何域名调用。

## 字幕插件 (Aegisub)

### 安装

将 `plugin/furigana_kara.lua` 文件复制到 Aegisub 自动化脚本目录：

- **Windows**: `%AppData%\Aegisub\automation\autoload\`
- **macOS**: `~/.config/aegisub/automation/autoload/`
- **Linux**: `~/.config/aegisub/automation/autoload/`

### 使用方法

1. 在 Aegisub 中打开字幕文件
2. 进入菜单 `Automation` → `YomiMark Furigana`
3. 配置 API URL（默认为 `http://127.0.0.1:8787`）
4. 选择要处理的行
5. 脚本将自动为日文文本添加注音

## 技术栈

### Backend

- **Runtime**: Cloudflare Workers
- **Framework**: Wrangler
- **Language**: TypeScript
- **主要库**:
  - `kuroshiro` - 日语处理库
  - `kuroshiro-analyzer-kuromoji` - 形态分析器

### Frontend

- **框架**: React 19
- **语言**: TypeScript
- **构建工具**: Vite
- **样式**: Tailwind CSS
- **UI 库**: Base UI、Lucide React

### Plugin

- **脚本语言**: Lua
- **目标应用**: Aegisub

## 项目结构详解

### Backend (`backend/`)

```
backend/
├── src/
│   ├── index.ts           # 主 API 处理器
│   └── types/             # TypeScript 类型定义
├── wrangler.toml          # Cloudflare Workers 配置
├── tsconfig.json          # TypeScript 配置
└── package.json
```

**关键特性：**
- XMLHttpRequest polyfill 用于 Cloudflare Workers 兼容性
- 单例模式初始化 Kuroshiro 实例以优化性能
- 完整的输入验证和错误处理
- CORS 支持

### Frontend (`frontend/`)

```
frontend/
├── src/
│   ├── App.tsx            # 主应用组件
│   ├── main.tsx           # 应用入口
│   ├── components/        # React 组件
│   │   └── ui/           # UI 组件库
│   └── lib/              # 工具函数
├── vite.config.ts        # Vite 配置
├── tsconfig.json         # TypeScript 配置
└── package.json
```

**主要功能：**
- 文本输入和结果显示
- 模式选择下拉菜单
- 复制到剪贴板功能
- 实时错误处理和加载状态
- 完全响应式设计

### Plugin (`plugin/`)

```
plugin/
└── furigana_kara.lua      # Aegisub 自动化脚本
```

**主要功能：**
- 集成 Aegisub 字幕编辑器
- 批量为字幕行添加注音
- 可配置的 API 地址
- 错误处理和日志记录

## 配置

### 环境变量

#### Frontend

在 `frontend/` 目录下创建 `.env` 或 `.env.local` 文件：

```
VITE_API_URL=http://your-api-url:8787
```

如未设置，默认使用 `http://127.0.0.1:8787`

#### Plugin

在 Aegisub 中运行脚本时可配置 API 地址（默认为 `http://127.0.0.1:8787`）

## 开发指南

### 添加新功能

1. **修改 API** - 编辑 `backend/src/index.ts`
2. **更新 UI** - 修改 `frontend/src/App.tsx` 及相关组件
3. **本地测试** - 运行 `npm run dev` 命令
4. **构建** - 运行 `npm run build` 检查编译错误

### 代码规范

- 使用 TypeScript 确保类型安全
- 遵循 ESLint 配置规则
- 在 frontend 中运行 `npm run lint` 检查代码质量

### 构建和部署

```bash
# Backend
cd backend
npm run build      # TypeScript 编译
npm run deploy    # 部署到 Cloudflare

# Frontend
cd frontend
npm run build     # 打包应用
# 将 dist/ 目录部署到任何静态文件服务器
```

## 常见问题

### Q: API 无法连接

**A:** 确保：
- Backend 服务正在运行（`npm run dev`）
- Frontend 配置的 API URL 正确
- 检查浏览器控制台的 CORS 错误信息

### Q: 注音结果不准确

**A:** 这可能是因为：
- Kuromoji 字典未完全加载
- 输入文本包含不支持的字符
- 尝试刷新页面重新加载字典

### Q: 如何离线使用？

**A:** 目前 Kuroshiro 依赖在线加载的词典。可修改 `backend/src/index.ts` 中的 `DICT_CDN` 使用本地字典。

## 相关资源

- [Kuroshiro 文档](https://github.com/hexenq/kuroshiro)
- [Cloudflare Workers 文档](https://developers.cloudflare.com/workers/)
- [Aegisub 自动化脚本指南](http://docs.aegisub.org/latest/Automation/)
