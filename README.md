# LOME

> **面向重要人际关系的双人情感深层交互与关系成长平台的设计与实现**  
> 基于 Flutter + 腾讯云开发 CloudBase 的跨端双人情感交互应用（大模型相关能力为规划项，当前未实现）

LOME 面向青年人，重点服务异地、高压力忙碌的挚友或恋人，打造亲密关系专属数字化沟通空间。项目以 **记录、陪伴、沟通** 为三大核心价值，坚持「AI 作为辅助而非替代」的设计原则。AI 仅承担理解、提醒、整理、引导工作，把表达权和决定权留给关系双方。

---

## 📌 赛事选题匹配说明（传智杯 AI 创新应用赛道 / VibeCoding 挑战赛）

本项目属于赛事推荐方向 **7. 数字孪生与轻量具身智能仿真** 的场景化落地：面向亲密关系痛点，搭建具备完整 CRUD 数据流转、异步留言与定时投递能力的 Flutter + 腾讯云开发跨端应用。

依托 Vibe Coding 模式，借助大模型辅助完成全流程开发；仓库内保留逐功能迭代的 Git 提交历史与开发日志，保障开发链路可复现。

---

## 📜 复现性声明

1. **真实开发过程**：本项目为团队真实 Vibe-Coding 协同开发产物，非直接复制完整开源项目。代码由 AI 辅助生成，全部经过人工阅读、审查、重构、Bug 调试，模块架构、业务逻辑、产品需求均由团队自主定义。
2. **Git 版本记录**：Git 仓库为 Public 公开仓库，保留按功能迭代的提交历史。需要说明的是，早期为图部署方便把云函数的 `node_modules` 一并提交过（单次提交最多涉及 1654 个文件），现已停止跟踪并将 `**/node_modules/` 加入 `.gitignore`，历史体积仍在。
3. **过程材料**：仓库内可直接查阅的是 `docs/dev_log/git_commit_log.txt`（Git 提交导出日志）与 `daily-logs/` 下 3 份开发日志（2026-05-11 / 05-18 / 05-25）。完整的 AI 对话 Prompt 链、Bug 修复交互截图与演示视频存放在网盘参赛包中，未随仓库提交。
4. **环境配置说明**：本项目依赖外部腾讯云 CloudBase 环境，前端源码可直接浏览。仓库内 `.env.example` 为云函数环境变量模板（`ENV_ID` / `JWT_SECRET` / `LETTER_MASTER_KEYS` / `LETTER_ACTIVE_KEY_VERSION`），**不包含任何真实密钥**，实际值需在部署时由使用者自行填充。
5. **历史密钥泄漏说明**：早期提交曾把腾讯云 `SecretId` / `SecretKey` 硬编码进 `lib/services/cloudbase_service.dart` 并进入公开历史，现已从工作区代码中移除（当前 `main` 不含该值）。该密钥对是否已失效，取决于团队是否在腾讯云控制台完成禁用与轮换；克隆本仓库的评审者请勿复用历史提交中的任何凭证。

---

## ✨ 产品核心理念

- **回忆承载**
  - 情侣日历：图文记录 + AI 关系周报
  - 定时慢信：信件加密归档
  - 同屏共读：阅读痕迹留存

- **有效陪伴**
  - 留言板：无打扰异步留言
  - 情侣状态感知
  - 异地实时同屏共读

- **深层交流**
  - 同屏共读：思想与价值观碰撞
  - 定时慢信：延时深度表达，提供情绪缓冲空间

---

## 📋 功能模块与开发状态

| 功能模块 | 核心能力 | 开发状态 |
| :--- | :--- | :---: |
| 用户账号 | 手机号验证码登录、绑定码绑定、身份鉴权、个人信息与解绑 | ⚠️ 业务流程已完成，但验证码为固定后门，未接短信服务 |
| 留言板 | 图文异步留言、已读回执、编辑删除、双向回应、双人数据隔离 | ✅ 已完成 |
| 情侣日历 | 共同记录图文与心情、规划行程、纪念日标记、本月记录统计 | ✅ 已完成 |
| 慢信 | 长文写信、本地加密草稿、自定义送达时间、信封加密存储、拆信动效、回信 | ✅ 已完成（已合并 `main`，后端 9 个 `letter*` 云函数） |
| 同屏共读 | 实时同步翻页、批注共享、AI 话题引导、角色扮演共读 | ⏳ 规划中 |
| 虚拟形象 | 首页形象展示、点击互动、状态同步、装扮与礼物联动 | ⏳ 规划中 |
| AI 增强能力 | 关系健康周报、恋爱小事录、情绪识别、每日一问、共读话题生成 | ⏳ 规划中 |

