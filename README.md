# CookPulse · 智能炒锅数字孪生（应用端分发版）

从**任意食材输入**到**AI 菜谱**、**料筒映射**、**六轴机械臂投料**、**控温烹饪**、**出餐与自清洗**，
一条命令跑完整个软件 → 数字孪生的自动流程。

本仓库只发布**加密后的应用端**：核心算法与业务逻辑以 AES-256-GCM 载荷分发，
仓库里没有可读的源码。参考实现与联调分支见私有仓库 `moonstone_hack_pengran`
（`codex/multimodal-kitchen` 之上的 `feat/cookpulse-integrated-release`）。

## 快速开始

```bash
git clone https://github.com/linyuze/moonstone_hack_pengran_public.git
cd moonstone_hack_pengran_public
./start.sh
```

浏览器会自动打开 <http://127.0.0.1:5186/>。按 `Ctrl+C` 结束，运行时目录会被清除。

自定义端口：`COOKPULSE_PORT=6000 ./start.sh`

## 环境要求

| 组件 | 版本 | 说明 |
| --- | --- | --- |
| Linux x86-64 / WSL2 | — | 启动器为 ELF 可执行文件 |
| Node.js | ≥ 20 | 运行 Web API（已打包为单文件，无需 npm install） |
| Python 3 | ≥ 3.9 | 运行数字孪生与物理仿真 |
| PyYAML | ≥ 6 | `python3 -m pip install --user pyyaml` |
| libcrypto | OpenSSL 1.1/3.x | 启动器解密载荷，发行版通常自带 |

不需要 Docker、不需要 MQTT broker、不需要编译前端。

## 配置菜谱模型

菜谱由大模型生成。二选一：

1. 环境变量

```bash
export COOKPULSE_AI_BASE_URL="https://api.deepseek.com/v1"
export COOKPULSE_AI_API_KEY="sk-..."
export COOKPULSE_AI_MODEL="deepseek-chat"
./start.sh
```

2. 本机配置文件（推荐，权限 600）

```bash
mkdir -p ~/.config/cookpulse
cat > ~/.config/cookpulse/ai.json <<'JSON'
{ "baseUrl": "https://api.deepseek.com/v1", "apiKey": "sk-...", "model": "deepseek-chat" }
JSON
chmod 600 ~/.config/cookpulse/ai.json
```

未配置模型时仍可启动：孪生会退回离线规则演示（仅支持清炒时蔬 / 清煮胡萝卜 / 清蒸豆腐）。

## 一次完整流程

1. 首页选食材、人数、口味与忌口。料筒支持 19 种食材（时蔬、胡萝卜、豆腐、番茄、鸡蛋、饮用水、香菇、土豆、甜青椒、洋葱、大白菜、菠菜、黄瓜、茄子、西兰花、鸡肉、猪肉、牛肉、虾仁）与 15 种调料（盐、食用油、生抽、葱花、蒜末、姜末、蚝油、老抽、鸡精、糖、醋、料酒、香油、淀粉、蜂蜜）。
2. 后端生成 1–3 个菜单候选，逐个核对用量、缺料与忌口。
3. 选中候选 → 自动发送到孪生 → 料筒按槽位投料 → 机械臂托盘投料 → 加热控温 → 出餐 → 冷却自清洗。
4. 工作台实时显示温度曲线、机械臂关节角、步骤进度与出餐克数。

菜单里出现本机料筒没有的食材时，程序会先让模型按真实料筒重写一次；
仍不可执行才给出**标注清楚的替代方案**，保证演示链路不中断。

加速：工作台里的「8× 仿真速度」同时作用于热模型、PID、机械臂与重力。

## 目录结构

```
cookpulse            加密载荷的原生启动器（已 strip）
app/cookpulse.pkg    AES-256-GCM 加密的运行时（Web 构建产物 + Web API + 孪生引擎）
start.sh             一键启动
docs/                架构说明与联调记录
```

## 加密边界（请如实理解）

- 仓库内容：只有密文与已编译的启动器，没有 Python / TypeScript / JSX 源码。
- 运行方式：启动器校验 AES-256-GCM 认证标签后，把载荷解到私有临时目录
  （`/dev/shm`，权限 0700）运行，退出时删除；密钥拆分掩码内嵌在 strip 过的二进制里。
- 局限：客户端分发无法做到绝对不可逆。拥有本机 root 权限与足够动机的人，
  仍可在进程运行期间 dump 内存或读取临时目录还原逻辑。这层保护的目标是
  「公开分发时不被随手阅读/复制核心实现」，不是对抗有 root 权限的逆向工程。
  需要更强保护请改为服务端推理（把核心逻辑放在你自己的服务器上，客户端只做展示）。

## 已验证

- 8 组食材（番茄+鸡蛋 / 青菜+香菇 / 土豆+胡萝卜 / 豆腐 / 彩椒+豆腐 / 番茄+土豆+香菇 / 牛肉+洋葱 / 空库存）
  全部走完「菜单生成 → 孪生编译 → 投料 → 烹饪 → 出餐 → 清洗」，
  仿真状态 `completed`、进度 100%、出餐克数正常。
- 孪生 Python 测试 175 项全通过；菜单相关前端测试 57 项全通过。
- 真实机械臂执行未验收：界面中的实机反馈通道保持只读，执行接口返回 409。
