
import sys

with open('brace_check_log.txt', 'w') as log:
    log.write("Starting check...\n")
    file_path = r'c:\Users\admin\Desktop\trae\DeskCare\assets\qml\ScheduleListWindow.qml'
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            lines = f.readlines()
        
        open_braces = 0
        close_braces = 0
        stack = []
        
        for i, line in enumerate(lines):
            for char in line:
                if char == '{':
                    open_braces += 1
                    stack.append(i + 1)
                elif char == '}':
                    close_braces += 1
                    if stack:
                        stack.pop()
                    else:
                        log.write(f"Extra closing brace at line {i + 1}\n")
        
        log.write(f"Total Open: {open_braces}\n")
        log.write(f"Total Close: {close_braces}\n")
        if stack:
            log.write(f"Unclosed braces at lines: {stack[-5:]}\n")
        else:
            log.write("Braces are balanced.\n")
    except Exception as e:
        log.write(f"Error: {e}\n")
