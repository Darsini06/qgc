import codecs

file_path = "d:/QT/QGC/src/FlightMap/Widgets/PhotoVideoControl.qml"

with codecs.open(file_path, 'r', 'utf-8') as f:
    text = f.read()

# Replace row heights
text = text.replace("height: 50", "height: 60")

# Replace margins
text = text.replace("anchors.fill: parent; anchors.margins: 15", "anchors.fill: parent; anchors.leftMargin: 20; anchors.rightMargin: 20")

# Make sure buttons and combo boxes look aligned to the right by ensuring QGCLabel fills width and vertically centers
with codecs.open(file_path, 'w', 'utf-8') as f:
    f.write(text)

print("SUCCESS")
