"""
Query the extended graph for specific questions.
Usage: python3 graphify-out/query_graph.py <query>
"""

import json
import sys
from pathlib import Path

GRAPH_PATH = Path("graphify-out/extended_graph.json")

def load_graph():
    with GRAPH_PATH.open() as f:
        return json.load(f)

def query_nodes(graph, domain=None, role=None, stability=None, keyword=None):
    """Filter nodes by criteria."""
    nodes = graph["nodes"]
    results = []
    for n in nodes:
        if domain and n.get("domain") != domain:
            continue
        if role and n.get("role") != role:
            continue
        if stability and n.get("stability") != stability:
            continue
        if keyword and keyword.lower() not in n.get("label", "").lower() and keyword.lower() not in n.get("lib_path", "").lower():
            continue
        results.append(n)
    return results

def query_edges(graph, relation=None, source_domain=None, target_domain=None):
    """Filter edges by criteria."""
    nodes_by_id = {n["id"]: n for n in graph["nodes"]}
    edges = graph["links"]
    results = []
    for e in edges:
        if relation and e.get("relation") != relation:
            continue
        src = nodes_by_id.get(e["source"], {})
        tgt = nodes_by_id.get(e["target"], {})
        if source_domain and src.get("domain") != source_domain:
            continue
        if target_domain and tgt.get("domain") != target_domain:
            continue
        results.append({
            "relation": e["relation"],
            "source": e["source"],
            "target": e["target"],
            "source_label": src.get("label", "?"),
            "target_label": tgt.get("label", "?"),
            "source_file": src.get("lib_path", ""),
            "target_file": tgt.get("lib_path", ""),
            "confidence": e.get("confidence", 0),
        })
    return results

def find_dependencies(graph, node_id, depth=1):
    """Find all nodes that a given node depends on."""
    nodes_by_id = {n["id"]: n for n in graph["nodes"]}
    visited = set()
    queue = [(node_id, 0)]
    results = []
    while queue:
        nid, d = queue.pop(0)
        if d > depth or nid in visited:
            continue
        visited.add(nid)
        node = nodes_by_id.get(nid)
        if node:
            results.append(node)
        for e in graph["links"]:
            if e["source"] == nid and e["relation"] == "DEPENDS_ON":
                queue.append((e["target"], d + 1))
    return results, visited

def find_dependents(graph, node_id, depth=1):
    """Find all nodes that depend on a given node."""
    nodes_by_id = {n["id"]: n for n in graph["nodes"]}
    visited = set()
    queue = [(node_id, 0)]
    results = []
    while queue:
        nid, d = queue.pop(0)
        if d > depth or nid in visited:
            continue
        visited.add(nid)
        node = nodes_by_id.get(nid)
        if node:
            results.append(node)
        for e in graph["links"]:
            if e["target"] == nid and e["relation"] == "DEPENDS_ON":
                queue.append((e["source"], d + 1))
    return results, visited

def main():
    if len(sys.argv) < 2:
        print("Usage: python3 query_graph.py <query>")
        print("Queries:")
        print("  domain <name>           - List nodes in a domain")
        print("  role <name>             - List nodes by role")
        print("  unstable                - List volatile/moderate nodes")
        print("  rule                    - List all business rules")
        print("  wiki                    - List wiki module mappings")
        print("  edges <relation>        - List edges by type")
        print("  cross-process           - List cross-process links")
        print("  depends <node_id>       - Find dependencies")
        print("  dependents <node_id>    - Find dependents")
        print("  search <keyword>        - Search nodes by keyword")
        return

    graph = load_graph()
    cmd = sys.argv[1]

    if cmd == "domain" and len(sys.argv) > 2:
        domain = sys.argv[2]
        nodes = query_nodes(graph, domain=domain)
        print(f"Domain '{domain}': {len(nodes)} nodes")
        for n in nodes:
            print(f"  [{n['role']}] {n['label']} ({n['lib_path']})")

    elif cmd == "role" and len(sys.argv) > 2:
        role = sys.argv[2]
        nodes = query_nodes(graph, role=role)
        print(f"Role '{role}': {len(nodes)} nodes")
        for n in nodes:
            print(f"  {n['label']} ({n['lib_path']})")

    elif cmd == "unstable":
        nodes = [n for n in graph["nodes"] if n.get("stability") in ("volatile", "moderate")]
        print(f"Unstable nodes: {len(nodes)}")
        for n in sorted(nodes, key=lambda x: -x.get("degree", 0)):
            print(f"  [{n['stability']}] {n['label']} (degree={n.get('degree',0)}, domain={n.get('domain')})")

    elif cmd == "rule":
        print("Business Rules:")
        for r in graph["business_rules"]:
            print(f"  [{r['domain']}] {r['label']}: {r['statement']}")
            print(f"    Source: {r['source']} | Related nodes: {len(r['related_nodes'])}")

    elif cmd == "wiki":
        print("Wiki Module Mappings:")
        for mod, info in graph["wiki_mappings"].items():
            print(f"  {mod}: {info['node_count']} nodes")

    elif cmd == "edges" and len(sys.argv) > 2:
        rel = sys.argv[2]
        edges = query_edges(graph, relation=rel)
        print(f"Edges of type '{rel}': {len(edges)}")
        for e in edges[:20]:
            print(f"  {e['source_label']} --[{e['relation']}]--> {e['target_label']}")
        if len(edges) > 20:
            print(f"  ... and {len(edges)-20} more")

    elif cmd == "cross-process":
        nodes_by_id = {n["id"]: n for n in graph["nodes"]}
        edges = [e for e in graph["links"] if e["relation"] in ("TRIGGERS_FUNCTION", "CALLS_FUNCTION")]
        print(f"Cross-process links: {len(edges)}")
        from collections import Counter
        types = Counter(e["relation"] for e in edges)
        for t, c in types.most_common():
            print(f"  {t}: {c}")
        for e in edges[:10]:
            src = nodes_by_id.get(e["source"], {})
            tgt = nodes_by_id.get(e["target"], {})
            print(f"  {src.get('label','?')} --[{e['relation']}]--> {tgt.get('label','?')}")

    elif cmd == "search" and len(sys.argv) > 2:
        keyword = sys.argv[2]
        nodes = query_nodes(graph, keyword=keyword)
        print(f"Search '{keyword}': {len(nodes)} nodes")
        for n in nodes:
            print(f"  [{n['role']}] {n['label']} ({n['lib_path']})")

    elif cmd == "depends" and len(sys.argv) > 3:
        node_id = sys.argv[2]
        depth = int(sys.argv[3]) if len(sys.argv) > 3 else 1
        nodes, visited = find_dependencies(graph, node_id, depth)
        print(f"Dependencies of '{node_id}' (depth={depth}): {len(nodes)} nodes")
        for n in nodes:
            print(f"  {n['label']} ({n['lib_path']})")

    elif cmd == "dependents" and len(sys.argv) > 3:
        node_id = sys.argv[2]
        depth = int(sys.argv[3]) if len(sys.argv) > 3 else 1
        nodes, visited = find_dependents(graph, node_id, depth)
        print(f"Dependents of '{node_id}' (depth={depth}): {len(nodes)} nodes")
        for n in nodes:
            print(f"  {n['label']} ({n['lib_path']})")

    else:
        print("Unknown query. Use --help for options.")

if __name__ == "__main__":
    main()
