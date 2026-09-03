"""
Build an extended semantic graph for the Kased App project.
Combines the existing graphify AST graph with:
  1. Rich node metadata (role, stability, responsibility)
  2. Semantic relation types (ORCHESTRATES, DEPENDS_ON, etc.)
  3. Wiki link resolution
  4. Business rule nodes
  5. JSON schema for querying + embeddings-ready serialization
  6. Cross-process links (Flutter <-> InsForge functions)
"""

import json
import re
from pathlib import Path
from collections import defaultdict, Counter

# ── Paths ──────────────────────────────────────────────────────────────────────
GRAPH_JSON   = Path("graphify-out/graph.json")
WIKI_INDEX   = Path("graphify-out/wiki/index.md")
OUT_DIR      = Path("graphify-out")

# ── Load base graph ───────────────────────────────────────────────────────────
print("Loading base graph...")
with GRAPH_JSON.open() as f:
    base_graph = json.load(f)

ast_nodes = {n["id"]: n for n in base_graph["nodes"]}
ast_links = base_graph["links"]
print(f"  {len(ast_nodes)} AST nodes, {len(ast_links)} AST edges")

# ── Utility ────────────────────────────────────────────────────────────────────
def normalize_path(raw: str) -> str:
    if not raw:
        return ""
    p = raw.replace("\\", "/")
    # Handle Windows absolute paths like C:/Users/.../cotis_app/lib/...
    if "/cotis_app/lib/" in p:
        return p.split("/cotis_app/lib/", 1)[1]
    if "/cotis_app/functions/" in p:
        return "functions/" + p.split("/cotis_app/functions/", 1)[1]
    # Handle relative paths like cotis_app/lib/...
    if p.startswith("cotis_app/lib/"):
        return p[len("cotis_app/"):]  # removes "cotis_app/" leaving "lib/..."
    if p.startswith("cotis_app/functions/"):
        return "functions/" + p[len("cotis_app/functions/"):]
    while p.startswith("../"):
        p = p[3:]
    return p

def node_label_to_file(label: str) -> str:
    """Some nodes have label = the file path itself."""
    for n in ast_nodes.values():
        if n["label"] == label:
            return normalize_path(n.get("source_file", ""))
    return ""

# ── Step 1: Assign rich metadata ───────────────────────────────────────────────
print("Step 1: Assigning rich node metadata...")

ROLE_PATTERNS = {
    "model":         r"^models/[^/]+\.(dart|js)$",
    "screen":        r"^screens/[^/]+/[^/]+\.dart$",
    "provider":      r"^providers/[^/]+\.dart$",
    "controller":    r"^controllers/[^/]+\.dart$",
    "service":       r"^core/(?:services|export|pdf|sync|realtime|notifications)/[^/]+\.dart$",
    "logic":         r"^core/logic/[^/]+\.dart$",
    "theme":         r"^core/theme/[^/]+\.dart$",
    "router":        r"^core/router/[^/]+\.dart$",
    "insforge":      r"^core/insforge/[^/]+\.dart$",
    "constants":     r"^core/constants\.dart$",
    "prefs":         r"^core/preferences/[^/]+\.dart$",
    "push_function": r"^functions/[^/]+\.js$",
    "native_android": r"android/",
    "native_ios":     r"ios/",
    "native_windows": r"windows/",
}

SEMANTIC_ROLE_PAIRS = [
    ("screen",    "PROVISIONS"),
    ("provider",  "MANAGES"),
    ("controller","ORCHESTRATES"),
    ("model",     "PERSISTS_AS"),
    ("service",   "IMPLEMENTS"),
    ("logic",     "ENCAPSULATES"),
    ("insforge","CALLS_API"),
    ("push_function","HANDLES_EVENT"),
    ("router",    "ROUTES_TO"),
    ("theme",     "APPLIES"),
]

degree = Counter()
for link in ast_links:
    degree[link["source"]] += 1
    degree[link["target"]] += 1

