# Lome 日历/记录/规划/重要日 云函数部署说明

> 环境 ID：`love-app1-0g8yva6l11e713ef`
> 所有新函数均遵循项目现有模式：`@cloudbase/node-sdk` + JWT(`Authorization: Bearer <token>`)鉴权,与 `login` / `interaction` 等函数一致。
> ⚠️ 文档原示例使用小程序专用 `wx-server-sdk` + `getWXContext().OPENID`,本项目是 Flutter App 走 HTTP 访问服务,已全部改为 JWT + node-sdk 方案。

## 1. 数据库集合(已创建 ✅)

| 集合 | 用途 | 权限 |
| --- | --- | --- |
| `records` | 记录数据 | PRIVATE(与 `letters` 一致) |
| `plans` | 规划数据 | PRIVATE |
| `important_days` | 重要日数据 | PRIVATE |
| `users` | 用户信息(已存在,18 条) | 未改动 |

- 数据库中还残留 3 个空的测试集合 `z_records` / `z_plans` / `z_important_days`,可自行在控制台删除。
- 建议在控制台为 `records` / `plans` / `important_days` 的 `date` 字段各建一个普通索引(月历查询按日期范围过滤)。
- 新集合权限设为 `PRIVATE`:App 不直连数据库(所有读写都走云函数),函数使用服务端 SDK 不受安全规则限制,因此规则对外部访问完全封闭。
  - 文档中的 `{"read": "auth.openid == doc.authorId || ..."}` 规则面向小程序 CloudBase 登录体系,本项目用自定义 JWT,`auth.openid` 永远不匹配,故等价做法是「集合 PRIVATE + 函数内做归属校验」(已在每个函数中实现)。

## 2. 云函数清单(代码已写好,待你部署)

| 函数名 | 接口 | 请求方式 | 主要入参 |
| --- | --- | --- | --- |
| `calendarMonthly` | /api/v1/calendar/monthly | GET/POST | `month` 如 `2026-08` |
| `calendarDaily` | /api/v1/calendar/daily | GET/POST | `date` 如 `2026-08-16` |
| `recordCreate` | /api/v1/record/create | POST | `date` `title` `content` `images[]` `mood` |
| `recordUpdate` | /api/v1/record/update | PUT/POST | `recordId` + 要改的字段 |
| `recordDelete` | /api/v1/record/delete | POST | `recordId` |
| `planCreate` | /api/v1/plan/create | POST | `date` `title` `content` `images[]` |
| `planUpdate` | /api/v1/plan/update | PUT/POST | `planId` + 要改的字段 |
| `planToggle` | /api/v1/plan/toggle | PUT/POST | `planId` `completed`(布尔) |
| `planDelete` | /api/v1/plan/delete | POST | `planId` |
| `importantDayList` | /api/v1/important-day/list | GET/POST | 无 |
| `importantDayCreate` | /api/v1/important-day/create | POST | `name` `date` `type` `remark` |
| `importantDayDelete` | /api/v1/important-day/delete | POST | `importantDayId` |
| `uploadImage` | /api/v1/upload/image | POST | `fileName` `fileContent`(base64) |

所有接口统一响应:`{ code, message, data }`;鉴权失败返回 `code: 4001`(与现有约定一致,前端会清 Token 跳登录页)。

### 2.1 网关路由(已创建 ✅,2026-08-16)

路由规则:**函数名按驼峰拆词,每个单词作为一级路径**,统一加前缀 `/api/v1/`。已全部创建在默认 HTTPSERVICE 域名 `love-app1-0g8yva6l11e713ef-1418513210.ap-shanghai.app.tcloudbase.com` 上(上游类型 `SCF`、不启用网关鉴权、路径透传关闭,与现有 `/api/v1/auth/*` 路由一致):

| 函数名 | 路由路径 |
| --- | --- |
| `calendarMonthly` | `/api/v1/calendar/monthly` |
| `calendarDaily` | `/api/v1/calendar/daily` |
| `recordCreate` / `recordUpdate` / `recordDelete` | `/api/v1/record/create` / `update` / `delete` |
| `planCreate` / `planUpdate` / `planToggle` / `planDelete` | `/api/v1/plan/create` / `update` / `toggle` / `delete` |
| `importantDayList` / `importantDayCreate` / `importantDayDelete` | `/api/v1/important/day/list` / `create` / `delete` |
| `uploadImage` | `/api/v1/upload/image` |

两条路径并存:原来的 `/<函数名>`(HTTP 访问服务默认路径)和新路由 `/api/v1/...` 均可访问。Flutter 端可继续用 `baseUrl/<函数名>`,或改用 REST 风格路径。

## 3. 部署步骤

### 方式一:CLI 批量部署(推荐,已提供 `cloudbaserc.json`)

项目根目录已生成 `cloudbaserc.json`,包含全部 13 个新函数及环境变量(`ENV_ID` + `JWT_SECRET`,与 `login` 函数一致)。

```bash
# 1. 安装 CLI(如未安装)
npm install -g @cloudbase/cli
# 2. 登录(选择 love-app1 环境)
tcb login

# 3. 批量部署全部 13 个函数(--yes 跳过交互确认)
tcb fn deploy --all --yes

# 或部署单个函数(可加 --force 覆盖)
tcb fn deploy calendarMonthly --yes
```

