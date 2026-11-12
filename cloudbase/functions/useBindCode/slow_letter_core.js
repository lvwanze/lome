const { createHash, randomUUID } = require('node:crypto');
const { createRelationships, RELATIONSHIPS, fail } = require('./relationship_core');

const LETTERS = 'slow_letters';
const ATTACHMENTS = 'slow_letter_attachments';
const DAY = 86400000;
const APPEARANCE = Object.freeze({ stampId: 'stamp_default_v1', paperId: 'paper_default_v1', sealId: 'seal_default_v1', envelopeId: 'envelope_default_v1' });
const segmenter = new Intl.Segmenter('zh', { granularity: 'grapheme' });
const graphemes = (value) => Array.from(segmenter.segment(value), (item) => item.segment);
const countContent = (value) => graphemes(value).filter((value) => !/^\s+$/u.test(value)).length;
const hash = (value) => createHash('sha256').update(value).digest('hex');
const id = (value) => typeof value === 'string' && /^[a-zA-Z0-9_-]{1,160}$/.test(value);
const allowed = (value, keys) => {
  if (!value || typeof value !== 'object' || Array.isArray(value) || Object.keys(value).some((key) => !keys.includes(key))) fail(400, '请求参数不合法');
};
const stageOf = (letter, time) => letter.arriveTime > time ? 'in_transit' : 'archive';
const stateOf = (letter, time) => stageOf(letter, time) === 'in_transit' ? null : letter.openedAt === null ? 'unread' : 'opened';

function parseArrival(value) {
  if (typeof value !== 'string' || !/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d{1,3})?(?:Z|[+-]\d{2}:\d{2})$/.test(value)) fail(12008, '请选择带时区的有效送达时间');
  const [year, month, day] = value.slice(0, 10).split('-').map(Number);
  const calendar = new Date(Date.UTC(year, month - 1, day));
  const offset = value.match(/([+-])(\d{2}):(\d{2})$/);
  if (calendar.getUTCFullYear() !== year || calendar.getUTCMonth() !== month - 1 || calendar.getUTCDate() !== day || Number(value.slice(11, 13)) > 23 || Number(value.slice(14, 16)) > 59 || Number(value.slice(17, 19)) > 59 || (offset && (Number(offset[2]) > 23 || Number(offset[3]) > 59))) fail(12008, '送达日期无效');
  const result = Date.parse(value);
  if (!Number.isFinite(result)) fail(12008, '送达日期无效');
  return result;
}

function imageInfo(bytes) {
  let mimeType, width, height;
  if (bytes.length >= 33 && bytes.subarray(0, 8).equals(Buffer.from('89504e470d0a1a0a', 'hex')) && bytes.toString('ascii', 12, 16) === 'IHDR' && bytes.toString('ascii', bytes.length - 8, bytes.length - 4) === 'IEND') {
    mimeType = 'image/png'; width = bytes.readUInt32BE(16); height = bytes.readUInt32BE(20);
  } else if (bytes.length > 12 && bytes.readUInt16BE(0) === 0xffd8 && bytes.readUInt16BE(bytes.length - 2) === 0xffd9) {
    mimeType = 'image/jpeg';
    let position = 2;
    while (position + 4 < bytes.length) {
      if (bytes[position++] !== 0xff) break;
      while (bytes[position] === 0xff) position++;
      const marker = bytes[position++];
      if (marker === 0xda || marker === 0xd9) break;
      if (marker === 0x01 || (marker >= 0xd0 && marker <= 0xd7)) continue;
      const length = bytes.readUInt16BE(position);
      if (length < 2 || position + length > bytes.length) break;
      if ([0xc0, 0xc1, 0xc2, 0xc3, 0xc5, 0xc6, 0xc7, 0xc9, 0xca, 0xcb, 0xcd, 0xce, 0xcf].includes(marker) && length >= 7) {
        height = bytes.readUInt16BE(position + 3); width = bytes.readUInt16BE(position + 5); break;
      }
      position += length;
    }
  } else if (bytes.length >= 30 && bytes.toString('ascii', 0, 4) === 'RIFF' && bytes.toString('ascii', 8, 12) === 'WEBP' && bytes.readUInt32LE(4) + 8 === bytes.length) {
    mimeType = 'image/webp';
    const format = bytes.toString('ascii', 12, 16);
    if (format === 'VP8X') { width = bytes.readUIntLE(24, 3) + 1; height = bytes.readUIntLE(27, 3) + 1; }
    else if (format === 'VP8L' && bytes[20] === 0x2f) { const dimensions = bytes.readUInt32LE(21); width = (dimensions & 0x3fff) + 1; height = ((dimensions >>> 14) & 0x3fff) + 1; }
    else if (format === 'VP8 ' && bytes.subarray(23, 26).equals(Buffer.from('9d012a', 'hex'))) { width = bytes.readUInt16LE(26) & 0x3fff; height = bytes.readUInt16LE(28) & 0x3fff; }
  }
  if (!mimeType || !width || !height || width > 8192 || height > 8192 || width * height > 16000000) fail(12003, '图片格式或像素尺寸无效');
  return { mimeType, width, height };
}

