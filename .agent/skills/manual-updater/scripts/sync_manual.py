import os

def scan_folder(folder_path):
    items = []
    if os.path.exists(folder_path):
        for entry in os.listdir(folder_path):
            if os.path.isdir(os.path.join(folder_path, entry)):
                items.append((entry, "folder"))
            elif entry.endswith('.md'):
                items.append((entry.replace('.md', ''), "file"))
    return items

def main():
    # Asumimos que o cwd será a raiz (PROJETO DE CICLO)
    base_dir = os.path.join(os.getcwd(), '.agent')
    manual_path = os.path.join(os.getcwd(), 'Documantation', 'dot-agents-manual.md')
    
    content = ""
    if os.path.exists(manual_path):
        with open(manual_path, 'r', encoding='utf-8') as f:
            content = f.read()

    folders_to_scan = {
        'agents': os.path.join(base_dir, 'agents'),
        'skills': os.path.join(base_dir, 'skills'),
        'workflows': os.path.join(base_dir, 'workflows')
    }

    print("=== Relatório de Sincronização: dot-agents-manual ===\n")

    all_found_names = []
    for cat_name, folder_path in folders_to_scan.items():
        print(f"--- Categoria: {cat_name.upper()} ---")
        items = scan_folder(folder_path)
        for item_name, item_type in items:
            # skills usually reside inside a folder with SKILL.md
            if cat_name == 'skills' and item_type == 'folder':
                skill_md_path = os.path.join(folder_path, item_name, 'SKILL.md')
                if not os.path.exists(skill_md_path):
                    continue # Skip invalid skill folders without SKILL.md
            elif cat_name == 'skills' and item_type == 'file':
                continue # Ignore files directly in .agent/skills/ unless they are skill folders
            
            all_found_names.append(item_name)
            
            # Simple substring checking first (assuming the exact name acts as an ID in the manual)
            if item_name not in content:
                print(f"[FALTA NO MANUAL] {cat_name} -> {item_name} (Precisa ser documentado)")
        print()

    print("--- Verificação Reversa (Itens no Manual que não existem mais no sistema) ---")
    print("ALL SYSTEM ITEMS: " + ", ".join(all_found_names))
    print("\n[!] INSTRUÇÃO AO AGENTE:")
    print("Leia o ./Documantation/dot-agents-manual.md. Se existir alguma ferramenta/skill documentada lá que NÃO está na lista 'ALL SYSTEM ITEMS' acima, APAGUE-A do manual, pois foi removida do sistema.")

if __name__ == "__main__":
    main()
