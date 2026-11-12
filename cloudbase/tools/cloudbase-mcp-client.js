// 通过标准 MCP stdio 协议复用本机登录态；只向调用者返回结构化结果，不输出凭据。
const { spawn } = require('node:child_process');
const { createInterface } = require('node:readline');

class CloudBaseMcpClient {
  constructor(entry = process.env.CLOUDBASE_MCP_ENTRY) {
    if (!entry) throw new Error('请通过 CLOUDBASE_MCP_ENTRY 指定已安装的 CloudBase MCP 入口');
    this.sequence = 0;
    this.pending = new Map();
    this.process = spawn(process.execPath, [entry], { stdio: ['pipe', 'pipe', 'pipe'], windowsHide: true });
    this.process.stderr.on('data', () => {});
    createInterface({ input: this.process.stdout }).on('line', (line) => {
      let message;
      try { message = JSON.parse(line); } catch { return; }
      const pending = this.pending.get(message.id);
      if (!pending) return;
      this.pending.delete(message.id);
      clearTimeout(pending.timer);
      if (message.error) pending.reject(new Error(`MCP ${message.error.code}: ${message.error.message}`));
      else pending.resolve(message.result);
    });
    this.process.on('exit', () => {
      for (const pending of this.pending.values()) {
        clearTimeout(pending.timer);
        pending.reject(new Error('CloudBase MCP 进程已退出'));
      }
      this.pending.clear();
    });
  }

  request(method, params, timeout = 180000) {
    const id = ++this.sequence;
    return new Promise((resolve, reject) => {
      const timer = setTimeout(() => {
        this.pending.delete(id);
        reject(new Error(`MCP 请求超时：${method}`));
      }, timeout);
      this.pending.set(id, { resolve, reject, timer });
      this.process.stdin.write(`${JSON.stringify({ jsonrpc: '2.0', id, method, params })}\n`);
    });
  }

  async connect() {
    await this.request('initialize', {
      protocolVersion: '2024-11-05', capabilities: {}, clientInfo: { name: 'lome-backend-tools', version: '1.0.0' },
    }, 30000);
    this.process.stdin.write(`${JSON.stringify({ jsonrpc: '2.0', method: 'notifications/initialized' })}\n`);
    return this;
  }

  async call(name, args) {
    const result = await this.request('tools/call', { name, arguments: args });
    const texts = (result.content || []).filter((item) => item.type === 'text').map((item) => item.text);
    const parsed = texts.map((value) => { try { return JSON.parse(value); } catch { return value; } });
    if (result.isError || parsed[0]?.success === false || parsed[0]?.ok === false) {
      // 工具错误可能含请求参数；只输出错误码，防止部署环境变量或 JWT 被带入日志。
      const code = parsed[0]?.errorCode || parsed[0]?.error?.code || parsed[0]?.code || 'TOOL_ERROR';
      throw new Error(`CloudBase 工具 ${name} 调用失败（${String(code).slice(0, 100)}）`);
    }
    return parsed.length === 1 ? parsed[0] : parsed;
  }

  close() { this.process.kill(); }
}

module.exports = { CloudBaseMcpClient };

if (require.main === module) {
  (async () => {
    const client = await new CloudBaseMcpClient().connect();
    try {
      if (process.argv[2] === 'schema') {
        const schema = await client.request('tools/list', {});
        require('node:fs').writeFileSync(process.argv[3], JSON.stringify(schema, null, 2));
        console.log(schema.tools.map((tool) => tool.name).join('\n'));
      } else if (process.argv[2] === 'status') {
        console.log(JSON.stringify(await client.call('auth', { action: 'status' }), null, 2));
      } else { throw new Error('仅支持 schema <文件路径> 或 status'); }
    } finally { client.close(); }
  })().catch((error) => { console.error(error.message); process.exitCode = 1; });
}