---

## 🛠 技术栈

### 客户端（`pubspec.yaml` 实际引入的依赖）

- **Flutter + Dart**：同一套代码可构建 Android / iOS / Web / 桌面平台
- **google_fonts**：全局字体；**image_picker**：图文记录与留言选图
- **http**：直连 CloudBase HTTP 网关调用云函数
- **shared_preferences**：登录 Token 与用户信息缓存（明文，属待改造项）
- **flutter_secure_storage**：慢信草稿的端侧加密存储
- **flutter_dotenv**：依赖已声明，但 `dotenv.load()` 尚未在启动流程中调用，客户端配置目前硬编码于 `lib/utils/app_constants.dart`

### 后端云服务（腾讯云开发 CloudBase）

- **云函数**：37 个云函数（`cloudbase/functions/`），承载鉴权、绑定、日历、留言板、慢信业务
- **云数据库**：持久化业务数据；集合权限设为仅管理端可读写，访问统一经云函数
- **云存储**：信件图片、静态资源
- **鉴权**：`jsonwebtoken` 签发 HS256 Token（有效期 7 天），业务侧以 JWT 解出的 `userId` 为准做双人 ID 数据隔离，全仓不存在信任客户端传入 `userId` 的写法
- ⚠️ **演示态限制**：`sendSms` 未接入短信服务，`login` 接受固定验证码 `666666`；这是开发后门，不代表真实鉴权能力，上线前必须替换

### 通信与任务调度（当前实现）

- 请求-响应式 HTTP 调用，无长连接；实时同步、批注推送尚未实现
- 慢信投递由客户端在服务端到期判定基础上触发，定时任务与失败重试属规划项

### AI 应用层（均为规划，尚无代码实现）

- 大语言模型 API 接入、情绪识别、关系周报、共读话题生成
- 目前仓库内不存在模型调用代码，请勿按已交付能力评估

### 安全与合规

已落地：

- JWT 身份校验 + 双人数据访问隔离
- 慢信内容信封加密：AES-256-GCM + 密钥环版本化，过期派生密钥即时清除，令牌比较使用 `timingSafeEqual`
- 上传图片做 magic-byte 校验，不信任扩展名与 MIME
- 数据库集合权限为管理端专用，客户端无法直读

待补齐（当前缺失，评审请以此为准）：

- 真实短信验证码与验证码有效期/频控，去除万能码
- `jwt.verify` 统一固定 `algorithms`，移除 `JWT_SECRET` 缺失时的兜底默认值
- 绑定码改用 `crypto` 随机源并增加失败次数限制
- 云函数日志中手机号与验证码脱敏
- 登录 Token 迁移到安全存储
- 隐私政策、用户协议、注销与数据删除流程
- 内容审核与举报入口（UGC 场景必需，尚未实现）
- 项目若实际对外提供持续性情感互动类 AI 服务，需按《人工智能拟人化互动服务管理暂行办法》（2026-04-10 公布、2026-07-15 施行）履行安全评估与算法备案义务；当前 AI 能力未实现，暂按个人信息保护相关要求整改

### 工程化

- Git 版本管理，按功能开分支，主要功能经 Pull Request 合并
- 后端 21 个单元/集成测试：`cd cloudbase && npm test`（全部通过，使用内存数据库替身，不触碰线上环境）
- 共享代码一致性校验：`npm run check:common`、`npm run check:letters`
- API 文档：`docs/calendar_api.md`（约 1000 行，日历模块接口）
- 已知缺口：仓库内无 CI 与提交门禁；`flutter analyze` 现存 409 条告警（0 error / 16 warning / 393 info，其中 308 条为 `withOpacity` 弃用）；`dart format` 下 45 个 Dart 文件中 36 个不符合格式；`test/widget_test.dart` 为空文件

---

## 🎯 Prompt 意图控制与 AI 代码约束策略

> 评审维度：方法创新性与意图控制  
>
> 本项目大量业务代码由 AI 辅助生成，团队采用多层约束，避免 AI 输出不可控代码。

1. **上下文约束**：向 AI 输入需求时，前置传入项目现有架构文档、数据模型、接口定义，强制 AI 遵循现有模块划分，禁止 AI 随意新增文件、随意自定义数据表。
2. **架构约束**：要求 AI 遵守分层：`utils/config 公共层 → services 服务层 → models 模型层 → pages 页面层 → widgets 组件层`（与仓库实际目录一致）。执行程度需如实说明：页面层确实不直接引 `http` 包、统一经 `services/` 出口，但仍有 11 处把 `/api/v1/...` 接口路径内联写在页面里、5 个页面各自直接读 `SharedPreferences`，且 `pages/` 下存在 1700 行级别的单文件，分层约束在慢信模块之外执行得最松。
3. **安全约束**：每次生成后端 / 鉴权相关代码，明确要求必须带上双人 ID 鉴权校验，拒绝无权限校验的代码。
4. **迭代约束**：不一次性要求 AI 输出完整大模块，而是拆分为小任务迭代生成；AI 输出代码后人工审查，再进行 Bug 调试，遇到异常通过多轮 Prompt 引导 AI 定位并修复问题。
5. **输出边界约束**：AI 仅负责编码实现，**产品需求、数据表、业务规则全部由人预先定义**。

