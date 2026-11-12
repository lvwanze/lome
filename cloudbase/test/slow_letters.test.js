const { test } = require('node:test');
const assert = require('node:assert/strict');
const { randomBytes, randomUUID } = require('node:crypto');
const { createLetterService, APPEARANCE, LETTERS, ATTACHMENTS, countContent, parseArrival } = require('../functions/slow_letter_core');
const { createCrypto } = require('../functions/slow_letter_crypto');
const { RELATIONSHIPS } = require('../functions/relationship_core');

// 内存实现模拟事务串行化、回滚和数据库查询；不访问真实用户数据。
class MemoryStore {
  constructor() { this.collections = new Map(); this.files = new Map(); this.queue = Promise.resolve(); }
  collection(name) { if (!this.collections.has(name)) this.collections.set(name, new Map()); return this.collections.get(name); }
  async get(name, id) { const value = this.collection(name).get(id); return value ? structuredClone(value) : null; }
  async put(name, id, value) { this.collection(name).set(id, { ...structuredClone(value), _id: id }); }
  async update(name, id, value) { const original = await this.get(name, id); if (!original) throw new Error('不存在'); await this.put(name, id, { ...original, ...value }); }
  async remove(name, id) { this.collection(name).delete(id); }
  async transaction(callback) {
    const preceding = this.queue;
    let release; this.queue = new Promise((resolve) => { release = resolve; });
    await preceding;
    const snapshot = structuredClone(this.collections);
    try { return await callback({}); } catch (error) { this.collections = snapshot; throw error; } finally { release(); }
  }
  matches(value, filter) {
    return Object.entries(filter).every(([key, expected]) => {
      if (key === '$or') return expected.some((condition) => this.matches(value, condition));
      if (key === '$and') return expected.every((condition) => this.matches(value, condition));
      if (expected && typeof expected === 'object') return Object.entries(expected).every(([operator, operand]) => ({ $lt: () => value[key] < operand, $lte: () => value[key] <= operand, $gt: () => value[key] > operand, $gte: () => value[key] >= operand })[operator]());
      return value[key] === expected;
    });
  }
  async query(name, filter, { order = [], limit = 20 } = {}) {
    const values = [...this.collection(name).values()].filter((value) => this.matches(value, filter));
    values.sort((a, b) => {
      for (const [field, direction] of order) if (a[field] !== b[field]) return (a[field] < b[field] ? -1 : 1) * (direction === 'asc' ? 1 : -1);
      return 0;
    });
    return structuredClone(values.slice(0, limit));
  }
  async count(name, filter) { return [...this.collection(name).values()].filter((value) => this.matches(value, filter)).length; }
  async upload(path, bytes) { this.files.set(path, Buffer.from(bytes)); return path; }
  async download(path) { return this.files.get(path); }
  async deleteFile(path) { this.files.delete(path); }
}
const PNG = Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jN60AAAAASUVORK5CYII=', 'base64');
const rejectCode = (code) => (error) => error.code === code;
async function fixture() {
  const store = new MemoryStore();
  for (const [userId, partnerId] of [['a', 'b'], ['b', 'a'], ['c', 'd'], ['d', 'c']]) await store.put('users', userId, { partnerId, isBound: true, nickname: `称呼${userId}` });
  let time = Date.parse('2026-10-22T08:00:00Z');
  const crypt = createCrypto({ k1: randomBytes(32).toString('base64') }, 'k1');
  const service = createLetterService({ store, crypt, now: () => time });
  const params = (overrides = {}) => ({ clientRequestId: randomUUID(), expectedPartnerId: 'b', title: '写给你的信', content: '我们一起认真生活。'.repeat(30), arriveAt: new Date(time + 86400000).toISOString(), ...overrides });
  return { store, service, crypt, params, advance: (milliseconds) => { time += milliseconds; } };
}

