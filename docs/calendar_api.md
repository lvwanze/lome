Flutter项目结构分析
好的，我先把文档写入文件，然后告诉你放哪里。

文件保存位置
建议放在项目根目录的 docs/ 文件夹下：

text
E:\HuaweiMoveData\Users\l1513\Desktop\lome\docs\calendar_api.md
创建文件夹并写入文件
1. 先创建 docs 目录（如果不存在）
bash
mkdir docs
2. 创建文件
我把完整的文档内容写入 docs/calendar_api.md，你可以直接复制下面的内容，在 VS Code 中新建文件保存：

文件路径: E:\HuaweiMoveData\Users\l1513\Desktop\lome\docs\calendar_api.md

文件内容
markdown
# Lome 日历功能接口文档

## 1. 基础约定

### 1.1 请求头
Content-Type: application/json
Authorization: Bearer <token>

text

### 1.2 通用响应格式
```json
{
  "code": 0,
  "message": "success",
  "data": {}
}
1.3 数据格式
类型	格式	示例
日期	YYYY-MM-DD	2026-08-15
月份	YYYY-MM	2026-08
1.4 错误码
错误码	含义
7001	尚未绑定伴侣
10001	规划不存在
10002	记录不存在
10003	重要日不存在
10004	重要日名称重复
9001	图片过大（>10MB）
9003	图片数量超限（>9张）
2. 日历模块
2.1 获取月历概览
Method: GET

Path: /api/v1/calendar/monthly

Query: month (YYYY-MM)

Response:

json
{
  "code": 0,
  "data": {
    "month": "2026-08",
    "recordedDays": 12,
    "days": [
      {
        "date": "2026-08-15",
        "hasRecord": true,
        "hasPlan": true,
        "hasImportantDay": false,
        "planPendingCount": 2,
        "importantDayName": null
      }
    ]
  }
}
字段说明:

字段	类型	说明
month	string	查询月份
recordedDays	integer	本月已记录天数
days[].date	string	日期
days[].hasRecord	boolean	有记录 → 淡粉圆点
days[].hasPlan	boolean	有规划 → 浅绿圆点
days[].hasImportantDay	boolean	重要日 → 淡黄圆点
days[].planPendingCount	integer	待完成规划数
days[].importantDayName	string|null	重要日名称
2.2 获取日详情
Method: GET

Path: /api/v1/calendar/daily

Query: date (YYYY-MM-DD)

Response:

json
{
  "code": 0,
  "data": {
    "date": "2026-08-15",
    "records": [
      {
        "recordId": "rec_001",
        "content": "今天一起去了海边 🌊",
        "images": ["https://cdn.example.com/img1.jpg"],
        "mood": "happy",
        "authorId": "u_123456",
        "authorNickname": "用户8975",
        "createTime": 1753718400000
      }
    ],
    "plans": [
      {
        "planId": "plan_001",
        "title": "晚上看电影",
        "completed": false,
        "authorId": "u_123456",
        "authorNickname": "用户8975"
      }
    ],
    "planPendingCount": 1,
    "importantDay": null
  }
}
3. 记录模块
3.1 创建记录
Method: POST

Path: /api/v1/record/create

Body:

json
{
  "date": "2026-08-15",
  "content": "今天一起看了日落 🌅",
  "images": ["https://cdn.example.com/sunset.jpg"],
  "mood": "happy"
}
字段说明:

字段	类型	必填	说明
date	string	✅	YYYY-MM-DD
content	string	❌	最长2000字
images	array	❌	最多9张
mood	string	❌	happy/calm/sad/love/excited
Response:

json
{
  "code": 0,
  "message": "记录创建成功",
  "data": { "recordId": "rec_003" }
}
3.2 更新记录
Method: PUT

Path: /api/v1/record/update

Body:

json
{
  "recordId": "rec_003",
  "content": "更新后的内容",
  "images": [],
  "mood": "love"
}
3.3 删除记录
Method: POST

Path: /api/v1/record/delete

Body: { "recordId": "rec_003" }

4. 规划模块
4.1 创建规划
Method: POST

Path: /api/v1/plan/create

Body:

json
{
  "date": "2026-08-15",
  "title": "一起去吃火锅",
  "content": "晚上7点老地方见 🍲",
  "images": []
}
字段说明:

字段	类型	必填	说明
date	string	✅	YYYY-MM-DD
title	string	✅	最长50字
content	string	❌	最长500字
images	array	❌	最多9张
4.2 切换完成状态
Method: PUT

Path: /api/v1/plan/toggle

Body: { "planId": "plan_003", "completed": true }

4.3 更新规划
Method: PUT

Path: /api/v1/plan/update

4.4 删除规划
Method: POST

Path: /api/v1/plan/delete

Body: { "planId": "plan_003" }

5. 重要日模块
5.1 获取重要日列表
Method: GET

Path: /api/v1/important-day/list

5.2 添加重要日
Method: POST

Path: /api/v1/important-day/create

Body:

json
{
  "name": "恋爱纪念日",
  "date": "2025-03-15",
  "repeatType": "yearly",
  "icon": "heart"
}
5.3 删除重要日
Method: POST

Path: /api/v1/important-day/delete

Body: { "importantDayId": "imp_003" }

6. 图片上传
Method: POST

Path: /api/v1/upload/image

Content-Type: multipart/form-data

字段: file (jpg/png/webp, 最大10MB)

Response:

json
{
  "code": 0,
  "data": { "url": "https://cdn.example.com/uploads/img_abc.jpg" }
}
7. 接口汇总
模块	Method	Path	说明
日历	GET	/api/v1/calendar/monthly	月历概览
日历	GET	/api/v1/calendar/daily	日详情
记录	POST	/api/v1/record/create	创建记录
记录	PUT	/api/v1/record/update	更新记录
记录	POST	/api/v1/record/delete	删除记录
规划	POST	/api/v1/plan/create	创建规划
规划	PUT	/api/v1/plan/update	更新规划
规划	PUT	/api/v1/plan/toggle	打勾/取消
规划	POST	/api/v1/plan/delete	删除规划
重要日	GET	/api/v1/important-day/list	重要日列表
重要日	POST	/api/v1/important-day/create	添加重要日
重要日	POST	/api/v1/important-day/delete	删除重要日
上传	POST	/api/v1/upload/image	上传图片
text

---

## 在 VS Code 中操作

1. 在项目根目录创建 `docs` 文件夹
2. 在 `docs` 文件夹中新建文件 `calendar_api.md`
3. 把上面的内容粘贴进去
4. 保存

---

## 或者用命令行创建

```bash
# 创建 docs 目录
mkdir docs

