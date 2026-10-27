import importlib.util
import json
import unittest
from unittest import mock
import subprocess
from pathlib import Path

BASE = Path(__file__).resolve().parents[1]
SCRIPT = BASE / "inventories/lab/terraform_inventory.py"
spec = importlib.util.spec_from_file_location("terraform_inventory", SCRIPT)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class TestTerraformInventory(unittest.TestCase):
    def setUp(self):
        self.nodes = json.loads((BASE / "tests/fixtures/nodes.json").read_text())

    def test_groups_and_ips(self):
        inv = module.build_inventory(self.nodes)
        self.assertEqual(inv["k8s_control"]["hosts"], ["k8s-control-01"])
        self.assertEqual(len(inv["k8s_workers"]["hosts"]), 2)
        self.assertEqual(inv["_meta"]["hostvars"]["k8s-monitoring-01"]["ansible_host"], "10.20.0.12")

    def test_invalid_role(self):
        self.nodes["k8s-worker-01"]["role"] = "database"
        with self.assertRaisesRegex(ValueError, "unsupported role"):
            module.build_inventory(self.nodes)

    def test_duplicate_ip(self):
        self.nodes["k8s-worker-01"]["fixed_ip"] = "10.20.0.10"
        with self.assertRaisesRegex(ValueError, "Duplicate"):
            module.build_inventory(self.nodes)

    def test_missing_terraform_binary(self):
        with mock.patch.object(module.subprocess, "run", side_effect=FileNotFoundError()):
            with self.assertRaisesRegex(RuntimeError, "executable not found"):
                module.terraform_nodes(BASE)

    def test_terraform_timeout(self):
        with mock.patch.object(module.subprocess, "run", side_effect=subprocess.TimeoutExpired("terraform", 20)):
            with self.assertRaisesRegex(RuntimeError, "Timed out"):
                module.terraform_nodes(BASE)

    def test_missing_control(self):
        del self.nodes["k8s-control-01"]
        with self.assertRaisesRegex(ValueError, "exactly one"):
            module.build_inventory(self.nodes)


if __name__ == "__main__":
    unittest.main()
