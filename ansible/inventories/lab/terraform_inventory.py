#!/usr/bin/env python3
"""Inventory JSON từ Terraform output nodes. Không thực hiện apply/refresh."""
import argparse
import ipaddress
import json
import os
import re
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[3]
DEFAULT_TF_DIR = REPO_ROOT / "terraform/environments/lab/k8s-cluster"
HOST_PATTERN = re.compile(r"^[A-Za-z0-9][A-Za-z0-9_.-]*$")


def terraform_nodes(tf_dir: Path) -> dict:
    if not tf_dir.is_dir():
        raise ValueError(f"Missing Terraform directory: {tf_dir}")
    try:
        result = subprocess.run(
            ["terraform", f"-chdir={tf_dir}", "output", "-json", "nodes"],
            capture_output=True, text=True, timeout=20, check=True,
        )
        nodes = json.loads(result.stdout)
    except FileNotFoundError as exc:
        raise RuntimeError("Terraform executable not found in PATH") from exc
    except subprocess.TimeoutExpired as exc:
        raise RuntimeError("Timed out while reading Terraform outputs") from exc
    except subprocess.CalledProcessError as exc:
        raise RuntimeError("Cannot read Terraform output 'nodes'; verify local state") from exc
    except json.JSONDecodeError as exc:
        raise RuntimeError("Terraform output 'nodes' is not valid JSON") from exc
    if not isinstance(nodes, dict):
        raise ValueError("Terraform output 'nodes' must be a JSON object")
    return nodes


def build_inventory(nodes: dict) -> dict:
    inventory = {
        "_meta": {"hostvars": {}},
        "k8s_control": {"hosts": []},
        "k8s_workers": {"hosts": []},
        "k8s_cluster": {"children": ["k8s_control", "k8s_workers"]},
    }
    ips = set()
    for name, node in sorted(nodes.items()):
        if not isinstance(name, str) or not HOST_PATTERN.fullmatch(name):
            raise ValueError(f"Invalid host name: {name!r}")
        if not isinstance(node, dict):
            raise ValueError(f"{name}: invalid node mapping")
        role, fixed, floating = node.get("role"), node.get("fixed_ip"), node.get("floating_ip")
        if role not in {"control", "worker"}:
            raise ValueError(f"{name}: unsupported role {role!r}")
        if not isinstance(fixed, str):
            raise ValueError(f"{name}: missing fixed_ip")
        ipaddress.IPv4Address(fixed)
        if fixed in ips:
            raise ValueError(f"Duplicate fixed IP: {fixed}")
        ips.add(fixed)
        if floating is not None:
            ipaddress.IPv4Address(floating)
        # Không có FIP: dùng fixed IP (chỉ hoạt động nếu máy Ansible có route).
        inventory["_meta"]["hostvars"][name] = {
            "ansible_host": floating or fixed,
            "node_ip": fixed,
            "k8s_role": role,
        }
        group = "k8s_control" if role == "control" else "k8s_workers"
        inventory[group]["hosts"].append(name)
    if len(inventory["k8s_control"]["hosts"]) != 1:
        raise ValueError("Lab requires exactly one control-plane node")
    return inventory


def main():
    parser = argparse.ArgumentParser(description="Terraform-backed Ansible inventory")
    modes = parser.add_mutually_exclusive_group(required=True)
    modes.add_argument("--list", action="store_true")
    modes.add_argument("--host", metavar="NAME")
    args = parser.parse_args()
    try:
        tf_dir = Path(os.environ.get("ANSIBLE_TF_DIR", str(DEFAULT_TF_DIR))).expanduser().resolve()
        inventory = build_inventory(terraform_nodes(tf_dir))
        output = (inventory["_meta"]["hostvars"].get(args.host, {})
                  if args.host else inventory)
        print(json.dumps(output, indent=2))
    except (ValueError, RuntimeError, OSError) as exc:
        print(f"[terraform-inventory] {exc}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
