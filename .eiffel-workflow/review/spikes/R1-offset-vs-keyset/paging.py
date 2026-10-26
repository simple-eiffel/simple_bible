"""R1 (Phase 2 review, concordance slice, 2026-10-26): BIB_CONC_PACK.place_page pages by
OFFSET. How does a deep page cost compare with keyset paging (token_id > last seen)?
Read-only against conc.db. Usage: python -I paging.py <conc.db>"""
import sqlite3, sys, time
c = sqlite3.connect("file:" + sys.argv[1] + "?mode=ro", uri=True)
base = ("SELECT t.token_id, t.surface, t.stem, w.code, u.div1, u.div2 FROM token t "
        "JOIN unit u ON u.unit_id = t.unit_id JOIN work w ON w.work_id = u.work_id "
        "WHERE t.lemma_id = 9380 AND t.corpus_id = 4 ")
ids = [r[0] for r in c.execute("SELECT token_id FROM token WHERE lemma_id = 9380 AND corpus_id = 4 ORDER BY token_id")]
print("sqlite", sqlite3.sqlite_version, "| places:", len(ids))
for off in (0, 44000, 88200):
    best = 1e9; bestk = 1e9
    for _ in range(3):
        t = time.perf_counter(); r1 = c.execute(base + "ORDER BY t.token_id LIMIT 200 OFFSET ?", (off,)).fetchall(); best = min(best, time.perf_counter() - t)
        last = ids[off - 1] if off else 0
        t = time.perf_counter(); r2 = c.execute(base + "AND t.token_id > ? ORDER BY t.token_id LIMIT 200", (last,)).fetchall(); bestk = min(bestk, time.perf_counter() - t)
    same = [r[0] for r in r1] == [r[0] for r in r2]
    print("page at row %6d: OFFSET %7.1f ms | keyset %6.1f ms | same rows: %s" % (off, best * 1000, bestk * 1000, same))
