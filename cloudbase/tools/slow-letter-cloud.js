// CloudBase 管理编排：敏感配置只在进程内传递，不写入日志、参数文件或仓库。
const { CloudBaseMcpClient } = require('./cloudbase-mcp-client');
const path = require('node:path');
const { randomBytes } = require('node:crypto');

const ROUTES = {
  letterOverview: '/api/v1/letters/overview', letterListV1: '/api/v1/letters/list', letterDetail: '/api/v1/letters/detail',
  letterSend: '/api/v1/letters/send', letterContent: '/api/v1/letters/content', letterRead: '/api/v1/letters/read',
  letterAttachmentUpload: '/api/v1/letters/attachment/upload', letterAttachmentContent: '/api/v1/letters/attachment/content',
};
const FUNCTIONS = [...Object.keys(ROUTES), 'letterAttachmentCleanup', 'useBindCode', 'unbind'];
const DOMAIN = 'love-app1-0g8yva6l11e713ef-1418513210.ap-shanghai.app.tcloudbase.com';
const indexes = {
  slow_letters: [
    ['relationship_sequence_unique', true, [['relationshipId', '1'], ['sequence', '1']]],
    ['pair_created', false, [['relationshipId', '1'], ['senderId', '1'], ['receiverId', '1'], ['createTime', '-1'], ['_id', '-1']]],
    ['pair_arrival', false, [['relationshipId', '1'], ['senderId', '1'], ['receiverId', '1'], ['arriveTime', '-1']]],
    ['pair_unread', false, [['relationshipId', '1'], ['senderId', '1'], ['receiverId', '1'], ['openedAt', '1'], ['arriveTime', '-1'], ['createTime', '-1'], ['_id', '-1']]],
  ],
  slow_letter_attachments: [['pending_expiry', false, [['state', '1'], ['expiresAt', '1']]]],
  couple_relationships: [],
};

function detailOf(result) { return result.data?.functionDetail; }
function variablesOf(detail) { return Object.fromEntries((detail?.Environment?.Variables || []).map((item) => [item.Key, item.Value])); }

async function provision(client) {
  for (const [collectionName, definitions] of Object.entries(indexes)) {
    const check = await client.call('readNoSqlDatabaseStructure', { action: 'checkCollection', collectionName });
    const exists = check.exists ?? check.data?.exists ?? check.data?.exist;
    // 不以错误当作不存在；checkCollection 的实际结构在初次执行时核对。
    if (exists === undefined) { console.log(JSON.stringify({ collectionName, check })); throw new Error('集合检查返回结构待核对'); }
    if (!exists) await client.call('writeNoSqlDatabaseStructure', { action: 'createCollection', collectionName });
    await client.call('managePermissions', { action: 'updateResourcePermission', resourceType: 'noSqlDatabase', resourceId: collectionName, permission: 'ADMINONLY' });
    if (definitions.length) {
      const existing = await client.call('readNoSqlDatabaseStructure', { action: 'listIndexes', collectionName });
      const serialized = JSON.stringify(existing);
      const missing = definitions.filter(([name]) => !serialized.includes(`\"${name}\"`));
      if (missing.length) await client.call('writeNoSqlDatabaseStructure', { action: 'updateCollection', collectionName, updateOptions: { CreateIndexes: missing.map(([IndexName, MgoIsUnique, keys]) => ({ IndexName, MgoKeySchema: { MgoIsUnique, MgoIndexKeys: keys.map(([Name, Direction]) => ({ Name, Direction })) } })) } });
    }
    console.log(`集合及权限已核对：${collectionName}`);
  }
}

async function maintenancePermissions(client) {
  // 云函数安全规则是环境级映射；保留既有通配和其他函数规则，只补维护函数禁用客户端调用。
  const current = await client.call('queryPermissions', { action: 'getResourcePermission', resourceType: 'function', resourceId: '*' });
  const text = current.data?.permissions?.[0]?.SecurityRule;
  if (!text) throw new Error('未取得环境级函数规则，拒绝覆盖');
  const rules = JSON.parse(text);
  if (!rules['*']) throw new Error('环境级函数规则缺少通配配置，拒绝覆盖');
  rules.letterAttachmentCleanup = { invoke: false };
  await client.call('managePermissions', { action: 'updateResourcePermission', resourceType: 'function', resourceId: '*', permission: 'CUSTOM', securityRule: JSON.stringify(rules) });
  const verified = await client.call('queryPermissions', { action: 'getResourcePermission', resourceType: 'function', resourceId: '*' });
  const actual = JSON.parse(verified.data.permissions[0].SecurityRule);
  if (actual.letterAttachmentCleanup?.invoke !== false) throw new Error('维护函数权限未生效');
  console.log('环境级函数规则已保留，维护函数客户端调用已禁用');
}