# 创建文件（用记事本）
notepad docs\calendar_api.md
然后把内容粘贴进去保存即可。

文件位置
text
E:\HuaweiMoveData\Users\l1513\Desktop\lome\
├── docs/
│   └── calendar_api.md          ← 接口文档放这里
├── lib/
│   ├── models/
│   ├── pages/
│   └── services/
├── assets/
└── ...
文档放好后，后续对接接口时可以随时查阅。需要我帮你把日历页面中的 API 调用改成真实的接口吗？

你给我命令行，我看看现有接口文档都写哪里了，然后这个要添加到同一块
好的，先用命令行搜索一下现有接口文档的位置：

搜索命令
bash
# 1. 搜索所有 .md 文件中的 "api/v1"
findstr /s /i "api/v1" *.md

# 2. 搜索所有 .md 文件中的 "接口"
findstr /s /i "接口" *.md

# 3. 搜索所有 .txt 文件中的 "api"
findstr /s /i "api" *.txt

# 4. 列出项目根目录下所有 .md 文件
dir *.md /s

# 5. 搜索 docs 目录（如果存在）
dir docs /s

# 6. 搜索 cloudbase 目录下是否有文档
dir cloudbase /s | findstr -i "md txt readme"
更精确的搜索
bash
# 搜索包含 "calendar" 的 md/txt 文件
findstr /s /i "calendar" *.md *.txt

# 搜索包含 "接口文档" 的文件
findstr /s /i "接口文档" *.md *.txt *.json

# 查看项目根目录
dir *.md *.txt *.json
一次性全搜
bash
# 搜索所有包含 "calendar" 或 "monthly" 或 "接口" 的文件
findstr /s /i "calendar monthly 接口" *
执行这些命令，把结果发给我。我会根据结果告诉你：

