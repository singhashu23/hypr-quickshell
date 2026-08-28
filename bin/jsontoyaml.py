import json
from ruamel.yaml import YAML

in_file = "/home/ashu/.cache/wal/colors.json"
out_file = "/home/ashu/.cache/wal/colors.yaml"

yaml = YAML(typ="safe")
yaml.default_flow_style = False

with open(in_file, "r") as i:
    data = json.load(i)

with open(out_file, "w") as o:
    yaml.dump(data, o)


