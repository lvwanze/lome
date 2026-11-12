const cloudbase = require('@cloudbase/node-sdk');
const jwt = require('jsonwebtoken');
const { randomUUID } = require('node:crypto');
const { createStore } = require('./slow_letter_store');
const { createCrypto } = require('./slow_letter_crypto');
const { createLetterService } = require('./slow_letter_core');
const { createRelationships, BusinessError, fail } = require('./relationship_core');

function response(payload, binary) {
  return {
    statusCode: 200, isBase64Encoded: !!binary,
    headers: { 'content-type': binary ? binary.mimeType : 'application/json; charset=utf-8', 'cache-control': 'no-store', 'x-content-type-options': 'nosniff' },
    body: binary ? binary.bytes.toString('base64') : JSON.stringify(payload),
  };
}

function makeHandler(action, method, dependencies = {}) {
  let store = dependencies.store, service = dependencies.service;
  let relationships = store ? createRelationships(store) : undefined;
  return async (event = {}) => {
    const requestId = `req_${randomUUID()}`;
    try {
      if (!store) {
        if (!process.env.ENV_ID) throw new Error('ENV_ID 未配置');
        store = createStore(cloudbase.init({ env: process.env.ENV_ID }));
        relationships = createRelationships(store);
      }
      const actualMethod = event.httpMethod || event.requestContext?.httpMethod;
      if (actualMethod && actualMethod !== method) fail(400, '请求方法不支持');
      if (action === 'cleanup') {
        if (event.Type !== 'Timer' || event.TriggerName !== 'slow-letter-attachment-cleanup') fail(4001, '只允许维护触发器调用');
      }
      const headers = Object.fromEntries(Object.entries(event.headers || {}).map(([key, value]) => [key.toLowerCase(), value]));
      let userId;
      if (action !== 'cleanup') {
        const authorization = headers.authorization || (!actualMethod && ['bind', 'unbind'].includes(action) && typeof event.token === 'string' ? `Bearer ${event.token}` : '');
        const match = typeof authorization === 'string' && authorization.match(/^Bearer\s+(\S+)$/i);
        if (!match || !process.env.JWT_SECRET) fail(4001, '未登录或 Token 无效');
        let token;
        try { token = jwt.verify(match[1], process.env.JWT_SECRET, { algorithms: ['HS256'] }); } catch { fail(4001, 'Token 无效或已过期'); }
        if (typeof token.userId !== 'string' || !/^[a-zA-Z0-9_-]{1,160}$/.test(token.userId)) fail(4001, 'Token 无效');
        userId = token.userId;
      }
      let params = {};
      if (method === 'GET') params = event.queryStringParameters || {};
      else if (action !== 'upload' && action !== 'cleanup') {
        try {
          if (typeof event.body === 'string' && Buffer.byteLength(event.body) > 96 * 1024) fail(400, '请求体过大');
          params = typeof event.body === 'string' ? JSON.parse(event.body) : event.body || (!actualMethod && action === 'bind' ? { bindCode: event.bindCode } : {});
        } catch (error) { if (error instanceof BusinessError) throw error; fail(400, 'JSON 请求体无效'); }
        if (!params || typeof params !== 'object' || Array.isArray(params)) fail(400, '请求体必须是 JSON 对象');
      }
      let result;
      if (action === 'bind') result = await relationships.bind(userId, params.bindCode);
      else if (action === 'unbind') result = await relationships.unbind(userId);
      else {
        if (!service) service = createLetterService({ store, crypt: createCrypto(JSON.parse(process.env.LETTER_MASTER_KEYS || '{}'), process.env.LETTER_ACTIVE_KEY_VERSION) });
        if (action === 'upload') {
          if (event.queryStringParameters && Object.keys(event.queryStringParameters).some((key) => key !== 'fileName')) fail(400, '上传查询参数无效');
          let bytes;
          if (event.isBase64Encoded === true && typeof event.body === 'string' && event.body.length % 4 === 0 && event.body.length <= Math.ceil(2 * 1024 * 1024 / 3) * 4 && /^[A-Za-z0-9+/]*={0,2}$/.test(event.body)) {
            bytes = Buffer.from(event.body, 'base64');
            if (bytes.toString('base64') !== event.body) fail(12003, '图片编码无效');
          }
          else if (Buffer.isBuffer(event.body)) bytes = event.body;
          else fail(12003, '请使用图片原始二进制上传');
          result = await service.upload(userId, bytes, String(headers['content-type'] || '').split(';')[0].toLowerCase());
        } else if (action === 'cleanup') result = await service.cleanup();
        else result = await service[action](userId, params);
      }
      if (action === 'attachment') return response(null, result);
      const payload = { code: 0, message: action === 'send' ? '寄出成功' : 'success', data: result, requestId };
      return actualMethod ? response(payload) : payload;
    } catch (error) {
      if (!(error instanceof BusinessError)) console.error(JSON.stringify({ requestId, action, errorType: error.name, code: String(error.code || 'INTERNAL').slice(0, 80) }));
      const payload = { code: error instanceof BusinessError ? error.code : 500, message: error instanceof BusinessError ? error.message : '服务器内部错误', data: null, requestId };
      return event.httpMethod || event.requestContext?.httpMethod ? response(payload) : payload;
    }
  };
}

module.exports = { makeHandler };