enriched_nodes = []
node_by_file: dict[str, list[str]] = defaultdict(list)
node_by_role: dict[str, list[str]] = defaultdict(list)

for nid, node in ast_nodes.items():
    src_file = node.get("source_file", "")
    rel_path = normalize_path(src_file)
    label = node["label"]
    in_lib = bool(rel_path)

    # Role classification
    role = "unknown"
    for r, pat in ROLE_PATTERNS.items():
        if re.search(pat, rel_path) or re.search(pat, src_file):
            role = r
            break

    if role == "unknown" and in_lib:
        file_role_map = {
            "models/": "model", "providers/": "provider", "screens/": "screen",
            "controllers/": "controller", "core/services/": "service",
            "core/logic/": "logic", "core/theme/": "theme", "core/router/": "router",
            "core/insforge/": "insforge", "core/preferences/": "prefs",
            "core/sync/": "service", "core/realtime/": "service",
            "core/notifications/": "service", "core/export/": "service",
            "core/pdf/": "service",
        }
        for prefix, r in file_role_map.items():
            if prefix in rel_path:
                role = r
                break

    deg = degree.get(nid, 0)
    stability = "stable" if deg < 10 else ("moderate" if deg < 30 else "volatile")

    domain = "infrastructure"
    if role in ("model", "screen", "provider", "controller", "service", "logic", "push_function"):
        if "membre" in rel_path.lower() or label.lower().startswith("membre"):
            domain = "membres"
        elif "culte" in rel_path.lower() or label.lower().startswith("culte"):
            domain = "cultes"
        elif "cotisation" in rel_path.lower() or label.lower().startswith("cotisation"):
            domain = "cotisations"
        elif "sync" in rel_path.lower():
            domain = "sync"
        elif "realtime" in rel_path.lower():
            domain = "temps_reel"
        elif "auth" in rel_path.lower() or "login" in rel_path.lower():
            domain = "authentification"
        elif "notif" in rel_path.lower() or "push" in rel_path.lower() or "onesignal" in rel_path.lower():
            domain = "notifications"
        elif "stats" in rel_path.lower() or "graph" in rel_path.lower():
            domain = "stats"
        elif "corbeille" in rel_path.lower() or "trash" in rel_path.lower():
            domain = "corbeille"
        elif "export" in rel_path.lower() or "pdf" in rel_path.lower():
            domain = "export"
        elif "theme" in rel_path.lower() or "motion" in rel_path.lower():
            domain = "them_UI"
        elif "router" in rel_path.lower():
            domain = "navigation"
        elif "prefs" in rel_path.lower() or "storage" in rel_path.lower():
            domain = "preferences"
        elif "update" in rel_path.lower():
            domain = "mise_a_jour"

    enriched = {
        **node,
        "role": role,
        "domain": domain,
        "stability": stability,
        "degree": deg,
        "lib_path": rel_path,
        "in_lib": in_lib,
    }
    enriched_nodes.append(enriched)

    if in_lib:
        node_by_file[rel_path].append(nid)
        node_by_role[role].append(nid)

print(f"  Enriched {len(enriched_nodes)} nodes")
print(f"  Roles: {dict(Counter(n['role'] for n in enriched_nodes).most_common())}")
print(f"  Domains: {dict(Counter(n['domain'] for n in enriched_nodes).most_common())}")

# ── Step 2: Semantic relation types ──────────────────────────────────────────
print("\nStep 2: Building semantic relations...")

role_map = {n["id"]: n["role"] for n in enriched_nodes}
file_map = {n["id"]: n["lib_path"] for n in enriched_nodes}

semantic_links = []
seen_semantic = set()