现有文档都在哪些位置

这份日历接口文档应该放到哪里（和现有文档统一位置）

findstr /s /i "api/v1" *.md
FINDSTR: 警告 - 输入文件 README.md 采用 Unicode 格式。
PS E:\HuaweiMoveData\Users\l1513\Desktop\lome>
好的，说明目前项目根目录下没有其他 .md 文件包含 api/v1，也就是说之前没有现成的接口文档。

结论
你的项目目前没有集中的接口文档目录，所以我们可以新建一个 docs/ 文件夹来统一管理。

操作步骤
1. 创建 docs 目录
bash
mkdir docs
2. 把接口文档写入文件
在 VS Code 中新建文件，路径为：

text
E:\HuaweiMoveData\Users\l1513\Desktop\lome\docs\calendar_api.md
然后把刚才那份完整的内容粘贴进去保存。

或者用命令行创建
bash
# 创建 docs 目录
mkdir docs

# 用记事本创建文件（然后粘贴内容）
notepad docs\calendar_api.md
最终文件结构
text
E:\HuaweiMoveData\Users\l1513\Desktop\lome\
├── docs/
│   └── calendar_api.md          ← 日历接口文档
├── lib/
├── assets/
├── cloudbase/
├── pubspec.yaml
└── ...
验证文件是否创建成功
bash
dir docs
应该看到 calendar_api.md 文件。

创建完成后，接口文档就在 docs/calendar_api.md，后续需要查阅时直接打开即可。

这不就是吗
对！这就是我们之前写的 api_service.dart，它已经包含了 HTTP 请求的基础封装（GET、POST、PUT）。

当前 api_service.dart 已有的功能
方法	功能	状态
get(path, query)	GET 请求	✅ 已有
post(path, body)	POST 请求	✅ 已有
put(path, body)	PUT 请求	✅ 已有
_buildHeaders()	构建请求头（含 Token）	✅ 已有
_handleResponse()	处理响应	✅ 已有
baseUrl	基础 URL	⚠️ 需要配置
现在需要做的
根据接口文档，在 api_service.dart 中添加日历模块的专用接口方法，方便日历页面调用：

dart
// ============ 日历模块接口 ============

/// 3.1 获取月历概览
static Future<Map<String, dynamic>> getMonthlyCalendar(String month) async {
  return get(
    '/api/v1/calendar/monthly',
    query: {'month': month},
  );
}

/// 3.2 获取日详情
static Future<Map<String, dynamic>> getDailyDetail(String date) async {
  return get(
    '/api/v1/calendar/daily',
    query: {'date': date},
  );
}

// ============ 记录模块接口 ============

/// 5.1 创建记录
static Future<Map<String, dynamic>> createRecord({
  required String date,
  required String content,
  List<String>? images,
  String? mood,
}) async {
  return post(
    '/api/v1/record/create',
    body: {
      'date': date,
      'content': content,
      'images': images ?? [],
      'mood': mood ?? 'happy',
    },
  );
}

// ============ 规划模块接口 ============

/// 4.1 创建规划
static Future<Map<String, dynamic>> createPlan({
  required String date,
  required String title,
  String? content,
  List<String>? images,
}) async {
  return post(
    '/api/v1/plan/create',
    body: {
      'date': date,
      'title': title,
      'content': content ?? '',
      'images': images ?? [],
    },
  );
}
需要我帮你把这些接口方法添加到 api_service.dart 中吗？
如果需要，直接告诉我，我生成完整的 api_service.dart 文件。

你给我搞迷糊了，这个到底放哪啊
哈哈抱歉，让我说清楚：

这个文件放这里
text
E:\HuaweiMoveData\Users\l1513\Desktop\lome\docs\calendar_api.md
两步操作
第1步：创建 docs 文件夹
bash
mkdir docs
第2步：创建文件
在 VS Code 中：

右键点击项目根目录的 docs 文件夹

选择 "新建文件"

命名为 calendar_api.md

把你那份文档内容粘贴进去

保存

