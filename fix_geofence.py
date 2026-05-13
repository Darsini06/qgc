import re

path = r"c:\Qgcs\qgc\src\PlanView\GeoFenceEditor.qml"

with open(path, "r", encoding="utf-8") as f:
    content = f.read()

# The problematic pattern: contentItem: RowLayout with semicolons separating children
bad_pattern = (
    r'contentItem: RowLayout \{ spacing: 8; '
    r'Item \{ Layout\.fillWidth: true \}; '
    r'QGCColoredImage \{ width: 14; height: 14; source: "/qmlimages/Edit\.svg"; '
    r'color: object\.interactive \? "white" : _colorTextSecondary \}; '
    r'QGCLabel \{ text: qsTr\("Edit Mode"\); '
    r'color: object\.interactive \? "white" : _colorTextSecondary; font\.bold: true \}; '
    r'Item \{ Layout\.fillWidth: true \} \}'
)

# Replacement with proper newline-separated children
# We need to preserve the indentation of the line. Find each match and fix it.
def fix_match(m):
    # Get the leading whitespace from the original line
    start = m.start()
    # Find beginning of the line
    line_start = content.rfind('\n', 0, start) + 1
    indent = ''
    for ch in content[line_start:start]:
        if ch in (' ', '\t'):
            indent += ch
        else:
            break
    inner_indent = indent + '    '
    return (
        "contentItem: RowLayout {\n"
        f"{inner_indent}spacing: 8\n"
        f"{inner_indent}Item {{ Layout.fillWidth: true }}\n"
        f"{inner_indent}QGCColoredImage {{ width: 14; height: 14; source: \"/qmlimages/Edit.svg\"; color: object.interactive ? \"white\" : _colorTextSecondary }}\n"
        f"{inner_indent}QGCLabel {{ text: qsTr(\"Edit Mode\"); color: object.interactive ? \"white\" : _colorTextSecondary; font.bold: true }}\n"
        f"{inner_indent}Item {{ Layout.fillWidth: true }}\n"
        f"{indent}}}"
    )

new_content = re.sub(bad_pattern, fix_match, content)

fixed = content.count('spacing: 8; Item { Layout.fillWidth: true }; QGCColoredImage')
print(f"Found {fixed} occurrences to fix")

with open(path, "w", encoding="utf-8") as f:
    f.write(new_content)

print("Done! GeoFenceEditor.qml fixed.")
