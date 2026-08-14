#!/usr/bin/env python3
"""Vérifie la cohérence de la configuration Google Sign-In Android.

Cause n°1 de `ApiException: 10` (DEVELOPER_ERROR) : le certificat de signature
de l'APK n'est pas déclaré dans le client OAuth Android du projet Firebase /
Google Cloud. Le fichier `google-services.json` ne contient alors AUCUN client
`client_type: 1`, ou un `certificate_hash` différent du SHA-1 du keystore.

Usage :
  python3 scripts/verifier-google-signin.py \
      --google-services cotis_app/android/app/google-services.json \
      [--keystore cotis_app/android/upload-keystore.jks \
       --keystore-password ... --key-alias ...] \
      [--web-client-id 5354...apps.googleusercontent.com]

Sortie : code 0 si la configuration peut fonctionner, 1 sinon (avec la
marche à suivre exacte).
"""
from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys

PACKAGE_NAME = "com.kasedapp"


def sha1_du_keystore(keystore: str, password: str, alias: str | None) -> str | None:
    cmd = ["keytool", "-list", "-v", "-keystore", keystore, "-storepass", password]
    if alias:
        cmd += ["-alias", alias]
    try:
        out = subprocess.run(cmd, capture_output=True, text=True, check=True).stdout
    except (subprocess.CalledProcessError, FileNotFoundError) as exc:
        print(f"::warning::Lecture du keystore impossible : {exc}")
        return None
    match = re.search(r"SHA1:\s*([0-9A-Fa-f:]+)", out)
    return match.group(1).replace(":", "").lower() if match else None


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--google-services", required=True)
    parser.add_argument("--keystore")
    parser.add_argument("--keystore-password", default="")
    parser.add_argument("--key-alias")
    parser.add_argument("--web-client-id")
    args = parser.parse_args()

    with open(args.google_services, encoding="utf-8") as handle:
        config = json.load(handle)

    clients = [
        client
        for client in config.get("client", [])
        if client.get("client_info", {}).get("android_client_info", {}).get("package_name")
        == PACKAGE_NAME
    ]
    if not clients:
        print(f"::error::google-services.json ne contient aucun client pour {PACKAGE_NAME}.")
        return 1

    oauth_clients = [o for client in clients for o in client.get("oauth_client", [])]
    android_clients = [o for o in oauth_clients if o.get("client_type") == 1]
    web_clients = [o for o in oauth_clients if o.get("client_type") == 3]

    erreurs: list[str] = []

    if not android_clients:
        erreurs.append(
            "Aucun client OAuth Android (client_type 1) dans google-services.json.\n"
            "  → Google Sign-In échouera avec ApiException: 10 sur TOUS les appareils.\n"
            "  → Firebase Console → Paramètres du projet → Vos applications → "
            f"{PACKAGE_NAME} → « Ajouter une empreinte » (SHA-1), puis retélécharger "
            "google-services.json et mettre à jour le secret GOOGLE_SERVICES_JSON_B64."
        )

    if args.web_client_id and not any(
        o.get("client_id") == args.web_client_id for o in web_clients
    ):
        erreurs.append(
            "Le Web Client ID fourni n'est pas celui de google-services.json "
            f"({[o.get('client_id') for o in web_clients]}). Le bridge InsForge "
            "rejettera l'idToken (audience mismatch)."
        )

    empreintes = {
        (o.get("android_info", {}).get("certificate_hash") or "").lower()
        for o in android_clients
    }
    if args.keystore:
        sha1 = sha1_du_keystore(args.keystore, args.keystore_password, args.key_alias)
        if sha1:
            print(f"SHA-1 du keystore de signature : {sha1}")
            if empreintes and sha1 not in empreintes:
                erreurs.append(
                    "Le SHA-1 du keystore n'est déclaré dans aucun client OAuth Android "
                    f"(déclarés : {sorted(empreintes) or 'aucun'}).\n"
                    "  → Ajoutez cette empreinte dans Firebase Console puis retéléchargez "
                    "google-services.json."
                )
    else:
        print(
            "::warning::Aucun keystore fourni : APK signé en debug → le SHA-1 de debug "
            "doit lui aussi être déclaré dans Firebase pour tester Google Sign-In."
        )

    if erreurs:
        for erreur in erreurs:
            print(f"::error::{erreur}")
        return 1

    print("✅ Configuration Google Sign-In cohérente")
    return 0


if __name__ == "__main__":
    sys.exit(main())