最终效果
text
lome/
├── docs/
│   └── calendar_api.md    ← 放这里！
├── lib/
├── assets/
├── cloudbase/
└── ...
这样以后找接口文档就在 docs/calendar_api.md，不会丢了。需要我帮你把 api_service.dart 中的日历接口方法也补上吗？


# Lome 日历功能接口文档.txt
# Lome 日历功能接口文档

## 1. 基础约定

### 1.1 请求头

除登录外所有接口携带 Token：

```
Content-Type: application/json
Authorization: Bearer <token>
```

### 1.2 通用响应格式

```json
{
  "code": 0,
  "message": "success",
  "data": {}
}
```

### 1.3 数据格式

| 类型 | 格式 | 示例 |
| ------ | ------ | ------ |
| 日期 | `YYYY-MM-DD` | `2026-07-31` |
| 月份 | `YYYY-MM` | `2026-07` |
| 时间戳 | 毫秒 (UTC) | `1753718400000` |

### 1.4 日历相关错误码

| 错误码 | 含义 | 前端处理 |
| :--- | :--- | :--- |
| `7001` | 尚未绑定伴侣 | 提示跳转绑定流程 |
| `10001` | 规划不存在 | Toast「该规划已删除」 |
| `10002` | 记录不存在 | Toast「该记录已删除」 |
| `10003` | 重要日不存在 | Toast「该重要日已删除」 |
| `10004` | 重要日名称重复 | Toast「已有同名重要日」 |
| `9001` | 图片过大 | Toast「图片不能超过10MB」 |
| `9003` | 图片数量超限 | Toast「最多上传9张图片」 |

---

## 2. 功能概述

日历功能由三个页面组成，均需用户已绑定伴侣：

```
日历页（月视图）
  ├── 点击日期 → 日详情（记录列表 + 规划列表）
  ├── 记录按钮 → 记录页（当天）
  ├── 规划按钮 → 规划页（当天）
  └── 添加重要日
```

| 页面 | 设计稿 | 核心能力 |
| :--- | :--- | :--- |
| 日历页 | 图1 | 月历网格，三种标记点（记录/规划/重要日），滑动切换月份 |
| 规划页 | 图2 | 待办日程，支持文字+图片，打勾完成，双方可见 |
| 记录页 | 图3 | 日记/回忆，支持文字+图片+心情，双方共同编辑 |

---

## 3. 日历模块

### 3.1 获取月历概览

* **Method**: `GET`
* **Path**: `/api/v1/calendar/monthly`
* **Query**:

  | 参数 | 类型 | 必填 | 说明 |
  |------|------|------|------|
  | `month` | `string` | 是 | `YYYY-MM` |

* **Response（有数据）**:

  ```json
  {
    "code": 0,
    "data": {
      "month": "2026-07",
      "recordedDays": 12,
      "days": [
        {
          "date": "2026-07-15",
          "hasRecord": true,
          "hasPlan": true,
          "hasImportantDay": false,
          "planPendingCount": 2,
          "importantDayName": null
        },
        {
          "date": "2026-07-20",
          "hasRecord": false,
          "hasPlan": true,
          "hasImportantDay": true,
          "planPendingCount": 0,
          "importantDayName": "纪念日"
        }
      ]
    }
  }
  ```

  | 字段 | 类型 | 说明 |
  | ------ | ------ | ------ |
  | `month` | `string` | 查询月份 |
  | `recordedDays` | `integer` | 本月已记录天数 |
  | `days[].date` | `string` | 日期 |
  | `days[].hasRecord` | `boolean` | 有记录 → 日历格显示**薄荷圆点** |
  | `days[].hasPlan` | `boolean` | 有规划 → 日历格显示**浅粉圆点** |
  | `days[].hasImportantDay` | `boolean` | 是重要日 → 日历格显示**淡黄圆点** |
  | `days[].planPendingCount` | `integer` | 待打勾规划数 |
  | `days[].importantDayName` | `string\|null` | 重要日名称 |

* **空状态文案**：
  * `recordedDays === 0` → 前端展示：「本月的记录还是空的，要不要留下什么？」
  * 某日 `planPendingCount === 0` 且无规划 → 「本月还没有待办日程，我们要去哪里探险呢？」

### 3.2 获取日详情

