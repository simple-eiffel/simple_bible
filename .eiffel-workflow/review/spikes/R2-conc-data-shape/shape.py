"""R2: does today's conc.db hold the values the value-class contracts expect? Read-only."""
import sqlite3, sys
c = sqlite3.connect("file:" + sys.argv[1] + "?mode=ro", uri=True)
q = lambda s: c.execute(s).fetchall()
print("sqlite", sqlite3.sqlite_version, "| user_version:", q("PRAGMA user_version")[0][0])
print("token columns:", [r[1] for r in q("PRAGMA table_info(token)")])
print("lemma columns:", [r[1] for r in q("PRAGMA table_info(lemma)")])
print("lemma_basis values:")
for v, n in q("SELECT lemma_basis, count(*) FROM token GROUP BY lemma_basis ORDER BY 2 DESC"):
    print("  %-24r %10d" % (v, n))
print("tokens with lemma_id NULL or 0:", q("SELECT count(*) FROM token WHERE lemma_id IS NULL OR lemma_id = 0")[0][0])
print("tokens with empty or NULL surface:", q("SELECT count(*) FROM token WHERE surface IS NULL OR surface = ''")[0][0])
print("lemmas by language, empty translit / all:")
for lang, e, n in q("SELECT language, sum(translit IS NULL OR translit = ''), count(*) FROM lemma GROUP BY language ORDER BY 3 DESC"):
    print("  %-6s %8d / %8d" % (lang, e, n))
