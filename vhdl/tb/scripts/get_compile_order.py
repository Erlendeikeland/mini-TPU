import re
import glob
import os
import argparse

class File:
    def __init__(self, path=None, name=None, instantiations=None):
        self.path = path
        self.name = name
        self.instantiations = instantiations if instantiations is not None else []

    def has_dependency(self, name):
        return name in self.instantiations

def get_package_name(content):
    match = re.search(r"^\s*package\s+(\w+)\s+is\b", content, re.MULTILINE)
    return match.group(1) if match else None

def get_entity_name(content):
    match = re.search(r"^\s*entity\s+(\w+)\s+is\b", content, re.MULTILINE)
    return match.group(1) if match else None

def get_entity_insts(content):
    entities = re.findall(r"^\s*(\w+)\s*:\s*entity\s*work\.(\w+)", content, re.MULTILINE)
    return [entity[1] for entity in entities]

def get_package_insts(content):
    packages = re.findall(r"^\s*use\s+work\.(\w+)\.all", content, re.MULTILINE)
    return packages

def get_compile_order(src_path, top_level_name):
    src_path = os.path.join(os.path.abspath(src_path), "")

    top_level_file = None
    all_files = []
    for path in glob.glob(src_path + "**/*.vhd", recursive=True):
        with open(path, "r") as f:
            content = f.read()
            if get_package_name(content):
                all_files.append(File(path, get_package_name(content), get_package_insts(content)))
            elif get_entity_name(content):
                if get_entity_name(content) == top_level_name:
                    top_level_file = File(path, get_entity_name(content), get_entity_insts(content) + get_package_insts(content))
                else:
                    all_files.append(File(path, get_entity_name(content), get_entity_insts(content) + get_package_insts(content)))

    compile_order = recursive_search(top_level_file, all_files)

    return compile_order
    
def recursive_search(file, all_files, visited=None):
    if visited is None:
        visited = set()

    compile_order = []
    
    if file.name in visited:
        return compile_order

    visited.add(file.name)

    for inst in file.instantiations:
        inst_file = next((f for f in all_files if f.name == inst), None)
        if inst_file:
            compile_order += recursive_search(inst_file, all_files, visited)
    
    compile_order.append(file)

    return compile_order

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Get compile order of VHDL files")
    parser.add_argument("src_path", type=str, help="Path to VHDL files")
    parser.add_argument("top_level_name", type=str, help="Name of the top-level file")
    args = parser.parse_args()

    compile_order = get_compile_order(args.src_path, args.top_level_name)

    print("\n".join([file.path for file in compile_order]))
    