点击日历某一天时调用，聚合返回当天的记录、规划、重要日。

* **Method**: `GET`
* **Path**: `/api/v1/calendar/daily`
* **Query**:

  | 参数 | 类型 | 必填 | 说明 |
  |------|------|------|------|
  | `date` | `string` | 是 | `YYYY-MM-DD` |

* **Response**:

  ```json
  {
    "code": 0,
    "data": {
      "date": "2026-07-15",
      "records": [
        {
          "recordId": "rec_001",
          "content": "今天一起去了海边 🌊",
          "images": ["https://cdn.example.com/img1.jpg"],
          "mood": "happy",
          "authorId": "u_123456",
          "authorNickname": "用户8975",
          "createTime": 1753718400000
        }
      ],
      "plans": [
        {
          "planId": "plan_001",
          "title": "晚上看电影",
          "completed": false,
          "authorId": "u_123456",
          "authorNickname": "用户8975"
        },
        {
          "planId": "plan_002",
          "title": "买花",
          "completed": true,
          "authorId": "u_654321",
          "authorNickname": "用户3787"
        }
      ],
      "planPendingCount": 1,
      "importantDay": null
    }
  }
  ```

  | 字段 | 类型 | 说明 |
  | ------ | ------ | ------ |
  | `records` | `array` | 当天记录列表 |
  | `records[].recordId` | `string` | 记录 ID |
  | `records[].content` | `string` | 文字内容 |
  | `records[].images` | `array<string>` | 图片 URL 列表 |
  | `records[].mood` | `string` | 心情：`happy`/`calm`/`sad`/`love`/`excited` |
  | `records[].authorId` | `string` | 作者 ID |
  | `records[].authorNickname` | `string` | 作者昵称 |
  | `plans` | `array` | 当天规划列表 |
  | `plans[].planId` | `string` | 规划 ID |
  | `plans[].title` | `string` | 规划标题 |
  | `plans[].completed` | `boolean` | 是否已完成 |
  | `plans[].authorId` | `string` | 创建者 ID |
  | `plans[].authorNickname` | `string` | 创建者昵称 |
  | `planPendingCount` | `integer` | 待完成规划数 |
  | `importantDay` | `object\|null` | 重要日详情，无则为 null |

---

## 4. 规划模块

> 对应设计稿图2：规划页。双方可创建、编辑、打勾完成。

### 4.1 创建规划

* **Method**: `POST`
* **Path**: `/api/v1/plan/create`

  | 字段 | 类型 | 必填 | 说明 |
  | ------ | ------ | ------ | ------ |
  | `date` | `string` | 是 | `YYYY-MM-DD` |
  | `title` | `string` | 是 | 最长 50 字 |
  | `content` | `string` | 否 | 详细内容，最长 500 字 |
  | `images` | `array<string>` | 否 | 图片 URL 列表，最多 9 张 |

  ```json
  {
    "date": "2026-07-31",
    "title": "一起去吃火锅",
    "content": "晚上7点老地方见 🍲",
    "images": []
  }
  ```

* **Response**:

  ```json
  {
    "code": 0,
    "message": "规划创建成功",
    "data": {
      "planId": "plan_003",
      "date": "2026-07-31",
      "title": "一起去吃火锅",
      "content": "晚上7点老地方见 🍲",
      "images": [],
      "completed": false,
      "createTime": 1753718400000
    }
  }
  ```

### 4.2 更新规划

* **Method**: `PUT`
* **Path**: `/api/v1/plan/update`

  | 字段 | 类型 | 必填 | 说明 |
  | ------ | ------ | ------ | ------ |
  | `planId` | `string` | 是 | 规划 ID |
  | `title` | `string` | 否 | 标题 |
  | `content` | `string` | 否 | 内容 |
  | `images` | `array<string>` | 否 | 传空数组 = 清空图片 |

  ```json
  {
    "planId": "plan_003",
    "title": "改成去吃海底捞",
    "content": "周六晚上8点",
    "images": []
  }
  ```

* **Response**: `{ "code": 0, "message": "规划更新成功", "data": null }`

### 4.3 切换完成状态（打勾）

> 对应规划页的「打勾按钮 — 圆形对号，透明底」

