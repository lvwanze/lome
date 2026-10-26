const { randomUUID } = require('node:crypto');

const RELATIONSHIPS = 'couple_relationships';
class BusinessError extends Error {
  constructor(code, message) { super(message); this.code = code; }
}
function fail(code, message) { throw new BusinessError(code, message); }

function createRelationships(store, now = Date.now) {
  async function current(userId, transaction, initialize = true) {
    const user = await store.get('users', userId, transaction);
    if (!user) fail(4002, '用户不存在');
    if (!user.partnerId || !user.isBound) fail(7001, '尚未绑定伴侣或绑定关系已变化');
    const partner = await store.get('users', user.partnerId, transaction);
    if (!partner || partner.partnerId !== userId || !partner.isBound) fail(7001, '伴侣绑定关系已变化');
    if (!user.relationshipId && !partner.relationshipId && initialize) {
      // 已绑定的旧用户在首次使用慢信时补齐关系记录；事务冲突会重试，不会重复建序列。
      const relationshipId = `rel_${randomUUID()}`;
      const relationship = { memberIds: [userId, partner._id].sort(), status: 'active', createTime: now(), endedAt: null, letterSequence: 0 };
      await store.put(RELATIONSHIPS, relationshipId, relationship, transaction);
      await store.update('users', userId, { relationshipId }, transaction);
      await store.update('users', partner._id, { relationshipId }, transaction);
      return { user, partner, relationshipId, relationship: { _id: relationshipId, ...relationship } };
    }
    if (!user.relationshipId || user.relationshipId !== partner.relationshipId) fail(7001, '伴侣关系记录不一致');
    const relationship = await store.get(RELATIONSHIPS, user.relationshipId, transaction);
    if (!relationship || relationship.status !== 'active' || !relationship.memberIds.includes(userId) || !relationship.memberIds.includes(partner._id)) fail(7001, '伴侣关系已结束');
    return { user, partner, relationshipId: relationship._id, relationship };
  }
  return {
    current,
    authorize: (userId) => store.transaction((transaction) => current(userId, transaction)),
    async bind(userId, bindCode) {
      if (typeof bindCode !== 'string' || !/^[A-Z0-9]{6}$/.test(bindCode)) fail(6001, '请提供有效的绑定码');
      const candidates = await store.query('bindCodes', { code: bindCode, used: false }, { limit: 1 });
      if (!candidates.length) fail(6001, '绑定码不存在或已使用');
      return store.transaction(async (transaction) => {
        const user = await store.get('users', userId, transaction);
        const code = await store.get('bindCodes', candidates[0]._id, transaction);
        if (!user) fail(4002, '用户不存在');
        if (user.partnerId) fail(5001, '您已绑定伴侣');
        if (!code || code.used || code.code !== bindCode) fail(6001, '绑定码不存在或已使用');
        if (now() >= code.expireTime) fail(6002, '绑定码已过期');
        if (code.userId === userId) fail(6003, '不能绑定自己');
        const partner = await store.get('users', code.userId, transaction);
        if (!partner) fail(4002, '对方用户不存在');
        if (partner.partnerId) fail(6004, '对方已绑定他人');
        const relationshipId = `rel_${randomUUID()}`;
        await store.put(RELATIONSHIPS, relationshipId, { memberIds: [userId, partner._id].sort(), status: 'active', createTime: now(), endedAt: null, letterSequence: 0 }, transaction);
        await store.update('users', userId, { partnerId: partner._id, isBound: true, relationshipId }, transaction);
        await store.update('users', partner._id, { partnerId: userId, isBound: true, relationshipId }, transaction);
        await store.update('bindCodes', code._id, { used: true, usedBy: userId, usedTime: now() }, transaction);
        return { partnerId: partner._id, partnerNickname: partner.nickname || '', relationshipId };
      });
    },
    unbind: (userId) => store.transaction(async (transaction) => {
      const context = await current(userId, transaction);
      await store.update(RELATIONSHIPS, context.relationshipId, { status: 'ended', endedAt: now() }, transaction);
      await store.update('users', userId, { partnerId: null, isBound: false, relationshipId: null }, transaction);
      await store.update('users', context.partner._id, { partnerId: null, isBound: false, relationshipId: null }, transaction);
      return { relationshipId: context.relationshipId };
    }),
  };
}

module.exports = { createRelationships, RELATIONSHIPS, BusinessError, fail };
