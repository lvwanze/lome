// 线上联调用独立合成用户；只删除本次精确记录的测试对象，不读取或改动真实用户信件。
const assert = require('node:assert/strict');
const { randomUUID, randomBytes, createHash } = require('node:crypto');
const jwt = require('jsonwebtoken');
const { connect, detailOf, variablesOf, DOMAIN, ROUTES } = require('./slow-letter-cloud');
// 使用标准 1x1 PNG；测试填充 tEXt 块用于验证 2 MiB 上限的真实网关收发。
const SMALL_PNG = Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jN60AAAAASUVORK5CYII=', 'base64');
function largePng() {
  const data = Buffer.alloc(2 * 1024 * 1024 - SMALL_PNG.length - 12, 120); data.write('Comment\0');
  const type = Buffer.from('tEXt'), payload = Buffer.concat([type, data]);
  let crc = 0xffffffff;
  for (const byte of payload) { crc ^= byte; for (let bit = 0; bit < 8; bit++) crc = (crc >>> 1) ^ ((crc & 1) ? 0xedb88320 : 0); }
  const length = Buffer.alloc(4); length.writeUInt32BE(data.length);
  const checksum = Buffer.alloc(4); checksum.writeUInt32BE((crc ^ 0xffffffff) >>> 0);
  return Buffer.concat([SMALL_PNG.subarray(0, -12), length, payload, checksum, SMALL_PNG.subarray(-12)]);
}

