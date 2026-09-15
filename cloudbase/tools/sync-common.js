// 把 cloudbase/functions/common.js（唯一真源）同步到每个云函数目录下的 common.js
//
// 用法：
//   node cloudbase/tools/sync-common.js          写入不一致的文件
//   node cloudbase/tools/sync-common.js --check  只检查不写，有不一致时退出码 1
const fs = require('fs');
const path = require('path');

const SRC = path.resolve(__dirname, '..', 'functions', 'common.js');
const FN_DIR = path.resolve(__dirname, '..', 'functions');
const CHECK = process.argv.includes('--check');

const src = fs.readFileSync(SRC, 'utf8');

// 只覆盖已经存在 common.js 的目录，绝不新建
// （login / sendSms / getUserInfo / interaction / generateBindCode / useBindCode / unbind
//   这 7 个函数自带实现，不用 common.js）
const targets = fs
  .readdirSync(FN_DIR)
  .map((name) => path.join(FN_DIR, name, 'common.js'))
  .filter((p) => fs.existsSync(p));

let changed = 0;
for (const target of targets) {
  if (fs.readFileSync(target, 'utf8') === src) continue;
  changed++;
  if (CHECK) {
    console.log('[不一致]', path.relative(FN_DIR, target));
    continue;
  }
  fs.writeFileSync(target, src);
  console.log('[已同步]', path.relative(FN_DIR, target));
}

console.log(
  CHECK
    ? `检查完成：${changed}/${targets.length} 个文件与真源不一致`
    : `同步完成：更新 ${changed}/${targets.length} 个文件`
);
if (CHECK && changed) process.exit(1);
