// 公共工具：参数解析 + JWT 鉴权（与现有 login/interaction 云函数保持一致）
//
// ⚠️ 本文件是各云函数目录下 common.js 的唯一真源，位于 functions 根目录、不会被当成
//    函数打包。改完执行 `node cloudbase/tools/sync-common.js` 下发到 21 个函数目录。
const cloudbase = require('@cloudbase/node-sdk');
const jwt = require('jsonwebtoken');

const app = cloudbase.init({ env: process.env.ENV_ID });
const db = app.database();
const _ = db.command;

// 兼容 HTTP 访问服务(GET queryStringParameters / POST body)与 CLI 直接调用(event 根参数)
function getParams(event) {
  let body = {};
  if (typeof event.body === 'string') {
    try { body = JSON.parse(event.body); } catch (e) { body = {}; }
  } else if (event.body && typeof event.body === 'object') {
    body = event.body;
  }
  return Object.assign({}, event.queryStringParameters, body, event);
}

// 从 Authorization Bearer Token 中解析 userId，失败返回 { error }
function getUserId(event) {
  const headers = event.headers || {};
  const token = String(headers.authorization || headers.Authorization || '')
    .replace(/^Bearer\s+/i, '') || event.token;

  if (!token) {
    return { error: { code: 4001, message: '未登录' } };
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    if (!decoded.userId) {
      return { error: { code: 4001, message: 'Token无效或已过期' } };
    }
    return { userId: decoded.userId };
  } catch (e) {
    if (e.name === 'JsonWebTokenError' || e.name === 'TokenExpiredError') {
      return { error: { code: 4001, message: 'Token无效或已过期' } };
    }
    return { error: { code: 500, message: '服务器内部错误' } };
  }
}

// 鉴权 + 查询用户，返回 { userId, user, partnerId } 或 { error }
async function getAuthUser(event) {
  const { userId, error } = getUserId(event);
  if (error) return { error };

  try {
    const res = await db.collection('users').doc(userId).get();
    const user = firstDoc(res);
    if (!user) {
      return { error: { code: 4002, message: '用户不存在' } };
    }
    return { userId, user, partnerId: user.partnerId || null };
  } catch (e) {
    console.error('查询用户失败:', e);
    return { error: { code: 500, message: '服务器内部错误' } };
  }
}

// 兼容不同 SDK 版本的 doc().get() 返回结构（对象或数组）
function firstDoc(res) {
  if (!res || !res.data) return null;
  return Array.isArray(res.data) ? res.data[0] : res.data;
}

// 校验日期格式 YYYY-MM-DD
function isValidDate(date) {
  return typeof date === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(date);
}

// 记录/规划/重要日是否对当前用户可见。
// 规则：文档的 authorId 属于「我」或者「我当前的伴侣」。
//   · 一律用 users.partnerId 这个**实时**关系判断，不看文档里创建时冻结的 partnerId 快照：
//     - 绑定之前写的历史文档，伴侣也能看到（旧规则下这些文档 partnerId 为 null，伴侣永远看不到）
//     - 解绑之后 users.partnerId 被清空，前任立刻失去访问权（旧规则下前任永久可读）
//   · partnerId 缺省为 null —— 漏传的调用点退化成「只看自己」，
//     失败方向是更严格而不是更宽松。
function inCoupleScope(doc, userId, partnerId = null) {
  if (!doc) return false;
  return doc.authorId === userId || (!!partnerId && doc.authorId === partnerId);
}

// 把同一套可见性规则下推到数据库查询，避免把全表拉进内存再过滤。
// 用法：db.collection('records').where({ date, authorId: authorScope(userId, partnerId) })
function authorScope(userId, partnerId) {
  return _.in(partnerId ? [userId, partnerId] : [userId]);
}

// 把文档里 images 数组中的 cloud:// fileID 批量换成临时访问链接（云存储为私有，
// 前端无法直接用 fileID 渲染）。原地修改传入的文档数组。
//
// 返回的必须是**纯 URL 字符串**：Flutter 端 RecordData/PlanData 按 List<String> 解析
// images（.map((e) => e.toString())），早先返回 {fileId, url} 对象会被渲染成 Map 字符串。
// 非 cloud:// 的历史值（早期存进去的 http 链接）原样保留；
// 换链失败时同样保留原值而不是填 null —— 宁可给一个可能过期的链接，也不要把图片抹掉。
async function fillImageUrls(docs) {
  if (!Array.isArray(docs) || !docs.length) return;

  const fileIds = [];
  for (const d of docs) {
    for (const img of d.images || []) {
      if (typeof img === 'string' && img.startsWith('cloud://')) fileIds.push(img);
    }
  }
  if (!fileIds.length) return;

  const urlMap = {};
  try {
    // getTempFileURL 单次最多 50 个 fileID，超出要分批
    for (let i = 0; i < fileIds.length; i += 50) {
      const tmp = await app.getTempFileURL({ fileList: fileIds.slice(i, i + 50) });
      for (const item of tmp.fileList || []) {
        if (item && item.fileID && item.tempFileURL) {
          urlMap[item.fileID] = item.tempFileURL;
        }
      }
    }
  } catch (e) {
    console.warn('生成图片临时链接失败:', e.message);
    return;
  }

  for (const d of docs) {
    d.images = (d.images || []).map((img) =>
      typeof img === 'string' && img.startsWith('cloud://') && urlMap[img] ? urlMap[img] : img
    );
  }
}

module.exports = {
  app,
  db,
  _,
  getParams,
  getUserId,
  getAuthUser,
  firstDoc,
  isValidDate,
  inCoupleScope,
  authorScope,
  fillImageUrls,
};