---

## 📁 项目目录结构

```text
lome/
├── lib/                            # Flutter 前端（45 个 .dart 文件）
│   ├── config/env.dart             # dotenv 读取封装（尚未接入启动流程）
│   ├── models/                     # 4 个数据模型：api_response / calendar_models / message_model / user_model
│   ├── pages/                      # 18 个业务页面（扁平目录，未按模块分子目录）
│   ├── services/                   # 6 个服务：api/auth/letter_store/message_service/slow_letter_api + 遗留的 cloudbase_service
│   ├── styles/                     # 3 个：颜色、字体、主题
│   ├── utils/                      # 3 个：app_constants、校验器等
│   ├── widgets/                    # 9 个公共组件（含 widgets/login/）
│   └── main.dart                   # 入口与命名路由表
│
├── cloudbase/                      # 腾讯云开发后端
│   ├── functions/                  # 37 个云函数 + 6 份共享模块源文件
│   │   ├── common.js               # 旧函数的鉴权/响应工具（source of truth）
│   │   ├── slow_letter_core.js     # 慢信业务核心（另有 11 份部署副本）
│   │   ├── slow_letter_crypto.js   # AES-256-GCM 信封加密与密钥环
│   │   ├── slow_letter_runtime.js  # HTTP 入口：鉴权/校验/错误映射
│   │   ├── slow_letter_store.js    # 数据访问层
│   │   └── relationship_core.js    # 双人关系校验
│   ├── test/slow_letters.test.js   # 后端 21 个测试用例
│   ├── tools/                      # 部署与一致性校验脚本（sync-*/slow-letter-cloud）
│   └── package.json                # npm test / check:common / check:letters
│
├── assets/images/                  # 33 个图片资源（约 47 MB，未启用 Git LFS）
├── test/                           # auth_service_test.dart + 空的 widget_test.dart
├── daily-logs/                     # 3 份开发日志（05-11 / 05-18 / 05-25）
├── docs/
│   ├── calendar_api.md             # 日历模块接口文档（约 1000 行）
│   └── dev_log/git_commit_log.txt  # Git 提交导出日志
├── android/ ios/ web/ linux/ macos/ windows/   # Flutter 平台工程
├── .env.example                    # 环境变量模板（不含真实密钥）
├── pubspec.yaml                    # Flutter 依赖与环境约束
└── README.md
```

> 注：`lib/` 目前未按 `auth/calendar/message_board/slow_letter` 等业务域分子目录，页面文件直接平铺；慢信相关页面以 `slow_letter_*`、`letter_*`、`envelope_*` 前缀区分。

---

## 🚀 环境搭建与本地运行

> ⚠️ **先读这一段**：仓库指向的是团队**共用演示环境**，登录使用固定后门验证码 `666666`（`sendSms` 未接入真实短信服务）。请勿在该环境存放任何真实个人数据；需要完整演示请自建 CloudBase 环境自行部署。
>
> 纯读代码约 2 分钟；跑通后端测试约 1 分钟（无需云资源）；自建后端部署约 20 分钟。

### 环境版本要求

- Flutter SDK：`3.29.0` 及以上
- Dart：`3.7.2` 及以上（依据 `pubspec.yaml` 的 `environment.sdk: ^3.7.2`）
- Node.js：`18.x`（后端测试与云函数部署脚本）
- 腾讯云 CloudBase 环境：自备独立环境 ID
- 大模型 API：**当前无需**，AI 能力尚未实现，详见上文「AI 应用层」

### 步骤 1：拉取代码（约 1 分钟）

```bash
git clone https://github.com/lvwanze/lome.git
cd lome
```

### 步骤 2：安装前端依赖（约 2 分钟）

```bash
flutter pub get
```

> ✅ 到此步骤完成，即可打开 IDE 浏览全部前端代码、UI 组件、业务逻辑，不需要密钥。
>
> ⚠️ 但直接 `flutter run` 会连到演示环境——生效的网关地址硬编码在 `lib/utils/app_constants.dart:9`（`lib/services/cloudbase_service.dart:12-14` 另有一份同样的地址，但该文件在 `lib/` 内无任何引用，属遗留代码）。

