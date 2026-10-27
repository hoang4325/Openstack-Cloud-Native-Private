#!/usr/bin/env python3

import json
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
TF_DIR = REPO_ROOT / "terraform/environments/lab/k8s-cluster"


def main():
    command = [
        "terraform",
        f"-chdir={TF_DIR}",
        "output",
        "-json",
        "nodes",
    ]

    try:
        result = subprocess.run(
            command,
            check=True,
            capture_output=True,
            text=True,
        )
        nodes = json.loads(result.stdout)
    except (subprocess.CalledProcessError, json.JSONDecodeError) as exc:
        print(
            f"Cannot read Terraform output from {TF_DIR}: {exc}",
            file=sys.stderr,
        )
        sys.exit(1)

    inventory = {
        "_meta": {"hostvars": {}},
        "k8s_control": {"hosts": []},
        "k8s_workers": {"hosts": []},
        "k8s_cluster": {
            "children": ["k8s_control", "k8s_workers"]
        },
    }

    for name, node in nodes.items():
        floating_ip = node.get("floating_ip")
        fixed_ip = node.get("fixed_ip")
        role = node.get("role")

        if not floating_ip or not fixed_ip:
            raise ValueError(
                f"{name}: missing floating_ip or fixed_ip"
            )

        if role not in ("control", "worker"):
            raise ValueError(
                f"{name}: unsupported role {role!r}"
            )

        inventory["_meta"]["hostvars"][name] = {
            "ansible_host": floating_ip,
            "node_ip": fixed_ip,
            "k8s_role": role,
        }

        if role == "control":
            inventory["k8s_control"]["hosts"].append(name)
        else:
            inventory["k8s_workers"]["hosts"].append(name)

    if len(inventory["k8s_control"]["hosts"]) != 1:
        raise ValueError(
            "Expected exactly one control-plane node"
        )

    print(json.dumps(inventory, indent=2))


if __name__ == "__main__":
    main()