for link in ast_links:
    src_id = link["source"]
    tgt_id = link["target"]
    src_role = role_map.get(src_id, "unknown")
    tgt_role = role_map.get(tgt_id, "unknown")
    src_file = file_map.get(src_id, "")
    tgt_file = file_map.get(tgt_id, "")

    if link.get("relation") == "imports" and not src_file and not tgt_file:
        continue

    ast_rel = link.get("relation", "")
    base_semantic = None

    if ast_rel == "calls" and src_role in ("screen", "provider", "service", "controller") and tgt_role == "service":
        base_semantic = "CALLS"
    elif ast_rel == "calls" and src_role == "screen" and tgt_role == "provider":
        base_semantic = "USES_PROVIDER"
    elif ast_rel == "calls" and src_role == "provider" and tgt_role == "service":
        base_semantic = "CALLS"
    elif ast_rel == "calls" and src_role == "service" and tgt_role == "logic":
        base_semantic = "USES_LOGIC"
    elif ast_rel == "contains" and src_role in ("model", "screen", "provider"):
        base_semantic = "CONTAINS"
    elif ast_rel == "imports" and src_file and tgt_file:
        base_semantic = "DEPENDS_ON"
    elif ast_rel == "imports" and tgt_file:
        base_semantic = "DEPENDS_ON"
    elif ast_rel == "method" and src_role in ("service", "controller"):
        base_semantic = "EXPOSES"
    elif ast_rel == "rationale_for":
        base_semantic = "JUSTIFIES"

    rel_tuple = (src_role, tgt_role)
    if rel_tuple in SEMANTIC_ROLE_PAIRS:
        rel_type = next(r for s, t, r in SEMANTIC_ROLE_PAIRS if (s, t) == rel_tuple)
    else:
        rel_type = base_semantic

    if not rel_type:
        continue

    edge_key = (src_id, tgt_id, rel_type)
    if edge_key in seen_semantic:
        continue
    seen_semantic.add(edge_key)

    semantic_links.append({
        "relation": rel_type,
        "source": src_id,
        "target": tgt_id,
        "confidence": 0.9 if rel_type != "DEPENDS_ON" else 0.7,
        "source_file": src_file,
        "target_file": tgt_file,
    })

print(f"  {len(semantic_links)} semantic edges")

# ── Step 3: Wiki link resolution (hardcoded from known structure) ─────────────
print("\nStep 3: Resolving wiki links...")

# Hardcoded wiki module -> file patterns (from wiki/index.md)
WIKI_MODULE_MAP = {
    "Authentification": [
        "providers/auth_provider.dart", "services/auth_service.dart",
        "screens/onboarding_screen.dart", "screens/login_screen.dart", "screens/signup_screen.dart",
        "core/router/app_router.dart",
    ],
    "Membres": [
        "controllers/membre_controller.dart", "models/membre.dart",
        "screens/membres/", "widgets/kased_avatar.dart",
    ],
    "Cultes": [
        "controllers/culte_controller.dart", "models/culte.dart",
        "screens/cultes/", "core/logic/culte_lock.dart",
    ],
    "Cotisations": [
        "controllers/cotisation_controller.dart", "models/cotisation.dart",
        "core/logic/cotisation_logic.dart", "core/logic/culte_lock.dart",
    ],
    "Sync Offline": [
        "core/sync/sync_manager.dart", "core/local_cache.dart",
        "models/sync_operation.dart",
    ],
    "Donnees locales": [
        "core/isar_local_cache.dart", "providers/isar_provider.dart",
    ],
    "Backend API": [
        "core/insforge/insforge_service.dart", "core/insforge/insforge_config.dart",
    ],
    "Theme et UI": [
        "core/theme/app_theme.dart", "core/theme/motion_tokens.dart",
        "widgets/kased_card.dart", "widgets/empty_state.dart",
    ],
    "Notifications": [
        "core/services/push_notify_service.dart", "core/services/onesignal_service.dart",
        "core/notifications/notification_service.dart",
    ],
    "Stats": [
        "providers/stats_graphiques_provider.dart", "screens/stats/stats_screen.dart",
        "core/services/stats_service.dart",
    ],
    "Corbeille": [
        "models/corbeille_item.dart", "screens/corbeille/corbeille_screen.dart",
        "core/logic/culte_lock.dart",
    ],
    "Export": [
        "core/export/cotisation_export_service.dart",
        "core/pdf/member_report_pdf_service.dart", "core/pdf/registre_pdf_service.dart",
    ],
    "Temps reel": [
        "core/realtime/", "core/realtime/presence_service.dart",
    ],
    "Preferences": [
        "core/preferences/app_prefs.dart",
    ],
}

