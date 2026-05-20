#!/usr/bin/env python3
"""
Export GraphRAG output to JSON format for Axiom-Scaffold
Converts Parquet files to a unified JSON graph structure
"""

import json
import os
from pathlib import Path
from datetime import datetime

try:
    import pandas as pd
except ImportError:
    print("❌ pandas n'est pas installé")
    print("   Installation : pip install pandas pyarrow")
    exit(1)


def load_parquet_safe(filepath):
    """Load a parquet file safely, return empty DataFrame if not found"""
    try:
        if os.path.exists(filepath):
            return pd.read_parquet(filepath)
        else:
            return pd.DataFrame()
    except Exception as e:
        print(f"⚠️  Erreur lors du chargement de {filepath}: {e}")
        return pd.DataFrame()


def export_graphrag_to_json():
    """Export GraphRAG output to JSON format"""
    
    print("📤 Export GraphRAG vers JSON...")
    
    base_dir = Path("graphrag_data/output")
    output_file = Path("graph/doc-graph.json")
    
    # Load entities
    entities_df = load_parquet_safe(base_dir / "create_final_entities.parquet")
    
    # Load relationships
    relationships_df = load_parquet_safe(base_dir / "create_final_relationships.parquet")
    
    # Load communities
    communities_df = load_parquet_safe(base_dir / "create_final_communities.parquet")
    
    # Load community reports (summaries)
    reports_df = load_parquet_safe(base_dir / "create_final_community_reports.parquet")
    
    # Build entities list
    entities = []
    if not entities_df.empty:
        for _, row in entities_df.iterrows():
            entity = {
                "id": str(row.get("id", row.get("name", "unknown"))),
                "name": str(row.get("name", row.get("title", ""))),
                "type": str(row.get("type", "unknown")),
                "description": str(row.get("description", "")),
                "degree": int(row.get("degree", 0)) if "degree" in row else 0,
                "community": str(row.get("community", "")) if "community" in row else None,
            }
            
            # Add source documents if available
            if "source_id" in row:
                entity["documents"] = [str(row["source_id"])]
            
            entities.append(entity)
    
    # Build relations list
    relations = []
    if not relationships_df.empty:
        for _, row in relationships_df.iterrows():
            relation = {
                "source": str(row.get("source", "")),
                "target": str(row.get("target", "")),
                "type": str(row.get("type", "RELATED_TO")),
                "description": str(row.get("description", "")),
                "weight": float(row.get("weight", 1.0)) if "weight" in row else 1.0,
            }
            relations.append(relation)
    
    # Build communities list
    communities = []
    if not communities_df.empty:
        for _, row in communities_df.iterrows():
            community = {
                "id": str(row.get("id", row.get("community", ""))),
                "title": str(row.get("title", f"Community {row.get('id', '')}")),
                "level": int(row.get("level", 0)) if "level" in row else 0,
                "size": int(row.get("size", 0)) if "size" in row else 0,
            }
            
            # Add summary from reports if available
            if not reports_df.empty:
                report = reports_df[reports_df["community"] == row.get("id", row.get("community", ""))]
                if not report.empty:
                    community["summary"] = str(report.iloc[0].get("summary", ""))
                    community["findings"] = str(report.iloc[0].get("findings", ""))
            
            communities.append(community)
    
    # Build final graph structure
    graph = {
        "entities": entities,
        "relations": relations,
        "communities": communities,
        "metadata": {
            "source": "graphrag",
            "timestamp": datetime.now().isoformat(),
            "entity_count": len(entities),
            "relation_count": len(relations),
            "community_count": len(communities),
        }
    }
    
    # Save to JSON
    output_file.parent.mkdir(parents=True, exist_ok=True)
    with open(output_file, "w", encoding="utf-8") as f:
        json.dump(graph, f, indent=2, ensure_ascii=False)
    
    print(f"✅ Graphe exporté : {output_file}")
    print(f"   • {len(entities)} entités")
    print(f"   • {len(relations)} relations")
    print(f"   • {len(communities)} communautés")
    
    return graph


if __name__ == "__main__":
    try:
        export_graphrag_to_json()
    except Exception as e:
        print(f"❌ Erreur lors de l'export : {e}")
        import traceback
        traceback.print_exc()
        exit(1)
