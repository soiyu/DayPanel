import { ref } from 'vue';
import { defineStore } from 'pinia';
import type { AchievementCard } from '../domain/models.ts';
import {
  GatewayError,
  WechatCloudGateway,
} from '../data/wechat-gateway.ts';

export const useCardsStore = defineStore('cards', () => {
  const gateway = new WechatCloudGateway();
  const cards = ref<AchievementCard[]>([]);
  const revision = ref(0);
  const loading = ref(false);
  const busy = ref(false);
  const error = ref<string | null>(null);

  async function load(): Promise<void> {
    if (loading.value) return;
    loading.value = true;
    error.value = null;
    try {
      const result = await gateway.cards();
      cards.value = result.cards;
      revision.value = result.revision;
    } catch (caught) {
      error.value = caught instanceof GatewayError ? caught.code : 'cloud_error';
    } finally {
      loading.value = false;
    }
  }

  async function favorite(card: AchievementCard): Promise<boolean> {
    if (busy.value) return false;
    busy.value = true;
    error.value = null;
    try {
      await gateway.favoriteCard(card.day, !card.favorite, revision.value);
      await load();
      return true;
    } catch (caught) {
      error.value = caught instanceof GatewayError ? caught.code : 'cloud_error';
      return false;
    } finally {
      busy.value = false;
    }
  }

  async function reflect(card: AchievementCard, text: string): Promise<boolean> {
    if (busy.value) return false;
    busy.value = true;
    error.value = null;
    try {
      await gateway.saveReflection(card.day, text, revision.value);
      await load();
      return true;
    } catch (caught) {
      error.value = caught instanceof GatewayError ? caught.code : 'cloud_error';
      return false;
    } finally {
      busy.value = false;
    }
  }

  return { cards, revision, loading, busy, error, load, favorite, reflect };
});