wiki_node_map: dict[str, list[str]] = defaultdict(list)
for mod, patterns in WIKI_MODULE_MAP.items():
    for pat in patterns:
        for nid, n in ast_nodes.items():
            n_file = normalize_path(n.get("source_file", ""))
            n_label = n.get("label", "")
            if pat in n_file or pat in n_label or n_label.endswith(pat.replace("/", "").replace(".dart", "")):
                wiki_node_map[mod].append(nid)

print(f"  {len(wiki_node_map)} wiki modules resolved to {sum(len(v) for v in wiki_node_map.values())} nodes")
for mod, ids in wiki_node_map.items():
    print(f"    {mod}: {len(ids)} nodes")

# ── Step 4: Business rule nodes ───────────────────────────────────────────────
print("\nStep 4: Creating business rule nodes...")

RULES = [
    {
        "id": "rule_cotisation_montant_defaut",
        "label": "CotisationMontantParDefaut",
        "role": "business_rule",
        "domain": "cotisations",
        "statement": "Le montant par défaut d'une cotisation est de 50 FCFA.",
        "source": "core/constants.dart",
        "related_nodes": [],
    },
    {
        "id": "rule_verrouillage_culte",
        "label": "VerrouillageCulte30j",
        "role": "business_rule",
        "domain": "cultes",
        "statement": "Un culte est verrouillé (lecture seule) après 30 jours.",
        "source": "core/logic/culte_lock.dart",
        "related_nodes": [],
    },
    {
        "id": "rule_purge_corbeille",
        "label": "PurgeCorbeille30j",
        "role": "business_rule",
        "domain": "corbeille",
        "statement": "Les éléments de la corbeille sont purgés après 30 jours.",
        "source": "core/constants.dart",
        "related_nodes": [],
    },
    {
        "id": "rule_sync_throttle",
        "label": "SyncThrottle5min",
        "role": "business_rule",
        "domain": "sync",
        "statement": "Max 1 synchronisation complète toutes les 5 minutes.",
        "source": "core/constants.dart",
        "related_nodes": [],
    },
    {
        "id": "rule_sync_retry",
        "label": "SyncMaxRetries5",
        "role": "business_rule",
        "domain": "sync",
        "statement": "Chaque opération sync retry max 5 fois avec backoff exponentiel.",
        "source": "core/constants.dart",
        "related_nodes": [],
    },
    {
        "id": "rule_auth_google_timeout",
        "label": "GoogleAuthTimeout120s",
        "role": "business_rule",
        "domain": "authentification",
        "statement": "Le timeout de l'authentification Google est de 120 secondes.",
        "source": "core/constants.dart",
        "related_nodes": [],
    },
    {
        "id": "rule_soft_delete_only",
        "label": "SoftDeleteUniquement",
        "role": "business_rule",
        "domain": "corbeille",
        "statement": "Les suppressions sont toujours des soft-delete (never hard-delete).",
        "source": "models/corbeille_item.dart",
        "related_nodes": [],
    },
    {
        "id": "rule_retard_ignore_adhesion",
        "label": "RetardIgnoreAvantAdhesion",
        "role": "business_rule",
        "domain": "cotisations",
        "statement": "Les cultes antérieurs à la date d'adhésion ne comptent pas dans le calcul des retards.",
        "source": "core/logic/cotisation_logic.dart",
        "related_nodes": [],
    },
    {
        "id": "rule_paiement_avance",
        "label": "PaiementEnAvance",
        "role": "business_rule",
        "domain": "cotisations",
        "statement": "Un paiement avant la date du culte reçoit le statut 'enAvance'.",
        "source": "core/logic/cotisation_logic.dart",
        "related_nodes": [],
    },
]

