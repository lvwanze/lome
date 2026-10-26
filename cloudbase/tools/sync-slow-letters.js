// 领域实现只有一份真源；发布前同步到独立打包的各云函数。
const fs = require('node:fs');
const path = require('node:path');
const root = path.resolve(__dirname, '../functions');
const endpoints = {
  letterOverview: ['overview', 'GET'], letterListV1: ['list', 'GET'], letterDetail: ['detail', 'GET'],
  letterSend: ['send', 'POST'], letterContent: ['content', 'POST'], letterRead: ['read', 'POST'],
  letterAttachmentUpload: ['upload', 'POST'], letterAttachmentContent: ['attachment', 'GET'],
  letterAttachmentCleanup: ['cleanup', 'POST'], useBindCode: ['bind', 'POST'], unbind: ['unbind', 'POST'],
};
const sources = ['slow_letter_core.js', 'slow_letter_crypto.js', 'slow_letter_store.js', 'relationship_core.js', 'slow_letter_runtime.js'];
let mismatches = 0;
function sync(destination, value) {
  if (fs.existsSync(destination) && fs.readFileSync(destination, 'utf8') === value) return;
  mismatches++;
  if (process.argv.includes('--check')) console.log(`不同步：${path.relative(root, destination)}`);
  else fs.writeFileSync(destination, value);
}
for (const [name, [action, method]] of Object.entries(endpoints)) {
  const directory = path.join(root, name);
  if (!process.argv.includes('--check')) fs.mkdirSync(directory, { recursive: true });
  sync(path.join(directory, 'index.js'), `// ${name}：共享实现请修改 functions 根目录真源后同步。\nexports.main = require('./slow_letter_runtime').makeHandler('${action}', '${method}');\n`);
  for (const source of sources) sync(path.join(directory, source), fs.readFileSync(path.join(root, source), 'utf8'));
  // 绑定模块已有 package.json 保留；新函数固定依赖版本以便复现部署。
  if (!['useBindCode', 'unbind'].includes(name)) sync(path.join(directory, 'package.json'), `${JSON.stringify({ name, version: '1.0.0', main: 'index.js', dependencies: { '@cloudbase/node-sdk': '2.11.0', jsonwebtoken: '9.0.2' } }, null, 2)}\n`);
}
console.log(`慢信同步${process.argv.includes('--check') ? '检查' : '完成'}：${mismatches} 个文件`);
if (process.argv.includes('--check') && mismatches) process.exitCode = 1;
module.exports = { endpoints };