* **Method**: `PUT`
* **Path**: `/api/v1/plan/toggle`

  ```json
  { "planId": "plan_003", "completed": true }
  ```

* **Response**:

  ```json
  {
    "code": 0,
    "data": {
      "planId": "plan_003",
      "completed": true,
      "completedBy": "u_123456",
      "completedTime": 1753718400000
    }
  }
  ```

### 4.4 删除规划

* **Method**: `POST`
* **Path**: `/api/v1/plan/delete`
* **Body**: `{ "planId": "plan_003" }`
* **Response**: `{ "code": 0, "message": "规划已删除", "data": null }`

---

## 5. 记录模块

> 对应设计稿图3：记录页。伴侣双方的共同日记，支持文字、图片、心情。

### 5.1 创建记录

* **Method**: `POST`
* **Path**: `/api/v1/record/create`

  | 字段 | 类型 | 必填 | 说明 |
  | ------ | ------ | ------ | ------ |
  | `date` | `string` | 是 | `YYYY-MM-DD` |
  | `content` | `string` | 否 | 最长 2000 字 |
  | `images` | `array<string>` | 否 | 最多 9 张 |
  | `mood` | `string` | 否 | `happy`/`calm`/`sad`/`love`/`excited` |

  ```json
  {
    "date": "2026-07-31",
    "content": "今天一起看了日落，好美 🌅",
    "images": ["https://cdn.example.com/sunset1.jpg"],
    "mood": "happy"
  }
  ```

* **Response**:

  ```json
  {
    "code": 0,
    "message": "记录创建成功",
    "data": {
      "recordId": "rec_003",
      "date": "2026-07-31",
      "content": "今天一起看了日落，好美 🌅",
      "images": ["https://cdn.example.com/sunset1.jpg"],
      "mood": "happy",
      "createTime": 1753718400000
    }
  }
  ```

### 5.2 更新记录

* **Method**: `PUT`
* **Path**: `/api/v1/record/update`

  | 字段 | 类型 | 必填 | 说明 |
  | ------ | ------ | ------ | ------ |
  | `recordId` | `string` | 是 | 记录 ID |
  | `content` | `string` | 否 | 文字 |
  | `images` | `array<string>` | 否 | 传空数组 = 清空 |
  | `mood` | `string` | 否 | 心情 |

* **Response**: `{ "code": 0, "message": "记录更新成功", "data": null }`

### 5.3 删除记录

* **Method**: `POST`
* **Path**: `/api/v1/record/delete`
* **Body**: `{ "recordId": "rec_003" }`
* **Response**: `{ "code": 0, "message": "记录已删除", "data": null }`

---

## 6. 重要日模块

### 6.1 获取重要日列表

* **Method**: `GET`
* **Path**: `/api/v1/important-day/list`
* **Response**:

  ```json
  {
    "code": 0,
    "data": {
      "list": [
        {
          "importantDayId": "imp_001",
          "name": "恋爱纪念日",
          "date": "2025-03-15",
          "repeatType": "yearly",
          "icon": "heart",
          "createdBy": "u_123456"
        }
      ]
    }
  }
  ```

  | 字段 | 类型 | 说明 |
  | ------ | ------ | ------ |
  | `importantDayId` | `string` | ID |
  | `name` | `string` | 名称，最长 20 字 |
  | `date` | `string` | `YYYY-MM-DD`（`yearly` 时忽略年份） |
  | `repeatType` | `string` | `yearly`/`monthly`/`once` |
  | `icon` | `string` | `heart`/`cake`/`star`/`gift` |
  | `createdBy` | `string` | 创建者 ID |

### 6.2 添加重要日

* **Method**: `POST`
* **Path**: `/api/v1/important-day/create`

  ```json
  { "name": "初次相遇", "date": "2024-06-01", "repeatType": "yearly", "icon": "star" }
  ```

* **Response**: `{ "code": 0, "message": "重要日添加成功", "data": { "importantDayId": "imp_003" } }`

### 6.3 删除重要日

* **Method**: `POST`
* **Path**: `/api/v1/important-day/delete`
* **Body**: `{ "importantDayId": "imp_003" }`
* **Response**: `{ "code": 0, "message": "重要日已删除", "data": null }`