async function main(envId) {
  const client = await connect(envId);
  const prefix = `slow_test_${randomBytes(8).toString('hex')}`;
  const users = ['a', 'b', 'c', 'd'].map((suffix) => `${prefix}_${suffix}`);
  const letters = [], relationships = new Set(), attachments = [], codes = [];
  let assertions = 0;
  const check = (value, label) => { assert.ok(value, label); assertions++; console.log(`通过：${label}`); };
  const write = (collectionName, action, options) => client.call('writeNoSqlDatabaseContent', { action, collectionName, ...options });
  async function http(route, method, token, body, binary = false) {
    const result = await fetch(`https://${DOMAIN}${route}`, { method, headers: { ...(token ? { Authorization: `Bearer ${token}` } : {}), ...(body ? { 'Content-Type': binary ? 'image/png' : 'application/json' } : {}) }, ...(body ? { body: binary ? body : JSON.stringify(body) } : {}), signal: AbortSignal.timeout(45000) });
    if (result.headers.get('content-type')?.startsWith('image/')) return { image: Buffer.from(await result.arrayBuffer()), cacheControl: result.headers.get('cache-control') };
    const raw = await result.text();
    let parsed;
    try { parsed = JSON.parse(raw); } catch { throw new Error(`HTTP ${result.status} 非 JSON 响应，路径=${route}`); }
    return parsed;
  }
  const expect = async (route, method, token, body, expected = 0) => {
    const value = await http(route, method, token, body);
    assert.equal(value.code, expected, `${route} 业务码不符，追踪号=${value.requestId || '无'}`);
    return value.data;
  };
  try {
    const login = detailOf(await client.call('queryFunctions', { action: 'getFunctionDetail', functionName: 'login', revealEnvValues: true }));
    const secret = variablesOf(login).JWT_SECRET;
    const tokens = users.map((userId) => jwt.sign({ userId }, secret, { expiresIn: '20m' }));
    for (const [name, route] of Object.entries(ROUTES)) {
      const method = ['letterSend', 'letterContent', 'letterRead', 'letterAttachmentUpload'].includes(name) ? 'POST' : 'GET';
      await expect(route, method, null, method === 'POST' ? {} : undefined, 4001);
    }
    check(true, '8 条 HTTP 路由全部可达且拒绝未登录请求');
    await write('users', 'insert', { documents: users.map((userId, index) => ({ _id: userId, nickname: `慢信联调${index}`, isBound: true, partnerId: users[index ^ 1], createTime: Date.now(), testRunId: prefix })) });
    const a = await expect(ROUTES.letterOverview, 'GET', tokens[0]); relationships.add(a.relationshipId);
    const b = await expect(ROUTES.letterOverview, 'GET', tokens[1]);
    const c = await expect(ROUTES.letterOverview, 'GET', tokens[2]); relationships.add(c.relationshipId);
    check(a.relationshipId === b.relationshipId && a.relationshipId !== c.relationshipId, '旧绑定用户初始化关系，双向共享且情侣之间隔离');
    const image = largePng();
    const upload = await http(ROUTES.letterAttachmentUpload, 'POST', tokens[0], image, true);
    assert.equal(upload.code, 0, `2 MiB 图片上传失败，追踪号=${upload.requestId}`); attachments.push(upload.data.attachmentId);
    check(upload.data.sizeBytes === image.length && image.length === 2097152, '2 MiB 图片通过真实 HTTP 网关加密上传');
    const sendBody = (partnerId, overrides = {}) => ({ clientRequestId: randomUUID(), expectedPartnerId: partnerId, title: '仅用于后端联调的测试信件', recipientLabel: '测试收信人', content: '这是一段合成测试正文，不包含任何真实用户内容。'.repeat(12), arriveAt: new Date(Date.now() + 25 * 3600000).toISOString(), ...overrides });
    const input = sendBody(users[1], { attachmentId: upload.data.attachmentId });
    const [first, second] = await Promise.all([
      expect(ROUTES.letterSend, 'POST', tokens[0], input),
      expect(ROUTES.letterSend, 'POST', tokens[1], sendBody(users[0])),
    ].map((pending) => pending.then((value) => { letters.push(value.letterId); return value; })));
    const duplicate = await expect(ROUTES.letterSend, 'POST', tokens[0], input);
    const other = await expect(ROUTES.letterSend, 'POST', tokens[2], sendBody(users[3])); letters.push(other.letterId);
    check(JSON.stringify([first.letterNo, second.letterNo].sort()) === JSON.stringify(['MX · 0001', 'MX · 0002']) && other.letterNo === 'MX · 0001' && duplicate.letterId === first.letterId, '真实并发双向寄信序列唯一、情侣私有序列和寄信幂等均正确');
    const list = await expect(`${ROUTES.letterListV1}?box=received&stage=in_transit`, 'GET', tokens[1]);
    check(list.items.length === 1 && list.items[0].title === null && !JSON.stringify(list).includes(input.content) && !JSON.stringify(list).includes(upload.data.attachmentId), '在途列表不泄露标题、正文或附件 ID');
    await expect(ROUTES.letterContent, 'POST', tokens[1], { letterId: first.letterId }, 12001);
    await expect(`${ROUTES.letterAttachmentContent}?letterId=${first.letterId}&attachmentId=${upload.data.attachmentId}`, 'GET', tokens[1], undefined, 12001);
    await expect(`${ROUTES.letterDetail}?letterId=${first.letterId}`, 'GET', tokens[2], undefined, 12002);
    const self = await expect(ROUTES.letterContent, 'POST', tokens[0], { letterId: first.letterId });
    check(self.content === input.content && self.viewToken === null, '寄件人可以回看，收件人提前读取和其他情侣越权均被拒绝');
    const downloaded = await http(`${ROUTES.letterAttachmentContent}?letterId=${first.letterId}&attachmentId=${upload.data.attachmentId}`, 'GET', tokens[0]);
    check(Buffer.isBuffer(downloaded.image) && createHash('sha256').update(downloaded.image).digest('hex') === createHash('sha256').update(image).digest('hex') && downloaded.cacheControl.includes('no-store'), '2 MiB 图片解密下载内容完整，响应为图片二进制且禁止缓存');
    // 仅调整本次合成信件的时间以验证到达后流程，生产接口没有缩短延时或改时钟入口。
    await write('slow_letters', 'update', { query: { _id: first.letterId, senderId: users[0], relationshipId: first.relationshipId }, update: { $set: { arriveTime: Date.now() - 10000 } }, isMulti: false });
    const arrived = await expect(ROUTES.letterContent, 'POST', tokens[1], { letterId: first.letterId });
    check((await expect(ROUTES.letterOverview, 'GET', tokens[1])).counts.receivedUnread === 1, '取到正文不会自动标记已读');
    const receipt = await expect(ROUTES.letterRead, 'POST', tokens[1], { letterId: first.letterId, viewToken: arrived.viewToken });
    const repeated = await expect(ROUTES.letterRead, 'POST', tokens[1], { letterId: first.letterId, viewToken: arrived.viewToken });
    check(receipt.firstOpen && !repeated.firstOpen && receipt.openedAt === repeated.openedAt && (await expect(ROUTES.letterOverview, 'GET', tokens[1])).counts.receivedUnread === 0, '阅读回执幂等且按权威数据重算未读数');
    const reply = await expect(ROUTES.letterSend, 'POST', tokens[1], sendBody(users[0], { replyToLetterId: first.letterId })); letters.push(reply.letterId);
    const page = await expect(`${ROUTES.letterListV1}?box=sent&limit=1`, 'GET', tokens[1]);
    const next = await expect(`${ROUTES.letterListV1}?box=sent&limit=1&cursor=${encodeURIComponent(page.nextCursor)}`, 'GET', tokens[1]);
    const detail = await expect(`${ROUTES.letterDetail}?letterId=${reply.letterId}&scope=all`, 'GET', tokens[1]);
    check(reply.letterNo === 'MX · 0003' && page.items[0].letterId !== next.items[0].letterId && detail.navigation.nextLetterId === second.letterId, '回信、游标分页及左右邻居查询均正确');
    await expect('/api/v1/bind/unbind', 'POST', tokens[0], {});
    await expect(ROUTES.letterContent, 'POST', tokens[0], { letterId: first.letterId }, 7001);
    const codeId = `${prefix}_code`, code = randomBytes(3).toString('hex').toUpperCase(); codes.push(codeId);
    await write('bindCodes', 'insert', { documents: [{ _id: codeId, code, userId: users[1], used: false, createTime: Date.now(), expireTime: Date.now() + 600000 }] });
    const rebound = await expect('/api/v1/bind/use', 'POST', tokens[0], { bindCode: code }); relationships.add(rebound.relationshipId);
    const restarted = await expect(ROUTES.letterSend, 'POST', tokens[0], sendBody(users[1])); letters.push(restarted.letterId);
    check(restarted.relationshipId !== first.relationshipId && restarted.letterNo === 'MX · 0001', '重绑生成新 relationshipId，新序列从 0001 开始');
    await expect(ROUTES.letterContent, 'POST', tokens[0], { letterId: first.letterId }, 12002);
    const preserved = await client.call('readNoSqlDatabaseContent', { collectionName: 'slow_letters', query: { _id: first.letterId }, projection: { letterNo: 1, relationshipId: 1 }, limit: 1 });
    check(JSON.stringify(preserved).includes(first.letterNo) && JSON.stringify(preserved).includes(first.relationshipId), '解绑重绑不改写旧信件编号及所属关系');
    console.log(JSON.stringify({ envId, passedChecks: assertions, result: '线上慢信联调通过' }));
  } finally {
    // 只清理本次精确记录的合成对象；真实信件永不在此清理范围内。
    for (const attachmentId of attachments) await client.call('manageStorage', { action: 'delete', cloudPath: `slow-letters/${attachmentId}.bin`, isDirectory: false, force: true });
    if (attachments.length) await write('slow_letter_attachments', 'delete', { query: { _id: { $in: attachments } }, isMulti: true });
    if (letters.length) await write('slow_letters', 'delete', { query: { _id: { $in: letters } }, isMulti: true });
    if (relationships.size) await write('couple_relationships', 'delete', { query: { _id: { $in: [...relationships] } }, isMulti: true });
    if (codes.length) await write('bindCodes', 'delete', { query: { _id: { $in: codes } }, isMulti: true });
    await write('users', 'delete', { query: { _id: { $in: users }, testRunId: prefix }, isMulti: true });
    console.log('本次合成测试对象已清理');
    client.close();
  }
}

if (require.main === module) main(process.argv[2]).catch((error) => { console.error(error.message); process.exitCode = 1; });
