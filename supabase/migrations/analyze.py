import os
import re

MIGRATIONS_DIR = "/home/semo/projects/sayr/supabase/migrations"

sql_files = sorted([f for f in os.listdir(MIGRATIONS_DIR) if f.endswith('.sql')])

tables = set()
rls_enabled_tables = set()

functions = {}

create_table_pattern = re.compile(r'create\s+table\s+(?:if\s+not\s+exists\s+)?(?:public\.)?([a-zA-Z0-9_]+)', re.IGNORECASE)
alter_table_rls_pattern = re.compile(r'alter\s+table\s+(?:public\.)?([a-zA-Z0-9_]+)\s+enable\s+row\s+level\s+security', re.IGNORECASE)

create_function_pattern = re.compile(r'create\s+(?:or\s+replace\s+)?function\s+(?:public\.)?([a-zA-Z0-9_]+)\s*\(', re.IGNORECASE)
set_search_path_pattern = re.compile(r'set\s+search_path\s*=\s*(?:\'\'|public)', re.IGNORECASE)

for file in sql_files:
    path = os.path.join(MIGRATIONS_DIR, file)
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
        
        # Find tables
        for match in create_table_pattern.finditer(content):
            tables.add(match.group(1).lower())
            
        # Find RLS
        for match in alter_table_rls_pattern.finditer(content):
            rls_enabled_tables.add(match.group(1).lower())
            
        # Find functions
        # This is a bit tricky because function definitions can span multiple lines
        # Let's just do a rough check by finding "CREATE FUNCTION foo" and checking the next 1000 chars
        for match in create_function_pattern.finditer(content):
            func_name = match.group(1).lower()
            start_idx = match.start()
            # find end of function or just grab next 2000 chars
            snippet = content[start_idx:start_idx+2000]
            
            has_search_path = bool(set_search_path_pattern.search(snippet))
            
            # Check for revoke
            revoke_pattern = re.compile(r'revoke\s+execute\s+on\s+function\s+(?:public\.)?' + re.escape(func_name) + r'\s*\(.*?\)\s+from\s+public', re.IGNORECASE)
            has_revoke = bool(revoke_pattern.search(content))
            
            # We might have multiple definitions (overloads or replacements)
            # So we keep track of the latest one or if ANY of them misses it
            if func_name not in functions:
                functions[func_name] = {'search_path': False, 'revoke': False}
            
            if has_search_path:
                functions[func_name]['search_path'] = True
            if has_revoke:
                functions[func_name]['revoke'] = True

print("Tables without RLS:")
for t in sorted(tables - rls_enabled_tables):
    print(t)

print("\nFunctions without search_path:")
for f, data in functions.items():
    if not data['search_path']:
        print(f)

print("\nFunctions without revoke:")
for f, data in functions.items():
    if not data['revoke']:
        print(f)

