import { ref } from 'vue';
import { defineStore } from 'pinia';
import {
  GatewayError,
  WechatCloudGateway,
} from '../data/wechat-gateway.ts';
import type { ChallengeLength, ChallengeProgress } from '../application/challenge-actions.ts';

export const useChallengesStore = defineStore('challenges', () => {
  const gateway = new WechatCloudGateway();
  const items = ref<ChallengeProgress[]>([]);
  const revision = ref(0);
  const loading = ref(false);
  const busy = ref(false);
  const error = ref<string | null>(null);

  async function load(): Promise<void> {
    if (loading.value) return;
    loading.value = true;
    error.value = null;
    try {
      const result = await gateway.challenges();
      items.value = result.challenges;
      revision.value = result.revision;
    } catch (caught) {
      error.value = caught instanceof GatewayError ? caught.code : 'cloud_error';
    } finally {
      loading.value = false;
    }
  }

  async function create(habitId: string, length: ChallengeLength): Promise<boolean> {
    if (busy.value) return false;
    busy.value = true;
    error.value = null;
    try {
      await gateway.createChallenge(habitId, length, revision.value);
      await load();
      return true;
    } catch (caught) {
      error.value = caught instanceof GatewayError ? caught.code : 'cloud_error';
      return false;
    } finally {
      busy.value = false;
    }
  }

  async function abandon(id: string): Promise<boolean> {
    if (busy.value) return false;
    busy.value = true;
    error.value = null;
    try {
      await gateway.abandonChallenge(id, revision.value);
      await load();
      return true;
    } catch (caught) {
      error.value = caught instanceof GatewayError ? caught.code : 'cloud_error';
      return false;
    } finally {
      busy.value = false;
    }
  }

  return { items, revision, loading, busy, error, load, create, abandon };
});
