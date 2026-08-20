/**
 * Migration InsForge pour Kased App
 *
 * Ce script doit être exécuté manuellement sur l'instance InsForge
 * pour ajouter les colonnes manquantes.
 *
 * Usage:
 *   INSFORGE_ADMIN_KEY=xxx python3 scripts/insforge-migrate.py
 */

import json
import sys
import urllib.request
import urllib.error

INSFORGE_URL = "https://pu74z8pe.us-east.insforge.app"

MIGRATIONS = {
    "membres": [
        ("montant_en_avance", "DOUBLE PRECISION NOT NULL DEFAULT 0"),
        ("total_dons", "DOUBLE PRECISION NOT NULL DEFAULT 0"),
        ("version", "INTEGER NOT NULL DEFAULT 1"),
        ("device_id", "TEXT"),
        ("is_deleted", "BOOLEAN NOT NULL DEFAULT false"),
        ("deleted_at", "TIMESTAMPTZ"),
        ("deleted_by", "TEXT"),
    ],
    "cultes": [
        ("note", "TEXT"),
        ("version", "INTEGER NOT NULL DEFAULT 1"),
        ("device_id", "TEXT"),
        ("is_deleted", "BOOLEAN NOT NULL DEFAULT false"),
        ("deleted_at", "TIMESTAMPTZ"),
        ("deleted_by", "TEXT"),
        ("member_ids", "TEXT[]"),
    ],
    "cotisations": [
        ("version", "INTEGER NOT NULL DEFAULT 1"),
        ("device_id", "TEXT"),
        ("is_deleted", "BOOLEAN NOT NULL DEFAULT false"),
        ("deleted_at", "TIMESTAMPTZ"),
        ("deleted_by", "TEXT"),
    ],
}

def alter_table(admin_key: str, table: str, column: str, type_: str):
    """Ajoute une colonne si elle n'existe pas."""
    sql = f"ALTER TABLE {table} ADD COLUMN IF NOT EXISTS {column} {type_}"

    req = urllib.request.Request(
        f"{INSFORGE_URL}/api/database/execute",
        data=json.dumps({"sql": sql}).encode(),
        headers={
            "Authorization": f"Bearer {admin_key}",
            "apikey": admin_key,
            "Content-Type": "application/json",
        },
        method="POST",
    )

    try:
        with urllib.request.urlopen(req) as resp:
            result = json.loads(resp.read().decode())
            print(f"  ✅ {table}.{column} → {result.get('message', 'OK')}")
            return True
    except urllib.error.HTTPError as e:
        error_body = e.read().decode()
        if "already exists" in error_body.lower():
            print(f"  ⏭️  {table}.{column} existe déjà")
            return True
        print(f"  ❌ {table}.{column} → {error_body[:200]}")
        return False

def main():
    if len(sys.argv) < 2:
        print("Usage: python3 scripts/insforge-migrate.py <ADMIN_API_KEY>")
        print("Or set INSFORGE_ADMIN_KEY environment variable")
        sys.exit(1)

    admin_key = sys.argv[1]

    print(f"🚀 Migration InsForge pour Kased App")
    print(f"   URL: {INSFORGE_URL}")
    print()

    success_count = 0
    error_count = 0

    for table, columns in MIGRATIONS.items():
        print(f"📋 Table: {table}")
        for column, type_ in columns:
            if alter_table(admin_key, table, column, type_):
                success_count += 1
            else:
                error_count += 1
        print()

    print(f"✅ {success_count} colonnes migrées")
    if error_count > 0:
        print(f"❌ {error_count} erreurs")
        sys.exit(1)

if __name__ == "__main__":
    main()
