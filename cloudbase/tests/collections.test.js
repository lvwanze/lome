/**
 * 云数据库集合 records / plans / important_days 接口集成测试
 *
 * 运行方式(项目根目录):
 *   node cloudbase/tests/collections.test.js
 *
 * 前置条件:
 *   - 13 个云函数已部署,网关路由 /api/v1/... 已创建
 *   - 无需安装依赖(Node 18+ 自带 fetch)
 *
 * 说明:
 *   - 直连已部署环境 love-app1;登录使用开发期固定验证码 666666
 *   - 每个用例创建的数据都在断言后立即清理,不留残留
 *   - 环境变量可覆盖: BASE_URL / TEST_PHONE / LOGIN_CODE
 */

const BASE =
  process.env.BASE_URL ||
  'https://love-app1-0g8yva6l11e713ef-1418513210.ap-shanghai.app.tcloudbase.com';
const TEST_PHONE = process.env.TEST_PHONE || '19011110000';
const LOGIN_CODE = process.env.LOGIN_CODE || '666666';

// 固定使用当前月份(2026-08)内的日期,便于校验月历接口
const DATE_RECORD = '2026-08-16';
const DATE_PLAN = '2026-08-20';
const DATE_IMPORTANT = '2026-08-15';
const MONTH = '2026-08';

let token = '';
let passed = 0;
let failed = 0;
const failures = [];

function assert(cond, name, extra) {
  if (cond) {
    passed++;
    console.log(`  ✅ ${name}`);
  } else {
    failed++;
    failures.push(name + (extra !== undefined ? ` — ${JSON.stringify(extra)}` : ''));
    console.log(`  ❌ ${name}${extra !== undefined ? ` — ${JSON.stringify(extra)}` : ''}`);
  }
}

async function api(method, path, body, useAuth = true) {
  const headers = { 'Content-Type': 'application/json' };
  if (useAuth && token) headers.Authorization = `Bearer ${token}`;
  const res = await fetch(BASE + path, {
    method,
    headers,
    body: body !== undefined ? JSON.stringify(body) : undefined,
    signal: AbortSignal.timeout(20000),
  });
  const text = await res.text();
  try {
    return { httpStatus: res.status, json: JSON.parse(text) };
  } catch (e) {
    return { httpStatus: res.status, json: null, raw: text.slice(0, 200) };
  }
}

async function login() {
  const r = await api('POST', '/api/v1/auth/login', { phone: TEST_PHONE, code: LOGIN_CODE }, false);
  assert(r.json && r.json.code === 0, '登录获取 Token', r.json);
  token = (r.json && r.json.data && r.json.data.token) || '';
  assert(!!token, 'Token 非空');
}

// ---------- 1. 鉴权防护:三个集合的接口无 Token 一律拒绝 ----------
async function testAuthGuard() {
  console.log('\n[1] 鉴权防护(无 Token 访问应返回 4001)');
  const cases = [
    ['POST', '/api/v1/record/create', { date: DATE_RECORD }],
    ['POST', '/api/v1/record/delete', { recordId: 'x' }],
    ['POST', '/api/v1/plan/create', { date: DATE_PLAN }],
    ['POST', '/api/v1/plan/toggle', { planId: 'x', completed: true }],
    ['POST', '/api/v1/important/day/create', { name: 'x', date: DATE_IMPORTANT }],
    ['POST', '/api/v1/important/day/list', {}],
  ];
  for (const [method, path, body] of cases) {
    const r = await api(method, path, body, false);
    assert(r.json && r.json.code === 4001, `无 Token ${path} → 4001`, r.json);
  }
}

