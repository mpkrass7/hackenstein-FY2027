import { sql } from 'drizzle-orm';
import { getExecutionContext } from '@databricks/appkit';
import type { AppDb } from './index.js';
import { recoveryRecommendations } from './schema.js';
import type { MoveOption } from './schema.js';

/**
 * Boot-time Delta → Lakebase sync — NorthPeak Store Ops.
 *
 * > Build 1 provisions REAL Lakebase Synced Tables for the read-only data the
 * > app serves: `app.store_sku_position`, `app.open_shortfalls`,
 * > `app.products`, `app.products_search`. Those are managed by the Lakebase
 * > sync (owned by the sync writer role) and the app just READS them — it does
 * > NOT sync or write them here.
 *
 * The ONLY table this fills is `app.recovery_recommendations` — the ML model's
 * ranked moves — because Build 1 does not sync that one. `ops_actions` and the
 * chat tables are the app's own writable tables and start empty.
 *
 * Fault-tolerant: if the recovery Gold table doesn't exist yet (the ML step),
 * we log + leave the mirror empty rather than failing boot. Idempotent in the
 * "only-if-empty" sense; pass `{ forceIfAnyEmpty: true }` to re-pull.
 */

type DataConfig = {
  catalog: string;
  schema: string;
  tables: {
    // Present in config for the synced tables, but NOT synced here (Build 1
    // Lakebase Synced Tables own them). Kept optional so the app config type
    // stays a superset.
    storeSkuPosition?: string;
    openShortfalls?: string;
    /** gold_recovery_recommendations — the ML model's ranked moves. The only
     *  table synced here; Build 1 does not sync it. */
    recoveryRecommendations?: string;
  };
};

export async function syncFromDelta(
  db: AppDb,
  cfg: DataConfig,
  opts: { forceIfAnyEmpty?: boolean } = {},
): Promise<void> {
  const recoveryTable = cfg.tables.recoveryRecommendations;
  if (!recoveryTable) {
    console.log(
      '[sync] no recovery_recommendations Delta table configured — nothing to sync (store/shortfall/products come from Lakebase Synced Tables).',
    );
    return;
  }

  const exists = await db.execute(
    sql`SELECT COUNT(*)::int AS n FROM app.recovery_recommendations`,
  );
  const n = (exists.rows[0] as { n: number } | undefined)?.n ?? 0;
  if (n > 0 && !opts.forceIfAnyEmpty) return;

  const warehouseId = process.env.DATABRICKS_WAREHOUSE_ID;
  if (!warehouseId) {
    console.warn('[sync] DATABRICKS_WAREHOUSE_ID not set — skipping recovery sync');
    return;
  }

  console.log('[sync] Syncing recovery_recommendations Delta → Lakebase…');
  const t0 = Date.now();
  const fq = `${cfg.catalog}.${cfg.schema}.${recoveryTable}`;

  // Best-effort: the recovery Gold table is the ML step and may not exist yet.
  const recoveryRows = await execSql<{
    store_id: string;
    product_id: string;
    recommended_move: string | null;
    recommended_source_store_id: string | null;
    recommended_substitute_product_id: string | null;
    recommended_units: number | null;
    predicted_recaptured_usd: number | null;
    predicted_net_value_usd: number | null;
    move_ranking: string | null;
    scored_at: string | null;
  }>(
    warehouseId,
    `SELECT store_id, product_id, recommended_move,
            recommended_source_store_id, recommended_substitute_product_id,
            recommended_units, predicted_recaptured_usd,
            predicted_net_value_usd,
            to_json(move_ranking) AS move_ranking, scored_at
     FROM ${fq}`,
  ).catch((e) => {
    console.warn(
      `[sync] recovery_recommendations not available yet — leaving that mirror empty: ${(e as Error).message}`,
    );
    return [] as never[];
  });

  if (recoveryRows.length) {
    await chunkInsert(recoveryRows, 5_000, (chunk) =>
      db
        .insert(recoveryRecommendations)
        .values(
          chunk.map((r) => ({
            id: `${r.store_id}:${r.product_id}`,
            storeId: r.store_id,
            productId: r.product_id,
            // eslint-disable-next-line @typescript-eslint/no-unnecessary-type-assertion
            recommendedMove: (r.recommended_move === 'transfer' ||
            r.recommended_move === 'expedite' ||
            r.recommended_move === 'substitute' ||
            r.recommended_move === 'markdown_hold'
              ? r.recommended_move
              : null) as
              | 'transfer'
              | 'expedite'
              | 'substitute'
              | 'markdown_hold'
              | null,
            recommendedSourceStoreId: r.recommended_source_store_id,
            recommendedSubstituteProductId: r.recommended_substitute_product_id,
            recommendedUnits:
              r.recommended_units === null ? null : Number(r.recommended_units),
            predictedRecapturedUsd:
              r.predicted_recaptured_usd === null
                ? null
                : Number(r.predicted_recaptured_usd),
            predictedNetValueUsd:
              r.predicted_net_value_usd === null
                ? null
                : Number(r.predicted_net_value_usd),
            moveRanking: parseMoveRanking(r.move_ranking),
          })),
        )
        .onConflictDoNothing(),
    );
  }
  console.log(
    `[sync] recovery recommendations: ${recoveryRows.length} (${((Date.now() - t0) / 1000).toFixed(1)}s)`,
  );
}