for rule in RULES:
    src = rule["source"]
    for nid, n in ast_nodes.items():
        n_file = normalize_path(n.get("source_file", ""))
        if src in n_file or n.get("lib_path") == src:
            rule["related_nodes"].append(nid)

print(f"  {len(RULES)} business rule nodes created")
for r in RULES:
    print(f"    {r['label']} => {len(r['related_nodes'])} linked nodes")

# ── Step 5: Cross-process links ───────────────────────────────────────────────
print("\nStep 5: Building cross-process links...")

# Find function file nodes (only file-level nodes, not sub-functions)
function_file_nodes = {}
for n in ast_nodes.values():
    src = normalize_path(n.get("source_file", ""))
    label = n.get("label", "")
    # Only match file-level nodes: label ends with .js and source is the file itself
    if src.startswith("functions/") and src.endswith(".js") and label.endswith(".js"):
        fn_name = src.replace("functions/", "").replace(".js", "")
        function_file_nodes[fn_name] = n["id"]

print(f"  Function files: {function_file_nodes}")

# Find Flutter nodes that interact with functions
flutter_push_nodes = []
flutter_auth_nodes = []
for nid, n in ast_nodes.items():
    lp = n.get("lib_path", "")
    lbl = n.get("label", "")
    if "push_notify" in lp.lower() or "onesignal" in lbl.lower() or "onesignal" in lp.lower():
        flutter_push_nodes.append(nid)
    if "auth" in lp.lower() or "auth" in lbl.lower():
        flutter_auth_nodes.append(nid)

print(f"  Flutter push nodes: {len(flutter_push_nodes)}")
print(f"  Flutter auth nodes: {len(flutter_auth_nodes)}")

cross_process_links = []

if "push-notify" in function_file_nodes:
    fn_id = function_file_nodes["push-notify"]
    for sn_id in flutter_push_nodes:
        cross_process_links.append({
            "relation": "TRIGGERS_FUNCTION",
            "source": sn_id,
            "target": fn_id,
            "confidence": 0.95,
            "source_file": file_map.get(sn_id, ""),
            "target_file": "functions/push-notify.js",
        })

if "google-auth-bridge" in function_file_nodes:
    fn_id = function_file_nodes["google-auth-bridge"]
    for sn_id in flutter_auth_nodes:
        cross_process_links.append({
            "relation": "CALLS_FUNCTION",
            "source": sn_id,
            "target": fn_id,
            "confidence": 0.95,
            "source_file": file_map.get(sn_id, ""),
            "target_file": "functions/google-auth-bridge.js",
        })

print(f"  {len(cross_process_links)} cross-process links")

# ── Step 6: Intra-module cohesion links ───────────────────────────────────────
print("\nStep 6: Adding intra-module cohesion links...")

module_links = []
file_groups: dict[str, list[str]] = defaultdict(list)
for nid, n in ast_nodes.items():
    lib_path = n.get("lib_path", "")
    if lib_path:
        parts = lib_path.split("/")
        module = parts[0] if len(parts) > 1 else "root"
        file_groups[module].append(nid)

for module, ids in file_groups.items():
    if module == "root":
        continue
    roles_in_module = [(nid, role_map.get(nid, "unknown")) for nid in ids]
    for sid, srole in roles_in_module:
        if srole == "screen":
            for tid, trole in roles_in_module:
                if trole in ("provider", "service", "model"):
                    key = (sid, tid, "MANAGES")
                    if key not in seen_semantic:
                        seen_semantic.add(key)
                        module_links.append({
                            "relation": "MANAGES",
                            "source": sid,
                            "target": tid,
                            "confidence": 0.6,
                            "source_file": file_map.get(sid, ""),
                            "target_file": file_map.get(tid, ""),
                        })

print(f"  {len(module_links)} cohesion links")