// ---------- 2. records 集合:增改删 + 日历联动 ----------
async function testRecords() {
  console.log('\n[2] records 集合');
  let recordId = '';

  // 参数校验
  let r = await api('POST', '/api/v1/record/create', { title: '缺日期' });
  assert(r.json && r.json.code === 400, '创建记录缺 date → 400', r.json);

  // 创建
  r = await api('POST', '/api/v1/record/create', {
    date: DATE_RECORD,
    title: '集成测试记录',
    content: '测试内容',
    mood: 'happy',
  });
  assert(r.json && r.json.code === 0, '创建记录成功', r.json);
  recordId = r.json && r.json.data && r.json.data.recordId;
  assert(!!recordId, '返回 recordId', r.json);

  // 日详情可见
  r = await api('GET', `/api/v1/calendar/daily?date=${DATE_RECORD}`);
  const found =
    r.json && r.json.code === 0 &&
    (r.json.data.records || []).some((rec) => rec.recordId === recordId && rec.title === '集成测试记录');
  assert(found, '日详情包含新记录', r.json && r.json.data);

  // 月历联动
  r = await api('POST', '/api/v1/calendar/monthly', { month: MONTH });
  const day16 = r.json && r.json.data && (r.json.data.days || []).find((d) => d.date === DATE_RECORD);
  assert(day16 && day16.hasRecord === true && day16.recordCount >= 1, '月历 08-16 hasRecord=true', day16);
  assert(r.json && r.json.data && r.json.data.recordedDays >= 1, '月历 recordedDays>=1', r.json && r.json.data);

  // 更新
  r = await api('POST', '/api/v1/record/update', { recordId, title: '集成测试记录-已改' });
  assert(r.json && r.json.code === 0, '更新记录成功', r.json);
  r = await api('GET', `/api/v1/calendar/daily?date=${DATE_RECORD}`);
  const updated = (r.json && r.json.data.records || []).find((rec) => rec.recordId === recordId);
  assert(updated && updated.title === '集成测试记录-已改', '更新后标题生效', updated);

  // 更新不存在的记录
  r = await api('POST', '/api/v1/record/update', { recordId: 'nonexistent-id', title: 'x' });
  assert(r.json && r.json.code === 404, '更新不存在的记录 → 404', r.json);

  // 删除
  r = await api('POST', '/api/v1/record/delete', { recordId });
  assert(r.json && r.json.code === 0, '删除记录成功', r.json);
  r = await api('GET', `/api/v1/calendar/daily?date=${DATE_RECORD}`);
  const afterDelete = (r.json && r.json.data.records || []).some((rec) => rec.recordId === recordId);
  assert(!afterDelete, '删除后日详情不再包含', r.json && r.json.data);
}

// ---------- 3. plans 集合:增改/切换/删 + 日历联动 ----------
async function testPlans() {
  console.log('\n[3] plans 集合');
  let planId = '';

  let r = await api('POST', '/api/v1/plan/create', { title: '缺日期' });
  assert(r.json && r.json.code === 400, '创建规划缺 date → 400', r.json);

  r = await api('POST', '/api/v1/plan/create', { date: DATE_PLAN, title: '集成测试规划', content: '一起完成测试' });
  assert(r.json && r.json.code === 0, '创建规划成功', r.json);
  planId = r.json && r.json.data && r.json.data.planId;
  assert(!!planId, '返回 planId', r.json);

  // 月历联动:未完成计数
  r = await api('POST', '/api/v1/calendar/monthly', { month: MONTH });
  const day20 = r.json && r.json.data && (r.json.data.days || []).find((d) => d.date === DATE_PLAN);
  assert(day20 && day20.hasPlan === true && day20.planPendingCount >= 1, '月历 08-20 hasPlan=true 且未完成计数>=1', day20);

  // 切换完成
  r = await api('POST', '/api/v1/plan/toggle', { planId, completed: true });
  assert(r.json && r.json.code === 0 && r.json.data.completed === true, '切换为已完成', r.json);
  assert(r.json && !!r.json.data.completedBy && !!r.json.data.completedTime, 'completedBy/completedTime 已写入', r.json && r.json.data);

  r = await api('GET', `/api/v1/calendar/daily?date=${DATE_PLAN}`);
  const planDone = (r.json && r.json.data.plans || []).find((p) => p.planId === planId);
  assert(planDone && planDone.completed === true, '日详情 completed=true', planDone);

  r = await api('POST', '/api/v1/calendar/monthly', { month: MONTH });
  const day20b = r.json && r.json.data && (r.json.data.days || []).find((d) => d.date === DATE_PLAN);
  assert(day20b && day20b.planPendingCount === 0, '完成后月历 pending 归零', day20b);

  // 再切回未完成
  r = await api('POST', '/api/v1/plan/toggle', { planId, completed: false });
  assert(r.json && r.json.code === 0 && r.json.data.completed === false && r.json.data.completedBy === null, '切回未完成并清空完成人', r.json && r.json.data);

  // toggle 参数校验
  r = await api('POST', '/api/v1/plan/toggle', { planId });
  assert(r.json && r.json.code === 400, 'toggle 缺 completed → 400', r.json);

  // 更新
  r = await api('POST', '/api/v1/plan/update', { planId, title: '集成测试规划-已改' });
  assert(r.json && r.json.code === 0, '更新规划成功', r.json);
  r = await api('GET', `/api/v1/calendar/daily?date=${DATE_PLAN}`);
  const planUpdated = (r.json && r.json.data.plans || []).find((p) => p.planId === planId);
  assert(planUpdated && planUpdated.title === '集成测试规划-已改', '更新后标题生效', planUpdated);

  // 删除
  r = await api('POST', '/api/v1/plan/delete', { planId });
  assert(r.json && r.json.code === 0, '删除规划成功', r.json);
  r = await api('GET', `/api/v1/calendar/daily?date=${DATE_PLAN}`);
  const planGone = (r.json && r.json.data.plans || []).some((p) => p.planId === planId);
  assert(!planGone, '删除后日详情不再包含', r.json && r.json.data);
}

