// 公共工具：参数解析 + JWT 鉴权（与现有 login/interaction 云函数保持一致）
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

// 记录/规划/重要日是否属于当前用户或伴侣（双人共享数据）
function inCoupleScope(doc, userId) {
  return doc.authorId === userId || doc.partnerId === userId;
}

module.exports = { app, db, _, getParams, getUserId, getAuthUser, firstDoc, isValidDate, inCoupleScope };