test('旧绑定用户只初始化一条共享关系，双方共用序列', async () => {
  const { service, store, params } = await fixture();
  const a = await service.send('a', params());
  const b = await service.send('b', params({ expectedPartnerId: 'a' }));
  assert.equal(a.relationshipId, b.relationshipId);
  assert.equal(a.letterNo, 'MX · 0001'); assert.equal(b.letterNo, 'MX · 0002');
  assert.equal(store.collection(RELATIONSHIPS).size, 1);
});
test('并发双向寄信生成不重复连续序列，另一对情侣独立从 1 开始', async () => {
  const { service, params } = await fixture();
  const results = await Promise.all(Array.from({ length: 12 }, (_, index) => service.send(index % 2 ? 'b' : 'a', params({ expectedPartnerId: index % 2 ? 'a' : 'b' }))));
  assert.equal(new Set(results.map((item) => item.letterNo)).size, 12);
  assert.deepEqual(results.map((item) => item.letterNo).sort(), Array.from({ length: 12 }, (_, index) => `MX · ${String(index + 1).padStart(4, '0')}`));
  assert.equal((await service.send('c', params({ expectedPartnerId: 'd' }))).letterNo, 'MX · 0001');
});
test('并发重复提交返回同一信件且只消耗一个编号', async () => {
  const { service, params, store } = await fixture(); const input = params();
  const results = await Promise.all([service.send('a', input), service.send('a', input)]);
  assert.deepEqual(results[0], results[1]); assert.equal(store.collection(LETTERS).size, 1);
  assert.equal((await service.send('a', params())).letterNo, 'MX · 0002');
  await assert.rejects(service.send('a', { ...input, title: '修改标题' }), rejectCode(12005));
});
test('关系序列跨日不重置，超过四位后完整展示', async () => {
  const { service, store, params, advance } = await fixture();
  const context = await service.relationships.authorize('a');
  await store.update(RELATIONSHIPS, context.relationshipId, { letterSequence: 9998 });
  assert.equal((await service.send('a', params())).letterNo, 'MX · 9999');
  advance(86400000);
  assert.equal((await service.send('b', params({ expectedPartnerId: 'a' }))).letterNo, 'MX · 10000');
});
test('过了送达时间仍可用原幂等键找回首次寄出结果', async () => {
  const { service, params, advance } = await fixture(); const input = params();
  const original = await service.send('a', input); advance(2 * 86400000);
  assert.deepEqual(await service.send('a', input), original);
});
test('密文存储且在途列表、详情不会向收信人泄露正文、标题、附件 ID', async () => {
  const { service, params, store } = await fixture(); const sent = await service.send('a', params());
  const stored = await store.get(LETTERS, sent.letterId);
  assert.equal(stored.content, undefined); assert.equal(stored.title, undefined);
  assert.ok(!JSON.stringify(stored).includes('写给你的信'));
  const detail = await service.detail('b', { letterId: sent.letterId });
  assert.equal(detail.letter.title, null); assert.equal(detail.canViewContent, false);
  assert.equal(detail.letter.content, undefined); assert.equal(detail.letter.attachmentId, undefined);
  assert.equal((await service.list('b', { box: 'received' })).items[0].title, null);
});
test('寄件人随时回看，收件人提前取正文和图片被拒绝', async () => {
  const { service, params } = await fixture(); const sent = await service.send('a', params());
  assert.equal((await service.content('a', { letterId: sent.letterId })).viewToken, null);
  await assert.rejects(service.content('b', { letterId: sent.letterId }), rejectCode(12001));
  await assert.rejects(service.attachment('b', { letterId: sent.letterId, attachmentId: 'att_fake' }), rejectCode(12001));
  await assert.rejects(service.read('a', { letterId: sent.letterId }), rejectCode(12002));
});
test('到达边界可取正文，但只有阅读回执减少未读数；并发回执保留首次时间', async () => {
  const { service, params, advance } = await fixture(); const sent = await service.send('a', params());
  advance(86400000);
  assert.equal((await service.detail('b', { letterId: sent.letterId })).letter.readState, 'unread');
  const content = await service.content('b', { letterId: sent.letterId });
  assert.equal((await service.overview('b', {})).counts.receivedUnread, 1);
  const receipts = await Promise.all([service.read('b', { letterId: sent.letterId, viewToken: content.viewToken }), service.read('b', { letterId: sent.letterId, viewToken: content.viewToken })]);
  assert.deepEqual(receipts.map((item) => item.firstOpen), [true, false]);
  assert.equal(receipts[0].openedAt, receipts[1].openedAt);
  assert.equal((await service.overview('b', {})).counts.receivedUnread, 0);
});
test('错误、过期、跨信件和跨用户的阅读凭证不能确认拆信', async () => {
  const { service, params, advance } = await fixture();
  const first = await service.send('a', params()), second = await service.send('a', params()); advance(86400000);
  const content = await service.content('b', { letterId: first.letterId });
  await assert.rejects(service.read('b', { letterId: second.letterId, viewToken: content.viewToken }), rejectCode(12007));
  await assert.rejects(service.read('b', { letterId: first.letterId, viewToken: 'invalid' }), rejectCode(12007));
  advance(600001);
  await assert.rejects(service.read('b', { letterId: first.letterId, viewToken: content.viewToken }), rejectCode(12007));
});
test('称呼和样式永久冻结；无效称呼、样式与预期伴侣被拒绝', async () => {
  const { service, params, store } = await fixture(); const input = params();
  const sent = await service.send('a', input); await store.update('users', 'b', { nickname: '后来的昵称' });
  assert.equal((await service.content('a', { letterId: sent.letterId })).recipientLabel, '称呼b');
  assert.deepEqual((await service.send('a', input)).appearance, APPEARANCE);
  await assert.rejects(service.send('a', params({ recipientLabel: '\n名字' })), rejectCode(12010));
  await assert.rejects(service.send('a', params({ appearance: { paperId: 'fake' } })), rejectCode(12009));
  await assert.rejects(service.send('a', params({ expectedPartnerId: 'd' })), rejectCode(7001));
});
test('图片以密文保存，归属与送达验证后返回原始二进制', async () => {
  const { service, params, store, advance } = await fixture(); const uploaded = await service.upload('a', PNG, 'image/png');
  const metadata = await store.get(ATTACHMENTS, uploaded.attachmentId);
  assert.notDeepEqual(store.files.get(metadata.fileId), PNG);
  const sent = await service.send('a', params({ attachmentId: uploaded.attachmentId }));
  assert.deepEqual((await service.attachment('a', { letterId: sent.letterId, attachmentId: uploaded.attachmentId })).bytes, PNG);
  advance(86400000);
  assert.deepEqual((await service.attachment('b', { letterId: sent.letterId, attachmentId: uploaded.attachmentId })).bytes, PNG);
  await assert.rejects(service.attachment('c', { letterId: sent.letterId, attachmentId: uploaded.attachmentId }), rejectCode(12002));
});
test('同一图片并发关联只允许一封信成功；失败事务不消耗编号', async () => {
  const { service, params } = await fixture(); const uploaded = await service.upload('a', PNG, 'image/png');
  const results = await Promise.allSettled([service.send('a', params({ attachmentId: uploaded.attachmentId })), service.send('a', params({ attachmentId: uploaded.attachmentId }))]);
  assert.equal(results.filter((item) => item.status === 'fulfilled').length, 1);
  assert.equal((await service.send('a', params())).letterNo, 'MX · 0002');
});
test('拒绝伪造、类型不匹配、超大图片和他人附件', async () => {
  const { service, params } = await fixture();
  await assert.rejects(service.upload('a', Buffer.from('fake'), 'image/png'), rejectCode(12003));
  await assert.rejects(service.upload('a', PNG, 'image/jpeg'), rejectCode(12003));
  await assert.rejects(service.upload('a', Buffer.alloc(2 * 1024 * 1024 + 1), 'image/png'), rejectCode(12003));
  const uploaded = await service.upload('b', PNG, 'image/png');
  await assert.rejects(service.send('a', params({ attachmentId: uploaded.attachmentId })), rejectCode(12003));
});
test('清理过期暂存图片但保留正式信件附件，清理可重复执行', async () => {
  const { service, params, advance, store } = await fixture();
  const orphan = await service.upload('a', PNG, 'image/png'), attached = await service.upload('a', PNG, 'image/png');
  await service.send('a', params({ attachmentId: attached.attachmentId })); advance(86400001);
  assert.equal((await service.cleanup()).removed, 1); assert.equal(await store.get(ATTACHMENTS, orphan.attachmentId), null);
  assert.ok(await store.get(ATTACHMENTS, attached.attachmentId)); assert.equal((await service.cleanup()).removed, 0);
});
test('同毫秒多封信分页不重不漏，游标与用户、方向和过滤条件绑定', async () => {
  const { service, params } = await fixture(); await Promise.all(Array.from({ length: 5 }, () => service.send('a', params())));
  const first = await service.list('a', { box: 'sent', limit: 2 }); const second = await service.list('a', { box: 'sent', limit: 2, cursor: first.nextCursor });
  const third = await service.list('a', { box: 'sent', limit: 2, cursor: second.nextCursor });
  assert.equal(new Set([...first.items, ...second.items, ...third.items].map((item) => item.letterId)).size, 5);
  assert.equal(third.hasMore, false);
  await assert.rejects(service.list('b', { box: 'received', cursor: first.nextCursor }), rejectCode(400));
  await assert.rejects(service.list('a', { box: 'sent', stage: 'archive', cursor: first.nextCursor }), rejectCode(400));
});
test('左右邻居在完整数据范围内查询，不跨方向；在途变历史时提示范围变化', async () => {
  const { service, params, advance } = await fixture();
  const first = await service.send('a', params()); advance(1); const second = await service.send('a', params());
  await service.send('b', params({ expectedPartnerId: 'a' }));
  assert.equal((await service.detail('a', { letterId: second.letterId })).navigation.nextLetterId, first.letterId);
  assert.equal((await service.detail('a', { letterId: first.letterId })).navigation.previousLetterId, second.letterId);
  advance(86400000);
  assert.equal((await service.detail('a', { letterId: first.letterId, scope: 'in_transit' })).navigation.scopeMatched, false);
});
test('解绑保留旧关系序列和信件编号，重绑创建新关系并重新从 0001 开始', async () => {
  const { service, params, store } = await fixture(); const sent = await service.send('a', params());
  await service.relationships.unbind('a');
  assert.equal((await store.get(LETTERS, sent.letterId)).letterNo, 'MX · 0001');
  assert.equal((await store.get(RELATIONSHIPS, sent.relationshipId)).letterSequence, 1);
  await store.put('bindCodes', 'code1', { code: 'ABC123', userId: 'b', used: false, expireTime: Date.now() + 1e12 });
  const bound = await service.relationships.bind('a', 'ABC123');
  assert.notEqual(bound.relationshipId, sent.relationshipId);
  const next = await service.send('a', params()); assert.equal(next.letterNo, 'MX · 0001');
  assert.notEqual(next.letterId, sent.letterId);
  await assert.rejects(service.content('a', { letterId: sent.letterId }), rejectCode(12002));
  assert.equal((await store.get(LETTERS, sent.letterId)).letterNo, sent.letterNo);
});
test('回信只允许已拆阅的来信，且生成新慢信和新序号', async () => {
  const { service, params, advance } = await fixture(); const sent = await service.send('a', params());
  await assert.rejects(service.send('b', params({ expectedPartnerId: 'a', replyToLetterId: sent.letterId })), rejectCode(12006));
  advance(86400000); const content = await service.content('b', { letterId: sent.letterId });
  await service.read('b', { letterId: sent.letterId, viewToken: content.viewToken });
  assert.equal((await service.send('b', params({ expectedPartnerId: 'a', replyToLetterId: sent.letterId }))).letterNo, 'MX · 0002');
});
test('字数和送达日期按契约校验，组合 emoji 计为一个字符', async () => {
  assert.equal(countContent('你 👨‍👩‍👧‍👦\n好'), 3);
  assert.throws(() => parseArrival('2026-02-30T12:00:00+08:00'), rejectCode(12008));
  assert.throws(() => parseArrival('2026-10-23T12:00:00'), rejectCode(12008));
  const { service, params } = await fixture();
  await assert.rejects(service.send('a', params({ content: '字'.repeat(199) })), rejectCode(12004));
  await assert.rejects(service.send('a', params({ content: '字'.repeat(5001) })), rejectCode(12004));
  await assert.rejects(service.send('a', params({ arriveAt: '2026-10-22T09:00:00Z' })), rejectCode(12008));
  await assert.rejects(service.send('a', params({ receiverId: 'd' })), rejectCode(400));
});
test('密文不能跨信件重放，篡改认证标签无法解密', async () => {
  const { crypt } = await fixture(); const sealed = crypt.encrypt(Buffer.from('私密正文'), 'letter:a');
  assert.equal(crypt.decrypt(sealed, 'letter:a').toString(), '私密正文');
  assert.throws(() => crypt.decrypt(sealed, 'letter:b'));
  assert.throws(() => crypt.decrypt({ ...sealed, tag: randomBytes(16).toString('base64') }, 'letter:a'));
});