function createLetterService({ store, crypt, now = Date.now }) {
  const relationships = createRelationships(store, now);
  const readPayload = (letter) => JSON.parse(crypt.decrypt(letter.sealed, `letter:${letter._id}`).toString('utf8'));
  const safeUser = (user) => ({ userId: user._id, nickname: user.nickname || '' });
  function scope(context, box) {
    return { relationshipId: context.relationshipId, senderId: box === 'sent' ? context.user._id : context.partner._id, receiverId: box === 'sent' ? context.partner._id : context.user._id };
  }
  function filterStage(base, stage, time) {
    return stage === 'all' ? base : { ...base, arriveTime: stage === 'in_transit' ? { $gt: time } : { $lte: time } };
  }
  function envelope(letter, context, time) {
    const sent = letter.senderId === context.user._id;
    return {
      letterId: letter._id, relationshipId: letter.relationshipId, letterNo: letter.letterNo,
      direction: sent ? 'sent' : 'received', stage: stageOf(letter, time), readState: stateOf(letter, time),
      sender: safeUser(sent ? context.user : context.partner), receiver: safeUser(sent ? context.partner : context.user),
      recipientLabel: letter.recipientLabel, appearance: letter.appearance, createTime: letter.createTime,
      arriveTime: letter.arriveTime, openedAt: letter.openedAt,
      title: sent || letter.openedAt !== null ? readPayload(letter).title : null,
      hasAttachment: !!letter.attachmentId, replyToLetterId: sent || letter.arriveTime <= time ? letter.replyToLetterId : null,
    };
  }
  async function visible(letterId, context, transaction) {
    if (!id(letterId)) fail(400, 'letterId 格式错误');
    const letter = await store.get(LETTERS, letterId, transaction);
    if (!letter || letter.relationshipId !== context.relationshipId || ![context.user._id, context.partner._id].includes(letter.senderId) || ![context.user._id, context.partner._id].includes(letter.receiverId) || letter.senderId === letter.receiverId) fail(12002, '信件不可用');
    return letter;
  }
  function requireArrival(letter, userId) {
    if (letter.receiverId === userId && now() < letter.arriveTime) fail(12001, '信件尚未到达');
  }
  function sendResult(letter) {
    return { letterId: letter._id, relationshipId: letter.relationshipId, letterNo: letter.letterNo, senderId: letter.senderId, receiverId: letter.receiverId, recipientLabel: letter.recipientLabel, appearance: letter.appearance, createTime: letter.createTime, arriveTime: letter.arriveTime, stage: 'in_transit', readState: null };
  }
  return {
    async overview(userId, params) {
      allowed(params, []);
      const context = await relationships.authorize(userId);
      const time = now();
      const sent = scope(context, 'sent'), received = scope(context, 'received');
      const unread = { ...filterStage(received, 'archive', time), openedAt: null };
      const values = await Promise.all([
        store.count(LETTERS, filterStage(sent, 'in_transit', time)), store.count(LETTERS, filterStage(sent, 'archive', time)),
        store.count(LETTERS, filterStage(received, 'in_transit', time)), store.count(LETTERS, filterStage(received, 'archive', time)),
        store.count(LETTERS, unread), store.query(LETTERS, unread, { order: [['arriveTime', 'desc'], ['createTime', 'desc'], ['_id', 'desc']], limit: 1 }),
      ]);
      const latest = values[5][0];
      return { serverTime: time, relationshipId: context.relationshipId, partner: safeUser(context.partner), counts: { sentInTransit: values[0], sentArchive: values[1], receivedInTransit: values[2], receivedArchive: values[3], receivedUnread: values[4] }, latestArrivedUnread: latest ? { letterId: latest._id, letterNo: latest.letterNo, senderNickname: context.partner.nickname || '', recipientLabel: latest.recipientLabel, appearance: latest.appearance, arriveTime: latest.arriveTime } : null };
    },
    async list(userId, params) {
      allowed(params, ['box', 'stage', 'limit', 'cursor']);
      const box = params.box, stage = params.stage === undefined ? 'all' : params.stage;
      const limit = params.limit === undefined ? 20 : Number(params.limit);
      if (!['sent', 'received'].includes(box) || !['in_transit', 'archive', 'all'].includes(stage) || !Number.isInteger(limit) || limit < 1 || limit > 50) fail(400, '列表查询参数错误');
      const context = await relationships.authorize(userId);
      const time = now();
      let filter = filterStage(scope(context, box), stage, time);
      if (params.cursor !== undefined) {
        let cursor;
        try { cursor = crypt.verify(params.cursor, 'letter-cursor'); } catch { fail(400, '分页游标无效'); }
        if (cursor.userId !== userId || cursor.relationshipId !== context.relationshipId || cursor.box !== box || cursor.stage !== stage || cursor.expiresAt <= time || !Number.isSafeInteger(cursor.createTime) || !id(cursor.letterId)) fail(400, '分页游标不匹配或已过期');
        filter = { ...filter, $or: [{ createTime: { $lt: cursor.createTime } }, { createTime: cursor.createTime, _id: { $lt: cursor.letterId } }] };
      }
      const letters = await store.query(LETTERS, filter, { order: [['createTime', 'desc'], ['_id', 'desc']], limit: limit + 1 });
      const hasMore = letters.length > limit, page = letters.slice(0, limit), last = page[page.length - 1];
      return { serverTime: time, items: page.map((letter) => envelope(letter, context, time)), hasMore, nextCursor: hasMore ? crypt.sign({ userId, relationshipId: context.relationshipId, box, stage, createTime: last.createTime, letterId: last._id, expiresAt: time + DAY }, 'letter-cursor') : null };
    },
    async detail(userId, params) {
      allowed(params, ['letterId', 'scope']);
      const stage = params.scope === undefined ? 'all' : params.scope;
      if (!['in_transit', 'archive', 'all'].includes(stage)) fail(400, 'scope 参数错误');
      const context = await relationships.authorize(userId), time = now();
      const letter = await visible(params.letterId, context);
      const filter = filterStage(scope(context, letter.senderId === userId ? 'sent' : 'received'), stage, time);
      const neighbours = await Promise.all(['gt', 'lt'].map((op) => store.query(LETTERS, { ...filter, $or: [{ createTime: { [`$${op}`]: letter.createTime } }, { createTime: letter.createTime, _id: { [`$${op}`]: letter._id } }] }, { order: [['createTime', op === 'gt' ? 'asc' : 'desc'], ['_id', op === 'gt' ? 'asc' : 'desc']], limit: 1 })));
      return { serverTime: time, letter: envelope(letter, context, time), canViewContent: letter.senderId === userId || time >= letter.arriveTime, canAcknowledgeRead: letter.receiverId === userId && time >= letter.arriveTime && letter.openedAt === null, navigation: { scope: stage, scopeMatched: stage === 'all' || stageOf(letter, time) === stage, previousLetterId: neighbours[0][0]?._id || null, nextLetterId: neighbours[1][0]?._id || null } };
    },
    async send(userId, params) {
      allowed(params, ['clientRequestId', 'expectedPartnerId', 'title', 'content', 'recipientLabel', 'appearance', 'arriveAt', 'attachmentId', 'replyToLetterId']);
      if (typeof params.clientRequestId !== 'string' || !/^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(params.clientRequestId) || !id(params.expectedPartnerId)) fail(400, '幂等键或预期伴侣参数错误');
      if (typeof params.title !== 'string' || !params.title.trim() || graphemes(params.title.trim()).length > 60 || typeof params.content !== 'string' || Buffer.byteLength(params.content) > 65536 || countContent(params.content) < 200 || countContent(params.content) > 5000) fail(12004, '标题须为 1～60 字，正文须为 200～5000 个有效字符');
      if (params.recipientLabel !== undefined && (typeof params.recipientLabel !== 'string' || !params.recipientLabel.trim() || graphemes(params.recipientLabel.trim()).length > 20 || /[\p{Cc}\p{Zl}\p{Zp}]/u.test(params.recipientLabel))) fail(12010, '请填写 1～20 字的单行称呼');
      const appearance = params.appearance === undefined ? { ...APPEARANCE } : params.appearance;
      if (!appearance || typeof appearance !== 'object' || Object.keys(appearance).length !== 4 || Object.entries(APPEARANCE).some(([key, value]) => appearance[key] !== value)) fail(12009, '样式参数无效');
      const arriveTime = parseArrival(params.arriveAt);
      const letterId = `ltr_${hash(`${userId}:${params.clientRequestId.toLowerCase()}`).slice(0, 40)}`;
      const requestHash = hash(JSON.stringify([params.expectedPartnerId, params.title.trim(), params.content, params.recipientLabel === undefined ? null : params.recipientLabel.trim(), Object.entries(APPEARANCE).map(([key]) => appearance[key]), params.arriveAt, params.attachmentId || null, params.replyToLetterId || null]));
      return store.transaction(async (transaction) => {
        const context = await relationships.current(userId, transaction);
        if (params.expectedPartnerId !== context.partner._id) fail(7001, '伴侣关系已变化，请重新确认收信对象');
        const existing = await store.get(LETTERS, letterId, transaction);
        if (existing) {
          if (existing.requestHash !== requestHash || existing.relationshipId !== context.relationshipId) fail(12005, '幂等键已用于其他寄信内容或关系');
          return sendResult(existing);
        }
        const time = now(), maximum = new Date(time); maximum.setUTCFullYear(maximum.getUTCFullYear() + 5);
        if (arriveTime < time + DAY || arriveTime > maximum.getTime()) fail(12008, '送达时间须至少延后 24 小时且不超过 5 年');
        let attachment = null;
        if (params.attachmentId !== undefined && params.attachmentId !== null) {
          if (!id(params.attachmentId)) fail(12003, '附件参数无效');
          attachment = await store.get(ATTACHMENTS, params.attachmentId, transaction);
          if (!attachment || attachment.ownerId !== userId || attachment.relationshipId !== context.relationshipId || attachment.state !== 'pending' || attachment.expiresAt <= time) fail(12003, '附件不存在、已关联或已过期');
        }
        if (params.replyToLetterId !== undefined && params.replyToLetterId !== null) {
          if (!id(params.replyToLetterId)) fail(12006, '回信目标无效');
          const parent = await store.get(LETTERS, params.replyToLetterId, transaction);
          if (!parent || parent.relationshipId !== context.relationshipId || parent.receiverId !== userId || parent.senderId !== context.partner._id || parent.openedAt === null || parent.arriveTime > time) fail(12006, '只能回复已拆阅的当前伴侣来信');
        }
        const sequence = context.relationship.letterSequence + 1;
        if (!Number.isSafeInteger(sequence) || sequence < 1) throw new Error('关系序列配置无效');
        const defaultLabel = context.partner.nickname && graphemes(context.partner.nickname.trim()).length <= 20 ? context.partner.nickname.trim() : '亲爱的你';
        const letter = { _id: letterId, schemaVersion: 1, relationshipId: context.relationshipId, sequence, letterNo: `MX · ${String(sequence).padStart(4, '0')}`, senderId: userId, receiverId: context.partner._id, createTime: time, arriveTime, openedAt: null, recipientLabel: params.recipientLabel === undefined ? defaultLabel : params.recipientLabel.trim(), appearance: { ...appearance }, attachmentId: attachment?._id || null, replyToLetterId: params.replyToLetterId || null, requestHash, sealed: crypt.encrypt(Buffer.from(JSON.stringify({ title: params.title.trim(), content: params.content })), `letter:${letterId}`) };
        const { _id, ...stored } = letter;
        await store.put(LETTERS, letterId, stored, transaction);
        await store.update(RELATIONSHIPS, context.relationshipId, { letterSequence: sequence }, transaction);
        if (attachment) await store.update(ATTACHMENTS, attachment._id, { state: 'attached', letterId, expiresAt: null }, transaction);
        return sendResult(letter);
      });
    },
    async content(userId, params) {
      allowed(params, ['letterId']);
      const context = await relationships.authorize(userId), letter = await visible(params.letterId, context);
      requireArrival(letter, userId);
      const attachment = letter.attachmentId ? await store.get(ATTACHMENTS, letter.attachmentId) : null;
      if (letter.attachmentId && (!attachment || attachment.letterId !== letter._id)) throw new Error('信件附件关联损坏');
      const expiresAt = now() + 600000, needsReceipt = letter.receiverId === userId && letter.openedAt === null;
      return { letterId: letter._id, relationshipId: letter.relationshipId, ...readPayload(letter), recipientLabel: letter.recipientLabel, appearance: letter.appearance, attachment: attachment ? { attachmentId: attachment._id, mimeType: attachment.mimeType } : null, viewToken: needsReceipt ? crypt.sign({ userId, relationshipId: context.relationshipId, letterId: letter._id, expiresAt }, 'letter-read') : null, viewTokenExpiresAt: needsReceipt ? expiresAt : null };
    },
    async read(userId, params) {
      allowed(params, ['letterId', 'viewToken']);
      return store.transaction(async (transaction) => {
        const context = await relationships.current(userId, transaction), letter = await visible(params.letterId, context, transaction);
        if (letter.receiverId !== userId) fail(12002, '信件不可用');
        requireArrival(letter, userId);
        if (letter.openedAt !== null) return { letterId: letter._id, readState: 'opened', openedAt: letter.openedAt, firstOpen: false };
        let proof;
        try { proof = crypt.verify(params.viewToken, 'letter-read'); } catch { fail(12007, '阅读凭证无效或已过期'); }
        if (proof.userId !== userId || proof.relationshipId !== context.relationshipId || proof.letterId !== letter._id || !Number.isFinite(proof.expiresAt) || proof.expiresAt <= now()) fail(12007, '阅读凭证无效或已过期');
        const openedAt = now();
        await store.update(LETTERS, letter._id, { openedAt }, transaction);
        return { letterId: letter._id, readState: 'opened', openedAt, firstOpen: true };
      });
    },
    async upload(userId, bytes, contentType) {
      const context = await relationships.authorize(userId);
      if (!Buffer.isBuffer(bytes) || !bytes.length || bytes.length > 2 * 1024 * 1024) fail(12003, '图片不能为空且不能超过 2 MiB');
      const info = imageInfo(bytes);
      if (contentType !== info.mimeType) fail(12003, '图片真实格式与 Content-Type 不一致');
      const attachmentId = `att_${randomUUID()}`, expiresAt = now() + DAY;
      const encrypted = crypt.encrypt(bytes, `attachment:${attachmentId}`);
      const ciphertext = Buffer.from(encrypted.ciphertext, 'base64'); delete encrypted.ciphertext;
      const fileId = await store.upload(`slow-letters/${attachmentId}.bin`, ciphertext);
      try {
        await store.put(ATTACHMENTS, attachmentId, { ownerId: userId, relationshipId: context.relationshipId, mimeType: info.mimeType, sizeBytes: bytes.length, width: info.width, height: info.height, fileId, encrypted, state: 'pending', letterId: null, createTime: now(), expiresAt });
      } catch (error) { await store.deleteFile(fileId); throw error; }
      return { attachmentId, mimeType: info.mimeType, sizeBytes: bytes.length, expiresAt };
    },
    async attachment(userId, params) {
      allowed(params, ['letterId', 'attachmentId']);
      const context = await relationships.authorize(userId), letter = await visible(params.letterId, context);
      requireArrival(letter, userId);
      if (!id(params.attachmentId) || params.attachmentId !== letter.attachmentId) fail(12003, '附件不可用');
      const attachment = await store.get(ATTACHMENTS, params.attachmentId);
      if (!attachment || attachment.letterId !== letter._id || attachment.state !== 'attached' || attachment.relationshipId !== context.relationshipId) fail(12003, '附件不可用');
      const ciphertext = await store.download(attachment.fileId);
      const bytes = crypt.decrypt({ ...attachment.encrypted, ciphertext: ciphertext.toString('base64') }, `attachment:${attachment._id}`);
      return { bytes, mimeType: attachment.mimeType };
    },
    async cleanup() {
      // 两阶段标记与发信事务争抢同一文档；删除存储失败时下轮继续清理，不删除正式附件。
      const candidates = await store.query(ATTACHMENTS, { state: 'pending', expiresAt: { $lte: now() } }, { limit: 50 });
      const retry = await store.query(ATTACHMENTS, { state: 'deleting' }, { limit: 50 });
      let removed = 0;
      for (const candidate of [...candidates, ...retry]) {
        const target = await store.transaction(async (transaction) => {
          const value = await store.get(ATTACHMENTS, candidate._id, transaction);
          if (!value || value.state === 'attached' || (value.state === 'pending' && value.expiresAt > now())) return null;
          await store.update(ATTACHMENTS, value._id, { state: 'deleting' }, transaction);
          return value;
        });
        if (!target) continue;
        await store.deleteFile(target.fileId);
        await store.remove(ATTACHMENTS, target._id);
        removed++;
      }
      return { removed };
    },
    relationships,
  };
}

module.exports = { createLetterService, LETTERS, ATTACHMENTS, APPEARANCE, countContent, imageInfo, parseArrival };
