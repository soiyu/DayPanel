import { computed, ref } from 'vue';
import { defineStore } from 'pinia';
import { todayKey, type DayKey } from '../domain/day.ts';
import type { Note } from '../domain/models.ts';
import {
  GatewayError,
  WechatCloudGateway,
  type NotesView,
} from '../data/wechat-gateway.ts';
import { resolveLocale, translate, type Locale } from '../i18n/index.ts';
import type { NoteQuery } from '../application/journal-actions.ts';

function currentMonth(day: DayKey): string {
  return day.slice(0, 7);
}

export const useJournalStore = defineStore('journal', () => {
  const gateway = new WechatCloudGateway();
  const today = ref<DayKey>(todayKey());
  const month = ref(currentMonth(today.value));
  const text = ref('');
  const notes = ref<Note[]>([]);
  const revision = ref(0);
  const loading = ref(false);
  const busy = ref(false);
  const error = ref<string | null>(null);
  const cache = new Map<string, Note>();

  const locale = computed<Locale>(() => resolveLocale('system'));
  const tr = (key: Parameters<typeof translate>[1]) =>
    translate(locale.value, key);

  async function load(): Promise<void> {
    if (loading.value) return;
    loading.value = true;
    error.value = null;
    today.value = todayKey();
    try {
      const view: NotesView = await gateway.notes({
        month: month.value || null,
        text: text.value.trim() || undefined,
      });
      notes.value = view.notes;
      revision.value = view.revision;
      for (const note of view.notes) cache.set(note.id, note);
    } catch (caught) {
      error.value = caught instanceof GatewayError ? caught.code : 'cloud_error';
    } finally {
      loading.value = false;
    }
  }

  function setMonth(value: string): void {
    month.value = value;
    void load();
  }

  function setText(value: string): void {
    text.value = value;
    void load();
  }

  function previousMonth(): void {
    const [year, monthNumber] = month.value.split('-').map(Number);
    const previous = new Date(Date.UTC(year, monthNumber - 2, 1));
    setMonth(
      `${previous.getUTCFullYear()}-${String(previous.getUTCMonth() + 1).padStart(2, '0')}`,
    );
  }

  function nextMonth(): void {
    const [year, monthNumber] = month.value.split('-').map(Number);
    const next = new Date(Date.UTC(year, monthNumber, 1));
    setMonth(
      `${next.getUTCFullYear()}-${String(next.getUTCMonth() + 1).padStart(2, '0')}`,
    );
  }

  async function loadNote(id: string): Promise<Note | null> {
    const cached = cache.get(id);
    if (cached) return cached;
    try {
      const view = await gateway.notes({});
      revision.value = view.revision;
      for (const note of view.notes) cache.set(note.id, note);
      return cache.get(id) ?? null;
    } catch (caught) {
      error.value = caught instanceof GatewayError ? caught.code : 'cloud_error';
      return null;
    }
  }

  async function create(input: {
    body: string;
    day: DayKey;
  }): Promise<boolean> {
    if (busy.value) return false;
    busy.value = true;
    error.value = null;
    try {
      await gateway.createNote({ ...input, habitId: null }, revision.value);
      await load();
      return true;
    } catch (caught) {
      error.value = caught instanceof GatewayError ? caught.code : 'cloud_error';
      return false;
    } finally {
      busy.value = false;
    }
  }

  async function update(
    id: string,
    patch: { body?: string; day?: DayKey },
  ): Promise<boolean> {
    if (busy.value) return false;
    busy.value = true;
    error.value = null;
    try {
      await gateway.updateNote(id, patch, revision.value);
      cache.delete(id);
      await load();
      return true;
    } catch (caught) {
      error.value = caught instanceof GatewayError ? caught.code : 'cloud_error';
      return false;
    } finally {
      busy.value = false;
    }
  }

  async function remove(id: string): Promise<boolean> {
    if (busy.value) return false;
    busy.value = true;
    error.value = null;
    try {
      await gateway.deleteNote(id, revision.value);
      cache.delete(id);
      await load();
      return true;
    } catch (caught) {
      error.value = caught instanceof GatewayError ? caught.code : 'cloud_error';
      return false;
    } finally {
      busy.value = false;
    }
  }

  return {
    today,
    month,
    text,
    notes,
    revision,
    loading,
    busy,
    error,
    tr,
    load,
    setMonth,
    setText,
    previousMonth,
    nextMonth,
    loadNote,
    create,
    update,
    remove,
  };
});

export type { NoteQuery };