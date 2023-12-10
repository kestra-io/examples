import csv
import os
import argparse
from ruamel.yaml import YAML, scalarstring


def main(blueprints_csv_path: str) -> None:
    # Ensure the 'blueprints' directory exists
    os.makedirs("blueprints", exist_ok=True)

    yaml = YAML()
    yaml.indent(mapping=2, sequence=4, offset=2)
    yaml.default_flow_style = False
    yaml.preserve_quotes = True

    with open(blueprints_csv_path, "r") as csvfile:
        csvreader = csv.DictReader(csvfile)

        for row in csvreader:
            id_ = row["id"]
            flow_code = row["flow"]

            # Extract the file name
            file_name_part = ""
            for line in flow_code.split("\n"):
                if line.startswith("id: "):
                    file_name_part = line.split("id: ")[1]
                    break

            if file_name_part:
                file_name = id_ + "_" + file_name_part + ".yml"
            else:
                # Fallback file name if 'id: ' is not found
                file_name = id_ + "_blueprint.yml"

            path = os.path.join("blueprints", file_name)

            # Convert the string to a Python object
            flow_code_dict = yaml.load(flow_code)

            # Ensure multiline strings are handled correctly
            def convert_to_literal_string(obj):
                if isinstance(obj, dict):
                    for key, value in obj.items():
                        obj[key] = convert_to_literal_string(value)
                elif isinstance(obj, list):
                    return [convert_to_literal_string(item) for item in obj]
                elif isinstance(obj, str) and "\n" in obj:
                    return scalarstring.LiteralScalarString(obj)
                return obj

            flow_code_dict = convert_to_literal_string(flow_code_dict)

            with open(path, "w") as file:
                yaml.dump(flow_code_dict, file)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Take the CSV file path and iterate over the rows"
    )
    parser.add_argument("blueprints_csv_path", type=str, help="Path to the CSV file")
    args = parser.parse_args()
    main(args.blueprints_csv_path)
