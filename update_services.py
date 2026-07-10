import os
import re

services = ['workflow_service.dart', 'document_service.dart', 'plugin_service.dart', 'browser_service.dart', 'analytics_service.dart', 'approval_service.dart', 'cognitive_state_service.dart', 'life_timeline_service.dart', 'attention_service.dart', 'circuit_breaker_service.dart']

for svc in services:
    path = os.path.join('lib', 'services', svc)
    if not os.path.exists(path): continue
    
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    if "import 'package:flutter/foundation.dart';" not in content and "import 'package:flutter/material.dart';" not in content:
        content = "import 'package:flutter/foundation.dart';\n" + content

    match = re.search(r'class\s+(\w+)(?:\s+extends\s+\w+)?\s*\{', content)
    if match:
        class_name = match.group(1)
        
        if re.search(r'' + class_name + r'\([^)]*\)\s*\{', content):
            if " constructor START');" not in content:
                content = re.sub(
                    r'(' + class_name + r'\([^)]*\)\s*\{)',
                    r"\1\n    debugPrint('" + class_name + r" constructor START');",
                    content,
                    count=1
                )
        else:
            if 'extends ChangeNotifier' in content:
                content = content.replace('class ' + class_name + ' extends ChangeNotifier {', 'class ' + class_name + ' extends ChangeNotifier {\n  ' + class_name + '() {\n    debugPrint(\'' + class_name + ' constructor START\');\n    debugPrint(\'' + class_name + ' constructor END\');\n  }')
            else:
                content = content.replace('class ' + class_name + ' {', 'class ' + class_name + ' {\n  ' + class_name + '() {\n    debugPrint(\'' + class_name + ' constructor START\');\n    debugPrint(\'' + class_name + ' constructor END\');\n  }')
    
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
