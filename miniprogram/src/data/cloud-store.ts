import { cloneState, emptyState, type UserState } from '../domain/models.ts';

export interface CloudSnapshot {
  revision: number;
  state: UserState;
}

export class RevisionConflict extends Error {
  readonly actualRevision: number;

  constructor(actualRevision: number) {
    super('Revision conflict');
    this.name = 'RevisionConflict';
    this.actualRevision = actualRevision;
  }
}

/**
 * Production implementations talk to CloudBase. The memory implementation is
 * a test double only; it deliberately enforces the same revision check so the
 * vertical slice exercises concurrency instead of a happy-path mock.
 */
export interface CloudStore {
  load(): Promise<CloudSnapshot>;
  commit(expectedRevision: number, state: UserState): Promise<number>;
  deleteAccount(expectedRevision: number): Promise<number>;
}

export class MemoryCloud implements CloudStore {
  private revision = 0;
  private state: UserState = emptyState();

  async load(): Promise<CloudSnapshot> {
    return {
      revision: this.revision,
      state: cloneState(this.state),
    };
  }

  async commit(expectedRevision: number, state: UserState): Promise<number> {
    if (expectedRevision !== this.revision) {
      throw new RevisionConflict(this.revision);
    }
    this.state = cloneState(state);
    this.revision += 1;
    return this.revision;
  }

  async deleteAccount(expectedRevision: number): Promise<number> {
    if (expectedRevision !== this.revision) {
      throw new RevisionConflict(this.revision);
    }
    this.state = emptyState();
    this.revision += 1;
    return this.revision;
  }
}