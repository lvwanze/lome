// 将领域层的查询描述转换为 CloudBase NoSQL 命令，所有查询在数据库层限制归属。
function createStore(app) {
  const db = app.database();
  const command = db.command;
  function condition(filter) {
    const parts = [];
    const fields = {};
    for (const [field, value] of Object.entries(filter)) {
      if (field === '$or' || field === '$and') parts.push(command[field === '$or' ? 'or' : 'and'](value.map(condition)));
      else if (value && typeof value === 'object' && !Array.isArray(value)) {
        const operations = Object.entries(value).map(([op, operand]) => command[op.slice(1)](operand));
        fields[field] = operations.length === 1 ? operations[0] : command.and(operations);
      } else fields[field] = value;
    }
    if (Object.keys(fields).length) parts.push(fields);
    return parts.length === 1 ? parts[0] : command.and(parts);
  }
  return {
    transaction: (callback) => db.runTransaction(callback, 5),
    async get(collection, id, transaction = db) {
      const result = await transaction.collection(collection).doc(id).get();
      return Array.isArray(result.data) ? result.data[0] || null : result.data || null;
    },
    async put(collection, id, value, transaction = db) { await transaction.collection(collection).doc(id).set(value); },
    async update(collection, id, value, transaction = db) {
      const result = await transaction.collection(collection).doc(id).update(value);
      if (result.updated !== 1) throw new Error('更新目标不存在');
    },
    async remove(collection, id, transaction = db) { await transaction.collection(collection).doc(id).remove(); },
    async query(collection, filter, { order = [], limit = 20 } = {}) {
      let query = db.collection(collection).where(condition(filter));
      for (const [field, direction] of order) query = query.orderBy(field, direction);
      const result = await query.limit(limit).get();
      return result.data || [];
    },
    async count(collection, filter) { return (await db.collection(collection).where(condition(filter)).count()).total; },
    async upload(path, bytes) { return (await app.uploadFile({ cloudPath: path, fileContent: bytes })).fileID; },
    async download(fileId) { return (await app.downloadFile({ fileID: fileId })).fileContent; },
    async deleteFile(fileId) {
      const result = await app.deleteFile({ fileList: [fileId] });
      const item = result.fileList && result.fileList[0];
      if (!item || (item.code && item.code !== 'SUCCESS') || (item.status && item.status !== 0)) throw new Error('暂存图片清理失败');
    },
  };
}

module.exports = { createStore };
