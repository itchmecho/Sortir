#!/bin/bash

# Script to add Swift files to Sortir Xcode project
# Usage: ./add_file_to_xcode.sh <filename.swift> <group> [fileref_id] [buildfile_id]
# Groups: Models, Views, ViewModels, Services, Components
#
# Example: ./add_file_to_xcode.sh MyNewView.swift Views

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR/.."
PBXPROJ="$PROJECT_DIR/Sortir/Sortir.xcodeproj/project.pbxproj"

if [ $# -lt 2 ]; then
    echo "Usage: $0 <filename.swift> <group>"
    echo "Groups: Models, Views, ViewModels, Services, Components"
    exit 1
fi

FILENAME="$1"
GROUP="$2"

# Generate unique IDs (or use provided ones)
TIMESTAMP=$(date +%s)
FILEREF_ID="${3:-AA$(printf '%012X' $TIMESTAMP)11}"
BUILDFILE_ID="${4:-AA$(printf '%012X' $TIMESTAMP)01}"

echo "Adding $FILENAME to $GROUP group..."
echo "FileRef ID: $FILEREF_ID"
echo "BuildFile ID: $BUILDFILE_ID"

# Map group to parent ID (these are the group IDs from the project)
case "$GROUP" in
    "Models")
        GROUP_ID="228C21072ED56D9100F0ACD5"
        ;;
    "Views")
        GROUP_ID="228C21172ED56D9100F0ACD5"
        ;;
    "ViewModels")
        GROUP_ID="228C21112ED56D9100F0ACD5"
        ;;
    "Services")
        GROUP_ID="228C210D2ED56D9100F0ACD5"
        ;;
    "Components")
        GROUP_ID="228C21142ED56D9100F0ACD5"
        ;;
    *)
        echo "Unknown group: $GROUP"
        echo "Valid groups: Models, Views, ViewModels, Services, Components"
        exit 1
        ;;
esac

# Check if file already exists in project
if grep -q "path = $FILENAME;" "$PBXPROJ"; then
    echo "File $FILENAME already exists in project!"
    exit 1
fi

# Create backup
cp "$PBXPROJ" "$PBXPROJ.backup"

# Add PBXFileReference
sed -i '' "/\/* End PBXFileReference section \*\//i\\
\\		$FILEREF_ID /* $FILENAME */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = $FILENAME; sourceTree = \"<group>\"; };
" "$PBXPROJ"

# Add PBXBuildFile
sed -i '' "/\/* End PBXBuildFile section \*\//i\\
\\		$BUILDFILE_ID /* $FILENAME in Sources */ = {isa = PBXBuildFile; fileRef = $FILEREF_ID /* $FILENAME */; };
" "$PBXPROJ"

# Add to group - find the group and add the file reference
# This is tricky with sed, so we use a more targeted approach
python3 << EOF
import re

with open("$PBXPROJ", 'r') as f:
    content = f.read()

# Find the group and add the file
group_pattern = r'($GROUP_ID /\* $GROUP \*/ = \{\s*isa = PBXGroup;\s*children = \()([^)]*?)(\);)'
match = re.search(group_pattern, content)

if match:
    before = match.group(1)
    children = match.group(2)
    after = match.group(3)

    # Add the new file reference
    new_children = children.rstrip() + '\n\t\t\t\t$FILEREF_ID /* $FILENAME */,'
    content = content[:match.start()] + before + new_children + '\n\t\t\t' + after + content[match.end():]

# Add to Sources build phase
sources_pattern = r'(/\* Begin PBXSourcesBuildPhase section \*/.*?files = \()([^)]*?)(\);)'
match = re.search(sources_pattern, content, re.DOTALL)

if match:
    before = match.group(1)
    files = match.group(2)
    after = match.group(3)

    new_files = files.rstrip() + '\n\t\t\t\t$BUILDFILE_ID /* $FILENAME in Sources */,'
    content = content[:match.start()] + before + new_files + '\n\t\t\t' + after + content[match.end():]

with open("$PBXPROJ", 'w') as f:
    f.write(content)

print("Successfully added $FILENAME to $GROUP!")
EOF

echo "Done! File added to project."
echo "Backup saved at: $PBXPROJ.backup"