### 步骤 3：只跑后端测试（无需云资源、无需网络）

```bash
cd cloudbase
npm ci
npm test
```

预期 21 个用例全部通过。测试用内存数据替身替换数据库，不触碰线上环境。
另有一致性校验脚本：`npm run check:common`、`npm run check:letters`。

### 步骤 4：部署云函数到自己的环境

```bash
cd cloudbase
cp .env.example .env                                  # 填 ENV_ID / JWT_SECRET / LETTER_MASTER_KEYS
node tools/slow-letter-cloud.js deploy <你的环境ID>
```

部署前请注意三件事：

1. `cloudbase/tools/slow-letter-cloud.js:107` 把允许的环境 ID 写死为演示环境，部署到自建环境需修改该处校验。
2. 各函数目录内的 `common.js`、`slow_letter_*.js` 是**部署副本**：只改 `cloudbase/functions/` 根目录那份，再执行 `npm run sync:letters` 同步，避免副本漂移。
3. 云数据库集合权限需设为仅管理端可读写；HTTP 网关路由当前为 `auth: false`，鉴权逻辑在函数内部执行。

### 步骤 5：指向你自己的后端并启动 App

客户端尚未接入环境变量注入（`flutter_dotenv` 已在依赖里，但 `dotenv.load()` 未被调用），需手动修改硬编码地址：

- `lib/utils/app_constants.dart:9` — **实际生效**的 HTTP 网关 `baseUrl`（`ApiService`、`SlowLetterApi` 都取这里）
- `lib/services/cloudbase_service.dart:12-14` — 同样一份地址，但该文件在 `lib/` 内无任何引用，属遗留代码，改不改都不影响运行

> 待改造项：地址应统一到一处，并用 `flutter run --dart-define=CLOUD_BASE_URL=...` 注入。

```bash
flutter run
```

### 复现说明

1. 没有腾讯云资源时，评审可执行步骤 1–3：阅读全部源码 + 跑通 21 个后端测试。
2. AI 相关能力处于方案设计阶段，仓库内没有模型调用代码。
3. ⚠️ `flutter test` 当前**无法通过**：`test/widget_test.dart` 是 0 字节空文件，`test/auth_service_test.dart` 的 6 个用例会经测试 binding 直连演示环境（该 binding 下 HTTP 请求统一返回 400），且测试脚本会向线上写入绑定码等数据。
4. 真实密钥不会提交到仓库；历史提交中曾出现的云开发 SecretId/SecretKey 已从工作区移除（见「复现性声明」第 5 条）。

---

## 📂 演进过程材料查阅指引

1. **Git 提交历史**：查看 GitHub 提交记录，或 `docs/dev_log/git_commit_log.txt`（导出的提交日志）。
2. **开发日志**：`daily-logs/` 下 3 份，覆盖 2026-05-11 项目初始化、05-18 登录页与云开发配置、05-25 主页联调。05-18 那份原文记录了「编写 `sendSms` 云函数（固定验证码 666666）」与「获取环境ID和密钥」两条工作项,正好是上文鉴权后门与密钥泄漏的原始出处；密钥已在后续提交从代码中移除。
3. **接口文档**：`docs/calendar_api.md`，日历模块的请求/响应结构与错误码。
4. **Prompt 迭代链、UI 设计稿、演示视频与 PDF 技术文档**：存放于网盘完整作品包，仓库内不包含这些材料。

---

## 📦 代码仓库

GitHub：[https://github.com/lvwanze/lome](https://github.com/lvwanze/lome)

> 网盘参赛包内同步存放完整源码压缩包，作为离线兜底查阅版本。

---

## 👥 团队信息

- **团队名称**：LOME
- **参赛院校**：河南师范大学软件学院
- **指导教师**：朱泰隆
- **参赛者**：
  - 吕宛泽（队长、全栈开发）
  团队成员（李卓、岳英昊、范嘉博、申金玄）
---

## 📄 声明

本项目为赛事参赛作品，代码仅供学习交流，未经团队许可，禁止商用、二次分发。

补充说明（如实标注当前缺口，避免评审按已交付能力评估）：

- **许可**：仓库未附带标准开源许可证文件（无 `LICENSE`），依上述声明默认保留所有权利。
- **隐私与用户协议**：仓库内没有隐私政策与用户协议文本，App 设置页的「隐私」入口目前只弹出提示、无实际页面；上线前需补齐并取得单独同意。
- **演示环境**：`main` 分支指向团队共用的 CloudBase 演示环境，验证码为固定后门 `666666`，请勿在其中存放真实个人数据。
