#!/usr/bin/env python3
"""
Add Swift files to the Flipix Xcode project.

Usage: python3 add_swift_file.py <filename> <group>

Groups: Models, Views, ViewModels, Services, Components

Example: python3 add_swift_file.py MyNewView.swift Views
"""

import sys
import os
import re
import random
import string
from datetime import datetime

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_DIR = os.path.dirname(SCRIPT_DIR)
PBXPROJ = os.path.join(PROJECT_DIR, "Flipix/Flipix.xcodeproj/project.pbxproj")

# Group IDs from the project file
GROUP_IDS = {
    "Models": "228C21072ED56D9100F0ACD5",
    "Views": "228C21172ED56D9100F0ACD5",
    "ViewModels": "228C21112ED56D9100F0ACD5",
    "Services": "228C210D2ED56D9100F0ACD5",
    "Components": "228C21142ED56D9100F0ACD5",
}

def generate_id():
    """Generate a unique 24-character hex ID."""
    chars = string.hexdigits.upper()[:16]
    return ''.join(random.choice(chars) for _ in range(24))

def add_file_to_project(filename, group):
    if group not in GROUP_IDS:
        print(f"Error: Unknown group '{group}'")
        print(f"Valid groups: {', '.join(GROUP_IDS.keys())}")
        return False

    # Generate unique IDs
    fileref_id = generate_id()
    buildfile_id = generate_id()

    print(f"Adding {filename} to {group}...")
    print(f"FileRef ID: {fileref_id}")
    print(f"BuildFile ID: {buildfile_id}")

    # Read current project file
    with open(PBXPROJ, 'r') as f:
        content = f.read()

    # Check if file already exists
    if f'path = {filename};' in content:
        print(f"Error: {filename} already exists in project!")
        return False

    # Create backup
    backup_path = PBXPROJ + '.backup'
    with open(backup_path, 'w') as f:
        f.write(content)
    print(f"Backup saved to: {backup_path}")

    # 1. Add PBXFileReference
    fileref_entry = f'\t\t{fileref_id} /* {filename} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {filename}; sourceTree = "<group>"; }};\n'
    content = content.replace(
        '/* End PBXFileReference section */',
        fileref_entry + '/* End PBXFileReference section */'
    )

    # 2. Add PBXBuildFile
    buildfile_entry = f'\t\t{buildfile_id} /* {filename} in Sources */ = {{isa = PBXBuildFile; fileRef = {fileref_id} /* {filename} */; }};\n'
    content = content.replace(
        '/* End PBXBuildFile section */',
        buildfile_entry + '/* End PBXBuildFile section */'
    )

    # 3. Add to group
    group_id = GROUP_IDS[group]
    # Find the group's children list and add the file
    pattern = rf'({group_id} /\* {group} \*/ = \{{\s*isa = PBXGroup;\s*children = \()([^)]*?)(\);)'
    match = re.search(pattern, content)

    if match:
        children = match.group(2).rstrip()
        new_children = children + f'\n\t\t\t\t{fileref_id} /* {filename} */,'
        content = content[:match.start(2)] + new_children + '\n\t\t\t' + content[match.end(2):]

    # 4. Add to Sources build phase
    # Find the sources build phase (look for the one with existing source files)
    sources_pattern = r'(0B1A00271A2A3A4A5A6A7A8A /\* Sources \*/ = \{\s*isa = PBXSourcesBuildPhase;.*?files = \()([^)]*?)(\);)'
    match = re.search(sources_pattern, content, re.DOTALL)

    if match:
        files = match.group(2).rstrip()
        new_files = files + f'\n\t\t\t\t{buildfile_id} /* {filename} in Sources */,'
        content = content[:match.start(2)] + new_files + '\n\t\t\t' + content[match.end(2):]

    # Write updated content
    with open(PBXPROJ, 'w') as f:
        f.write(content)

    print(f"Successfully added {filename} to {group}!")
    return True

def main():
    if len(sys.argv) < 3:
        print(__doc__)
        sys.exit(1)

    filename = sys.argv[1]
    group = sys.argv[2]

    if not filename.endswith('.swift'):
        print("Warning: File doesn't have .swift extension")

    success = add_file_to_project(filename, group)
    sys.exit(0 if success else 1)

if __name__ == '__main__':
    main()
