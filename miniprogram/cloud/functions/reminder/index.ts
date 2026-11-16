// @ts-nocheck
/**
 * Scheduled sender for one-shot / daily-digest subscription messages.
 * The client must have obtained an accepted one-time authorization before the
 * job is created. This function never writes habit/task content.
 */
import cloud from 'wx-server-sdk';

cloud.init({ env: cloud.DYNAMIC_CURRENT_ENV });
const db = cloud.database();
const _ = db.command;

const JOB_LIMIT = 100;

async function mark(jobId, status, extra = {}) {
  await db.collection('dp_jobs').doc(jobId).update({
    data: { status, updatedAt: db.serverDate(), ...extra },
  });
}

export async function main() {
  const now = new Date();
  const due = await db
    .collection('dp_jobs')
    .where({ status: 'pending', sendAt: _.lte(now) })
    .limit(JOB_LIMIT)
    .get();

  let sent = 0;
  let invalid = 0;
  let failed = 0;

  for (const job of due.data) {
    if (!job.templateId || !job._openid) {
      await mark(job.id, 'invalid', { failure: 'missing_template_or_openid' });
      invalid += 1;
      continue;
    }
    const data = job.payload && typeof job.payload === 'object' ? job.payload : {};
    try {
      await cloud.openapi.subscribeMessage.send({
        touser: job._openid,
        templateId: job.templateId,
        page: job.page || undefined,
        data,
        miniprogramState: 'formal',
        lang: 'zh_CN',
      });
      await mark(job.id, 'sent', { sentAt: db.serverDate() });
      sent += 1;
    } catch (error) {
      const code = error?.errCode ?? error?.errcode ?? null;
      // 43101: user refused / no quota; 47003: template data invalid.
      if (code === 43101 || code === 47003) {
        await mark(job.id, 'invalid', {
          failure: String(code),
        });
        invalid += 1;
      } else {
        await mark(job.id, 'failed', {
          failure: String(code ?? error?.errMsg ?? 'send_failed'),
        });
        failed += 1;
      }
    }
  }

  return { ok: true, checked: due.data.length, sent, invalid, failed };
}