---

## 7. 图片上传（规划/记录共用）

* **Method**: `POST`
* **Path**: `/api/v1/upload/image`
* **Content-Type**: `multipart/form-data`

  | 字段 | 类型 | 必填 | 说明 |
  |------|------|------|------|
  | `file` | `file` | 是 | jpg/png/webp，最大 10MB |

* **Response**:

  ```json
  { "code": 0, "data": { "url": "https://cdn.example.com/uploads/img_abc.jpg" } }
  ```

---

## 8. 设计稿 UI 元素对照

### 日历页（图1）

| UI 元素 | 设计说明 | 数据来源 |
| :--- | :--- | :--- |
| 日历网格区 | 月视图，左右滑动切换月份 | `/calendar/monthly?month=` |
| 薄荷圆点 | 当天有记录 | `hasRecord: true` |
| 浅粉圆点 | 当天有规划 | `hasPlan: true` |
| 淡黄圆点 | 当天是重要日 | `hasImportantDay: true` |
| "本月已记录xx天" | 有记录时展示 | `recordedDays > 0` |
| "本月的记录还是空的…" | 空状态 | `recordedDays === 0` |
| "xx日行程待打勾" | 有待完成规划 | `planPendingCount > 0` |
| "本月还没有待办日程…" | 规划空状态 | 无规划数据 |
| 记录按钮 | 圆角透明玻璃，跳转记录页（当天） | — |
| 规划按钮 | 圆角透明玻璃，跳转规划页（当天） | — |
| 添加重要日按钮 | 弹出添加表单 | `/important-day/create` |

### 规划页（图2）

| UI 元素 | 设计说明 | 对应接口 |
| :--- | :--- | :--- |
| 日期栏 | 显示当前日期 | — |
| 打勾按钮 | 圆形对号，透明底 | `PUT /plan/toggle` |
| 方形圆角区域 | 内容展示区 | `title` + `content` |
| 编辑文字按钮 | 圆形加号，透明 | 唤起文字编辑 |
| 添加图片按钮 | 圆形加号，透明 | `POST /upload/image` |
| 添加贴纸按钮 | 圆形，透明，**占位先不做** | 预留 |
| 保存按钮 | 圆形，透明 | `POST /plan/create` 或 `PUT /plan/update` |

### 记录页（图3）

| UI 元素 | 设计说明 | 对应接口 |
| :--- | :--- | :--- |
| 日期栏 | 显示当前日期 | — |
| 方形圆角区域 | 内容展示区 | `content` + `images` |
| 编辑文字按钮 | 圆形加号，透明 | 唤起文字编辑 |
| 添加图片按钮 | 圆形加号，透明 | `POST /upload/image` |
| 添加贴纸按钮 | 圆形，透明，**占位先不做** | 预留 |
| 保存按钮 | 圆形，透明 | `POST /record/create` 或 `PUT /record/update` |

---

## 附录：接口汇总

| 模块 | Method | Path | 说明 |
| :--- | :--- | :--- | :--- |
| 日历 | `GET` | `/api/v1/calendar/monthly` | 月历概览 |
| 日历 | `GET` | `/api/v1/calendar/daily` | 日详情聚合 |
| 规划 | `POST` | `/api/v1/plan/create` | 创建规划 |
| 规划 | `PUT` | `/api/v1/plan/update` | 更新规划 |
| 规划 | `PUT` | `/api/v1/plan/toggle` | 打勾/取消完成 |
| 规划 | `POST` | `/api/v1/plan/delete` | 删除规划 |
| 记录 | `POST` | `/api/v1/record/create` | 创建记录 |
| 记录 | `PUT` | `/api/v1/record/update` | 更新记录 |
| 记录 | `POST` | `/api/v1/record/delete` | 删除记录 |
| 重要日 | `GET` | `/api/v1/important-day/list` | 重要日列表 |
| 重要日 | `POST` | `/api/v1/important-day/create` | 添加重要日 |
| 重要日 | `POST` | `/api/v1/important-day/delete` | 删除重要日 |
| 上传 | `POST` | `/api/v1/upload/image` | 上传图片 |
