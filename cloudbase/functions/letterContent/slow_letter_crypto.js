const crypto = require('node:crypto');

// 主密钥只从云函数环境读取；每个密文使用独立数据密钥与 GCM nonce。
function createCrypto(keys, activeVersion) {
  const ring = Object.fromEntries(Object.entries(keys).map(([version, value]) => [version, Buffer.from(value, 'base64')]));
  if (!ring[activeVersion] || Object.values(ring).some((key) => key.length !== 32)) throw new Error('慢信密钥配置无效');
  function encryptWith(key, bytes, aad) {
    const iv = crypto.randomBytes(12);
    const cipher = crypto.createCipheriv('aes-256-gcm', key, iv);
    cipher.setAAD(Buffer.from(aad));
    const ciphertext = Buffer.concat([cipher.update(bytes), cipher.final()]);
    return { iv: iv.toString('base64'), tag: cipher.getAuthTag().toString('base64'), ciphertext: ciphertext.toString('base64') };
  }
  function decryptWith(key, value, aad) {
    const decipher = crypto.createDecipheriv('aes-256-gcm', key, Buffer.from(value.iv, 'base64'));
    decipher.setAAD(Buffer.from(aad));
    decipher.setAuthTag(Buffer.from(value.tag, 'base64'));
    return Buffer.concat([decipher.update(Buffer.from(value.ciphertext, 'base64')), decipher.final()]);
  }
  return {
    encrypt(bytes, aad) {
      const dataKey = crypto.randomBytes(32);
      return { version: activeVersion, wrappedKey: encryptWith(ring[activeVersion], dataKey, `${aad}:key`), ...encryptWith(dataKey, bytes, aad) };
    },
    decrypt(value, aad) {
      if (!ring[value.version]) throw new Error('慢信解密密钥版本不可用');
      const dataKey = decryptWith(ring[value.version], value.wrappedKey, `${aad}:key`);
      return decryptWith(dataKey, value, aad);
    },
    sign(payload, purpose) {
      const body = Buffer.from(JSON.stringify({ ...payload, keyVersion: activeVersion })).toString('base64url');
      const key = crypto.createHmac('sha256', ring[activeVersion]).update(purpose).digest();
      return `${body}.${crypto.createHmac('sha256', key).update(body).digest('base64url')}`;
    },
    verify(token, purpose) {
      if (typeof token !== 'string' || token.length > 4096) throw new Error('凭证无效');
      const parts = token.split('.');
      if (parts.length !== 2) throw new Error('凭证无效');
      const payload = JSON.parse(Buffer.from(parts[0], 'base64url').toString());
      if (!ring[payload.keyVersion]) throw new Error('凭证无效');
      const key = crypto.createHmac('sha256', ring[payload.keyVersion]).update(purpose).digest();
      const expected = crypto.createHmac('sha256', key).update(parts[0]).digest();
      const actual = Buffer.from(parts[1], 'base64url');
      if (actual.length !== expected.length || !crypto.timingSafeEqual(expected, actual)) throw new Error('凭证无效');
      return payload;
    },
  };
}

module.exports = { createCrypto };