# ── Step 7: Add business rules as nodes ───────────────────────────────────────
print("\nStep 7: Adding business rule nodes...")

# Generate unique IDs using a deterministic prefix
rule_node_ids = {}
for rule in RULES:
    rule_id = f"rule_{rule['id']}"
    rule["node_id"] = rule_id
    rule_node_ids[rule_id] = True
    enriched_nodes.append({
        "id": rule_id,
        "label": rule["label"],
        "role": "business_rule",
        "domain": rule["domain"],
        "stability": "stable",
        "degree": len(rule["related_nodes"]),
        "lib_path": rule["source"],
        "in_lib": True,
        "source_file": f"cotis_app/lib/{rule['source']}",
        "source_location": None,
        "file_type": "business_rule",
        "norm_label": rule["label"].lower(),
        "community": None,
    })

print(f"  Added {len(RULES)} business rule nodes")

# ── Step 8: Rule-to-code links ────────────────────────────────────────────────
print("\nStep 8: Adding business rule links...")

rule_links = []
for rule in RULES:
    rule_node_id = rule["node_id"]
    for related_id in rule["related_nodes"]:
        rule_links.append({
            "relation": "JUSTIFIES",
            "source": rule_node_id,
            "target": related_id,
            "confidence": 0.95,
            "source_file": rule["source"],
            "target_file": file_map.get(related_id, ""),
        })

print(f"  {len(rule_links)} business rule links added")

# ── Build final graph ──────────────────────────────────────────────────────────
print("\nBuilding final graph...")

all_links = semantic_links + cross_process_links + module_links + rule_links

final_links = []
final_link_set = set()
for link in all_links:
    key = (link["source"], link["target"], link["relation"])
    if key not in final_link_set:
        final_link_set.add(key)
        final_links.append(link)

output_graph = {
    "version": "2.0",
    "created": "2026-09-02",
    "project": "kased-app-new",
    "directed": True,
    "multigraph": False,
    "graph": {},
    "nodes": enriched_nodes,
    "links": final_links,
    "hyperedges": [],
    "metadata": {
        "total_nodes": len(enriched_nodes),
        "total_links": len(final_links),
        "ast_base_nodes": len(ast_nodes),
        "ast_base_edges": len(ast_links),
        "semantic_edges_added": len(semantic_links),
        "cross_process_edges": len(cross_process_links),
        "cohesion_edges": len(module_links),
        "business_rules": len(RULES),
        "rule_links_added": len(rule_links),
        "wiki_modules": len(wiki_node_map),
        "role_distribution": dict(Counter(n["role"] for n in enriched_nodes)),
        "domain_distribution": dict(Counter(n["domain"] for n in enriched_nodes)),
    },
    "semantic_relations": {
        rel: desc for rel, desc in [
            ("DEPENDS_ON", "Import dependency between project files"),
            ("CALLS", "Method/function call between project components"),
            ("USES_PROVIDER", "Screen uses a Riverpod provider"),
            ("USES_LOGIC", "Service uses pure business logic"),
            ("CONTAINS", "Container relationship (class contains method)"),
            ("EXPOSES", "Service exposes a public API method"),
            ("PROVISIONS", "Screen provisions a widget/component"),
            ("MANAGES", "High-level management (screen->provider, module cohesion)"),
            ("ORCHESTRATES", "Controller orchestrates services/models"),
            ("PERSISTS_AS", "Model maps to database entity"),
            ("IMPLEMENTS", "Service implements an interface/contract"),
            ("ENCAPSULATES", "Logic class encapsulates business rules"),
            ("CALLS_API", "Flutter code calls InsForge API endpoint"),
            ("HANDLES_EVENT", "Server function handles a specific event type"),
            ("ROUTES_TO", "Router maps path to screen"),
            ("APPLIES", "Theme applies styles to components"),
            ("TRIGGERS_FUNCTION", "Client code triggers a serverless function"),
            ("CALLS_FUNCTION", "Client code calls a serverless function"),
            ("JUSTIFIES", "Business rule implemented by code"),
        ]
    },
    "business_rules": RULES,
    "wiki_mappings": {mod: {"node_count": len(ids), "node_ids": ids} for mod, ids in wiki_node_map.items()},
}