test('HTTP 入口校验登录和 JSON，并返回真实图片集成响应而非 base64 JSON', async () => {
  const jwt = require('jsonwebtoken');
  const { makeHandler } = require('../functions/slow_letter_runtime');
  const { store, service, params } = await fixture();
  process.env.JWT_SECRET = 'only-for-local-runtime-tests';
  const headers = { Authorization: `Bearer ${jwt.sign({ userId: 'a' }, process.env.JWT_SECRET)}` };
  const overview = makeHandler('overview', 'GET', { store, service });
  const unauthorized = await overview({ httpMethod: 'GET', headers: { 'x-cloudbase-context': 'never-echo', 'x-debug-secret': 'never-echo' } });
  assert.equal(JSON.parse(unauthorized.body).code, 4001); assert.ok(!unauthorized.body.includes('never-echo'));
  const send = makeHandler('send', 'POST', { store, service });
  assert.equal(JSON.parse((await send({ httpMethod: 'POST', headers, body: '{broken' })).body).code, 400);
  assert.equal(JSON.parse((await send({ httpMethod: 'GET', headers })).body).code, 400);
  const upload = makeHandler('upload', 'POST', { store, service });
  const uploaded = JSON.parse((await upload({ httpMethod: 'POST', headers: { ...headers, 'Content-Type': 'image/png' }, body: PNG.toString('base64'), isBase64Encoded: true })).body).data;
  const sent = JSON.parse((await send({ httpMethod: 'POST', headers, body: JSON.stringify(params({ attachmentId: uploaded.attachmentId })) })).body).data;
  const getImage = makeHandler('attachment', 'GET', { store, service });
  const image = await getImage({ httpMethod: 'GET', headers, queryStringParameters: { letterId: sent.letterId, attachmentId: uploaded.attachmentId } });
  assert.equal(image.isBase64Encoded, true); assert.equal(image.headers['content-type'], 'image/png');
  assert.deepEqual(Buffer.from(image.body, 'base64'), PNG); assert.equal(image.headers['cache-control'], 'no-store');
});

module.exports = { MemoryStore, PNG };
