import re
import glob
import sys
import os

class File:
    def __init__(self, path=None, name=None, instantiations=None):
        self.path = path
        self.name = name
        self.instantiations = instantiations if instantiations is not None else []

    def has_dependency(self, entity):
        return entity.name in self.instantiations

class Entity(File):
    def __init__(self, path, name, instantiations):
        super().__init__(path, name, instantiations)

class Package(File):
    def __init__(self, path, name, instantiations):
        super().__init__(path, name, instantiations)

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

def get_compile_order(src_path, tb_name):
    all_files = []
    for path in glob.glob(src_path + "**/*.vhd", recursive=True):
        with open(path, "r") as f:
            content = f.read()
            if get_package_name(content):
                all_files.append(Package(path, get_package_name(content), get_package_insts(content)))
            elif get_entity_name(content):
                all_files.append(Entity(path, get_entity_name(content), get_entity_insts(content) + get_package_insts(content)))

    compile_order = []
    while all_files:
        for file in all_files:
            if not any([file.has_dependency(entity) for entity in all_files]):
                if any([file.name in entity.instantiations for entity in all_files]) or file.name == tb_name:
                    compile_order.append(file)
                all_files.remove(file)

    return compile_order


if __name__ == "__main__":
    src_path = os.path.join(sys.argv[1], "")
    tb_name = sys.argv[2]

    compile_order = get_compile_order(src_path, tb_name)

    print("\n".join([os.path.normpath(file.path).replace("\\", "/") for file in compile_order]))