配置说明:

- `functionRoot: "./cloudbase/functions"`,函数按目录名自动解析,13 个目录与配置一一对应。
- 运行时 `Nodejs18.15`、`handler: index.main`、`installDependency: true`(云端自动装依赖),与现有 9 个函数保持一致。
- 函数类型为 **Event(事件函数)**,与现有函数一致,不要改成 HTTP 函数类型(函数类型部署后不可变更,且 HTTP 函数需要 scf_bootstrap 启动脚本)。
- `uploadImage` 超时设为 20s(上传大图),其余 10s。
- ⚠️ 部署后需在控制台确认已开启 **HTTP 访问服务**(云函数 → HTTP 访问服务),Flutter 端通过 `https://love-app1-0g8yva6l11e713ef-1418513210.ap-shanghai.app.tcloudbase.com/<函数名>` 调用。
- ⚠️ `cloudbaserc.json` 内含 JWT_SECRET,注意不要泄露(当前仓库为私有开发用途可接受)。
- 若使用 @cloudbase/cli 2.12.0 以下版本,配置文件中的环境变量会完全覆盖线上配置;本批函数为新建,无影响。

### 方式二:控制台手动部署

对每个函数(共 13 个),重复以下操作:

1. 云开发控制台 → 云函数 → 新建云函数,函数名与目录名一致(如 `calendarMonthly`)。
2. 运行时选 **Nodejs**(与现有函数相同),上传 `cloudbase/functions/<函数名>/` 目录下的 `index.js`、`common.js`、`package.json`(在线安装依赖,`package.json` 已声明 `@cloudbase/node-sdk` 和 `jsonwebtoken`)。
3. 配置环境变量(两个都要,缺一不可):
   - `ENV_ID` = `love-app1-0g8yva6l11e713ef`
   - `JWT_SECRET` = **必须与 `login` 函数已配置的 JWT_SECRET 完全一致**,否则所有接口都会返回 4001。
4. 开启 **HTTP 访问服务**(云函数详情 → HTTP 访问服务 → 开启/配置)。
   - 默认触发路径即函数名:`https://love-app1-0g8yva6l11e713ef-1418513210.ap-shanghai.app.tcloudbase.com/calendarMonthly`,与 Flutter 端 `CloudBaseService` 的调用方式一致,无需改客户端。
   - 若想按文档的 REST 路径(`/api/v1/record/create` 等),可在 HTTP 访问服务里把每个函数的触发路径改成对应路径。

## 4. 权限与数据设计要点

- **双人共享**:每条记录/规划/重要日都带 `authorId`(创建者)+ `partnerId`(创建时的伴侣)。查询接口只返回 `authorId == 我 || partnerId == 我` 的数据,实现双方互见。
- **写权限**:更新/删除仅创建者(`authorId`)可操作(对应文档安全规则 `write: author`);`planToggle` 例外——伴侣也可以帮对方勾选完成,完成人会记录到 `completedBy`。
- **图片**:`uploadImage` 接收 base64(≤3MB,HTTP 访问服务请求体上限约 6MB),存入云存储私有目录 `images/<userId>/`,返回 `fileId` + 临时访问 URL。`calendarDaily` 查询记录时会自动为 `images` 里的 fileID 换新临时链接,前端直接渲染。
- **日期格式**:`date` 为 `YYYY-MM-DD` 字符串;`createTime` 等为毫秒时间戳(与接口文档约定一致)。
- **日历修正**:文档示例中 `new Date(month).getDate()` 对 `"2026-08"` 会得到 NaN,已改为 `new Date(y, m, 0).getDate()` 计算当月天数;月尾日期也按实际天数计算,避免字符串比较越界。

## 5. 测试(已通过 ✅,48 用例)

集成测试脚本位于 `cloudbase/tests/collections.test.js`,直连已部署环境,覆盖 records / plans / important_days 三个集合的:

- 鉴权防护(无 Token 一律 4001)
- 增删改查与 404/400 错误分支
- 日历联动(月历标记、pending 计数、重要日名称、日详情)
- 参数校验(缺参数、非法月份/日期、images 截断)

运行方式(无需安装依赖,Node 18+):

```bash
node cloudbase/tests/collections.test.js
# 可用环境变量覆盖: BASE_URL / TEST_PHONE / LOGIN_CODE
```

测试数据在断言后立即清理,不留残留;退出码 0=全部通过,1=存在失败。

## 6. 部署后自测建议

用 curl 验证(先调 `login` 拿 token):

```bash
TOKEN=<登录接口返回的token>
BASE=https://love-app1-0g8yva6l11e713ef-1418513210.ap-shanghai.app.tcloudbase.com

# 创建记录
curl -X POST $BASE/recordCreate -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"date":"2026-08-16","title":"一起看日落","content":"在海边","mood":"happy"}'

# 月历概览（GET 方式）
curl "$BASE/calendarMonthly?month=2026-08" -H "Authorization: Bearer $TOKEN"

# 创建规划并切换完成
curl -X POST $BASE/planCreate -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" -d '{"date":"2026-08-20","title":"看电影"}'
curl -X POST $BASE/planToggle -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" -d '{"planId":"<上一步返回的planId>","completed":true}'
```