# ── Write output ───────────────────────────────────────────────────────────────
OUT_DIR.mkdir(parents=True, exist_ok=True)

out_path = OUT_DIR / "extended_graph.json"
with out_path.open("w", encoding="utf-8") as f:
    json.dump(output_graph, f, indent=2, ensure_ascii=False)
print(f"\n[OK] Extended graph: {out_path}")
print(f"  Nodes:   {output_graph['metadata']['total_nodes']}")
print(f"  Links:   {output_graph['metadata']['total_links']}")
print(f"  Rules:   {output_graph['metadata']['business_rules']}")
print(f"  Wiki:    {output_graph['metadata']['wiki_modules']} modules")

# Embeddings
embed_path = OUT_DIR / "graph_embeddings.json"
embed_data = {
    "nodes": [
        {
            "id": n["id"],
            "label": n["label"],
            "role": n["role"],
            "domain": n["domain"],
            "lib_path": n["lib_path"],
            "text_for_embedding": f"{n['label']} ({n['role']}) in {n['lib_path']} domain {n['domain']}",
        }
        for n in enriched_nodes
    ],
    "links": [
        {"source": l["source"], "target": l["target"], "relation": l["relation"]}
        for l in final_links
    ],
    "business_rules": [
        {"id": r["id"], "label": r["label"], "statement": r["statement"], "domain": r["domain"], "source": r["source"]}
        for r in RULES
    ],
}
with embed_path.open("w", encoding="utf-8") as f:
    json.dump(embed_data, f, indent=2, ensure_ascii=False)
print(f"[OK] Embeddings: {embed_path}")

# Query index
query_index = {
    "by_role": {role: [n["id"] for n in enriched_nodes if n["role"] == role] for role in set(n["role"] for n in enriched_nodes)},
    "by_domain": {dom: [n["id"] for n in enriched_nodes if n["domain"] == dom] for dom in set(n["domain"] for n in enriched_nodes)},
    "by_file": {f: ids for f, ids in node_by_file.items()},
    "by_stability": {s: [n["id"] for n in enriched_nodes if n["stability"] == s] for s in {"stable", "moderate", "volatile"}},
    "semantic_edges": [
        {"relation": l["relation"], "source": l["source"], "target": l["target"], "confidence": l["confidence"]}
        for l in final_links
    ],
}
query_path = OUT_DIR / "query_index.json"
with query_path.open("w", encoding="utf-8") as f:
    json.dump(query_index, f, indent=2, ensure_ascii=False)
print(f"[OK] Query index: {query_path}")

# ── Summary ────────────────────────────────────────────────────────────────────
print("\n" + "="*60)
print("SUMMARY")
print("="*60)
m = output_graph["metadata"]
print(f"Total nodes:   {m['total_nodes']} (was {m['ast_base_nodes']})")
print(f"Total links:   {m['total_links']} (was {m['ast_base_edges']})")
print(f"  + Semantic AST: {m['semantic_edges_added']}")
print(f"  + Cross-process: {m['cross_process_edges']}")
print(f"  + Cohesion:      {m['cohesion_edges']}")
print(f"  + Rule links:    {m['rule_links_added']}")
print(f"\nRoles:     {dict(Counter(n['role'] for n in enriched_nodes).most_common())}")
print(f"Domains:   {dict(Counter(n['domain'] for n in enriched_nodes).most_common())}")
print(f"\nBusiness Rules: {len(RULES)}")
for r in RULES:
    print(f"  [{r['domain']}] {r['label']}: {r['statement']}")
print(f"\nWiki Modules: {len(wiki_node_map)}")
for mod, info in wiki_node_map.items():
    print(f"  {mod}: {len(info)} nodes")