// ---------- 4. important_days 集合:增/查/删 + 日历联动 ----------
async function testImportantDays() {
  console.log('\n[4] important_days 集合');
  let importantDayId = '';

  let r = await api('POST', '/api/v1/important/day/create', { date: DATE_IMPORTANT });
  assert(r.json && r.json.code === 400, '添加重要日缺 name → 400', r.json);
  r = await api('POST', '/api/v1/important/day/create', { name: '缺日期' });
  assert(r.json && r.json.code === 400, '添加重要日缺 date → 400', r.json);

  r = await api('POST', '/api/v1/important/day/create', {
    name: '恋爱纪念日',
    date: DATE_IMPORTANT,
    type: 'anniversary',
    remark: '测试数据',
  });
  assert(r.json && r.json.code === 0, '添加重要日成功', r.json);
  importantDayId = r.json && r.json.data && r.json.data.importantDayId;
  assert(!!importantDayId, '返回 importantDayId', r.json);

  // 列表包含
  r = await api('POST', '/api/v1/important/day/list', {});
  const inList = r.json && r.json.code === 0 &&
    (r.json.data.list || []).some((d) => d.importantDayId === importantDayId && d.name === '恋爱纪念日');
  assert(inList, '列表包含新重要日', r.json && r.json.data);

  // 月历联动
  r = await api('POST', '/api/v1/calendar/monthly', { month: MONTH });
  const day15 = r.json && r.json.data && (r.json.data.days || []).find((d) => d.date === DATE_IMPORTANT);
  assert(day15 && day15.hasImportantDay === true && day15.importantDayName === '恋爱纪念日', '月历 08-15 标记重要日及名称', day15);

  // 日详情联动
  r = await api('GET', `/api/v1/calendar/daily?date=${DATE_IMPORTANT}`);
  assert(r.json && r.json.data && r.json.data.importantDay && r.json.data.importantDay.name === '恋爱纪念日', '日详情返回重要日', r.json && r.json.data);

  // 删除
  r = await api('POST', '/api/v1/important/day/delete', { importantDayId });
  assert(r.json && r.json.code === 0, '删除重要日成功', r.json);
  r = await api('POST', '/api/v1/important/day/list', {});
  const stillThere = r.json && (r.json.data.list || []).some((d) => d.importantDayId === importantDayId);
  assert(!stillThere, '删除后列表不再包含', r.json && r.json.data);

  // 删除不存在
  r = await api('POST', '/api/v1/important/day/delete', { importantDayId: 'nonexistent-id' });
  assert(r.json && r.json.code === 404, '删除不存在的重要日 → 404', r.json);
}

// ---------- 5. 参数校验 ----------
async function testParamValidation() {
  console.log('\n[5] 参数校验');
  let r = await api('POST', '/api/v1/calendar/monthly', { month: '2026-13' });
  assert(r.json && r.json.code === 400, '月历非法月份 → 400', r.json);
  r = await api('POST', '/api/v1/calendar/monthly', {});
  assert(r.json && r.json.code === 400, '月历缺 month → 400', r.json);
  r = await api('GET', '/api/v1/calendar/daily?date=2026/08/16');
  assert(r.json && r.json.code === 400, '日详情非法日期 → 400', r.json);
  r = await api('POST', '/api/v1/record/create', { date: '2026-08-16', images: [1, 2, 3, 4, 5] });
  assert(r.json && r.json.code === 0, '创建记录 images 超 4 张自动截断仍成功', r.json);
  if (r.json && r.json.code === 0) {
    const id = r.json.data.recordId;
    const d = await api('POST', '/api/v1/record/delete', { recordId: id });
    assert(d.json && d.json.code === 0, '清理截断测试记录', d.json);
  }
}

async function main() {
  console.log(`测试环境: ${BASE}`);
  console.log(`测试账号: ${TEST_PHONE}`);
  try {
    await login();
    if (!token) throw new Error('无法获取 Token,终止测试');
    await testAuthGuard();
    await testRecords();
    await testPlans();
    await testImportantDays();
    await testParamValidation();
  } catch (e) {
    failed++;
    failures.push(`测试执行异常: ${e.message}`);
    console.log(`  ❌ 测试执行异常: ${e.message}`);
  }

  console.log(`\n${'='.repeat(50)}`);
  console.log(`通过: ${passed}  失败: ${failed}`);
  if (failures.length) {
    console.log('失败用例:');
    failures.forEach((f) => console.log(`  - ${f}`));
    process.exit(1);
  } else {
    console.log('🎉 全部测试通过');
    process.exit(0);
  }
}

main();