async function deploy(client, envId) {
  const functions = (await client.call('queryFunctions', { action: 'listFunctions', limit: 100 })).data.functions;
  const names = new Set(functions.map((value) => value.FunctionName));
  const login = detailOf(await client.call('queryFunctions', { action: 'getFunctionDetail', functionName: 'login', revealEnvValues: true }));
  const jwtSecret = variablesOf(login).JWT_SECRET;
  if (!jwtSecret || jwtSecret === '***') throw new Error('无法在进程内复用线上 JWT 配置');
  let keyVariables;
  if (names.has('letterSend')) keyVariables = variablesOf(detailOf(await client.call('queryFunctions', { action: 'getFunctionDetail', functionName: 'letterSend', revealEnvValues: true })));
  const masterKeys = keyVariables?.LETTER_MASTER_KEYS || JSON.stringify({ k1: randomBytes(32).toString('base64') });
  const active = keyVariables?.LETTER_ACTIVE_KEY_VERSION || 'k1';
  const from = process.argv[4];
  if (from && !FUNCTIONS.includes(from)) throw new Error('续部署函数名称无效');
  for (const name of FUNCTIONS.slice(from ? FUNCTIONS.indexOf(from) : 0)) {
    console.log(`开始部署：${name}`);
    const isBinding = ['useBindCode', 'unbind'].includes(name);
    const current = names.has(name) ? detailOf(await client.call('queryFunctions', { action: 'getFunctionDetail', functionName: name, revealEnvValues: true })) : null;
    const envVariables = { ...variablesOf(current), ENV_ID: envId, JWT_SECRET: jwtSecret, ...(isBinding ? {} : { LETTER_MASTER_KEYS: masterKeys, LETTER_ACTIVE_KEY_VERSION: active }) };
    if (!current) await client.call('manageFunctions', { action: 'createFunction', func: { name, type: 'Event', runtime: 'Nodejs18.15', handler: 'index.main', timeout: 30, envVariables, isWaitInstall: true, ignore: ['node_modules', '.git'] }, functionRootPath: path.resolve(__dirname, '../functions') });
    else {
      await client.call('manageFunctions', { action: 'updateFunctionConfig', functionName: name, timeout: 30, envVariables });
      await client.call('manageFunctions', { action: 'updateFunctionCode', functionName: name, functionRootPath: path.resolve(__dirname, '../functions'), func: { name, isWaitInstall: true, ignore: ['node_modules', '.git'] } });
    }
    let actual;
    for (let attempt = 0; attempt < 30; attempt++) {
      actual = detailOf(await client.call('queryFunctions', { action: 'getFunctionDetail', functionName: name }));
      if (actual.Status === 'Active' && actual.CodeResult === 'success') break;
      if (actual.CodeResult?.includes('fail') || actual.Status === 'CreateFailed' || actual.Status === 'UpdateFailed') throw new Error(`${name} 平台部署失败`);
      await new Promise((resolve) => setTimeout(resolve, 2000));
    }
    if (actual.Status !== 'Active' || actual.CodeResult !== 'success') throw new Error(`${name} 尚未处于可用状态`);
    console.log(`部署完成：${name}，状态=${actual.Status}`);
  }
  await maintenancePermissions(client);
  const triggers = await client.call('queryFunctions', { action: 'listFunctionTriggers', functionName: 'letterAttachmentCleanup' });
  if (!JSON.stringify(triggers).includes('slow-letter-attachment-cleanup')) await client.call('manageFunctions', { action: 'createFunctionTrigger', functionName: 'letterAttachmentCleanup', triggers: [{ name: 'slow-letter-attachment-cleanup', type: 'timer', config: '0 */30 * * * * *' }] });
  const existing = JSON.stringify(await client.call('queryGateway', { action: 'listRoutes', domain: DOMAIN }));
  for (const [name, route] of Object.entries(ROUTES)) {
    if (!existing.includes(`\"${route}\"`)) await client.call('manageGateway', { action: 'createRoute', domain: DOMAIN, targetName: name, path: route, upstreamResourceType: 'SCF', auth: false });
    else {
      const current = JSON.stringify(await client.call('queryGateway', { action: 'getRoute', domain: DOMAIN, path: route }));
      if (!current.includes(`\"${name}\"`)) throw new Error(`路径已被其他资源占用：${route}`);
    }
    console.log(`网关已核对：${route}`);
  }
}

async function connect(envId) {
  if (envId !== 'love-app1-0g8yva6l11e713ef') throw new Error('请显式指定已确认的 lome 环境 ID');
  const client = await new CloudBaseMcpClient().connect();
  const status = await client.call('auth', { action: 'status' });
  if (status.auth_status !== 'READY') throw new Error('CloudBase 登录尚未就绪');
  await client.call('auth', { action: 'set_env', envId, region: 'ap-shanghai', site: 'domestic' });
  return client;
}

async function main() {
  const [mode, envId] = process.argv.slice(2);
  const client = await connect(envId);
  try {
    if (mode === 'inspect') {
      const tasks = [
        ['environment', 'queryEnv', { action: 'info', envId }],
        ['functions', 'queryFunctions', { action: 'listFunctions', limit: 100, offset: 0 }],
        ['collections', 'readNoSqlDatabaseStructure', { action: 'listCollections', limit: 100 }],
        ['routes', 'queryGateway', { action: 'listRoutes' }],
        ['jwtConfigShape', 'queryFunctions', { action: 'getFunctionDetail', functionName: 'login' }],
      ];
      for (const [name, tool, args] of tasks) {
        const result = await client.call(tool, args);
        if (name === 'jwtConfigShape') console.log(JSON.stringify({ name, variables: detailOf(result)?.Environment?.Variables?.map((value) => ({ key: value.Key, length: value.ValueLength })) }));
        else if (name === 'functions') console.log(JSON.stringify({ name, functions: result.data.functions.map((value) => ({ name: value.FunctionName, status: value.Status })) }));
        else console.log(JSON.stringify({ name, result }));
      }
    } else if (mode === 'binary-docs') {
      console.log(JSON.stringify(await client.call('searchKnowledgeBase', { mode: 'docs', action: 'searchDocs', query: 'HTTP 访问服务 云函数 isBase64Encoded 响应' })));
    } else if (mode === 'provision') await provision(client);
    else if (mode === 'deploy') await deploy(client, envId);
    else if (mode === 'permissions') await maintenancePermissions(client);
    else throw new Error('未知管理操作');
  } finally { client.close(); }
}

if (require.main === module) main().catch((error) => { console.error(error.message); process.exitCode = 1; });
module.exports = { connect, detailOf, variablesOf, DOMAIN, ROUTES };