/** `move_ranking` comes back as a JSON string (we `to_json(...)` it in SQL
 *  because the SQL Statements API serializes complex types as strings).
 *  Parse defensively — a malformed ranking just becomes []. */
function parseMoveRanking(raw: string | null): MoveOption[] {
  if (!raw) return [];
  try {
    const parsed = JSON.parse(raw) as unknown;
    return Array.isArray(parsed) ? (parsed as MoveOption[]) : [];
  } catch {
    return [];
  }
}

/**
 * Reset: truncate the app's OWN tables (chat state, the writable action table,
 * and the recovery_recommendations mirror), then re-sync recovery. The
 * Build-1 Lakebase Synced Tables (store_sku_position, open_shortfalls,
 * products, products_search) are READ-ONLY and owned by the sync — never
 * touched here.
 */
export async function wipeMirroredTables(db: AppDb): Promise<void> {
  await db.transaction(async (tx) => {
    await tx.execute(sql`TRUNCATE TABLE app.feedback RESTART IDENTITY CASCADE`);
    await tx.execute(sql`TRUNCATE TABLE app.messages RESTART IDENTITY CASCADE`);
    await tx.execute(sql`TRUNCATE TABLE app.conversations RESTART IDENTITY CASCADE`);
    // The writable action table — the only place agent writes land.
    await tx.execute(sql`TRUNCATE TABLE app.ops_actions RESTART IDENTITY CASCADE`);
    // App-owned recovery mirror — re-pulled by syncFromDelta after this.
    await tx.execute(
      sql`TRUNCATE TABLE app.recovery_recommendations RESTART IDENTITY CASCADE`,
    );
  });
}

async function execSql<T>(
  warehouseId: string,
  statement: string,
): Promise<T[]> {
  const { client } = getExecutionContext();
  type StmtResp = {
    statement_id: string;
    status: { state: string; error?: { message: string } };
    manifest?: {
      schema: { columns: Array<{ name: string }> };
      chunks?: Array<{ chunk_index: number; row_count: number }>;
    };
    result?: {
      chunk_index: number;
      row_count: number;
      data_array?: Array<Array<unknown>>;
      next_chunk_index?: number;
    };
  };

  const initial = (await client.apiClient.request({
    method: 'POST',
    path: '/api/2.0/sql/statements',
    payload: {
      statement,
      warehouse_id: warehouseId,
      wait_timeout: '50s',
      on_wait_timeout: 'CONTINUE',
      disposition: 'INLINE',
      format: 'JSON_ARRAY',
    },
    headers: new Headers(),
    raw: false,
    query: {},
  })) as StmtResp;

  // Cap total polling at 10 minutes. The warehouse can take a couple of
  // minutes to spin from idle + scan, but a state stuck in RUNNING beyond
  // 10 min is broken — fail loud instead of silently blocking boot forever.
  const POLL_DEADLINE_MS = 10 * 60 * 1000;
  const startedAt = Date.now();

  let cur = initial;
  while (
    cur.status.state !== 'SUCCEEDED' &&
    cur.status.state !== 'FAILED' &&
    cur.status.state !== 'CANCELED'
  ) {
    if (Date.now() - startedAt > POLL_DEADLINE_MS) {
      throw new Error(
        `[sync] SQL still ${cur.status.state} after 10 minutes — aborting (statement_id=${cur.statement_id})`,
      );
    }
    await new Promise((r) => setTimeout(r, 1000));
    cur = (await client.apiClient.request({
      method: 'GET',
      path: `/api/2.0/sql/statements/${cur.statement_id}`,
      headers: new Headers(),
      raw: false,
      query: {},
    })) as StmtResp;
  }
  if (cur.status.state !== 'SUCCEEDED') {
    throw new Error(
      `[sync] SQL failed: ${cur.status.error?.message ?? cur.status.state}`,
    );
  }

  const cols = cur.manifest?.schema.columns.map((c) => c.name) ?? [];
  const rows: T[] = [];
  let chunk = cur.result;
  while (chunk) {
    for (const row of chunk.data_array ?? []) {
      const obj: Record<string, unknown> = {};
      for (let i = 0; i < cols.length; i++) obj[cols[i]] = row[i];
      rows.push(obj as T);
    }
    if (chunk.next_chunk_index === undefined || chunk.next_chunk_index === null) break;
    chunk = (await client.apiClient.request({
      method: 'GET',
      path: `/api/2.0/sql/statements/${cur.statement_id}/result/chunks/${chunk.next_chunk_index}`,
      headers: new Headers(),
      raw: false,
      query: {},
    })) as StmtResp['result'];
  }
  return rows;
}

async function chunkInsert<T>(
  rows: T[],
  size: number,
  fn: (chunk: T[]) => Promise<unknown>,
): Promise<void> {
  for (let i = 0; i < rows.length; i += size) {
    await fn(rows.slice(i, i + size));
  }
}
