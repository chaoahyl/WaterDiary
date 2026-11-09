"""Exercise the production diary logic with Swift Foundation, without building the app.

Usage: python Tests/run_model_tests.py
       python Tests/run_model_tests.py --wsl Ubuntu

The temporary test source loads the Models and Stores files, omitting only
Combine imports and observation annotations. All model methods run directly
from production.
"""

import argparse
from pathlib import Path
import shutil
import subprocess
import tempfile


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--wsl", metavar="DISTRO")
    parser.add_argument("--swift-arg", action="append", default=[], help="Extra Swift interpreter argument")
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    model_files = [root / "WaterDiary/Models/WaterModels.swift", root / "WaterDiary/Stores/WaterStore.swift"]
    model = "\n".join(path.read_text(encoding="utf-8") for path in model_files)
    model = model.replace("import Combine\n", "").replace(": ObservableObject", "").replace("@Published ", "")
    tests = (root / "Tests/WaterStoreTests.swift").read_text(encoding="utf-8")

    with tempfile.TemporaryDirectory(prefix="waterdiary-tests-") as temporary:
        path = Path(temporary) / "main.swift"
        path.write_text("import Foundation\n" + model + "\n" + tests, encoding="utf-8")
        if args.wsl:
            mapped = subprocess.check_output(
                ["wsl", "-d", args.wsl, "--exec", "wslpath", "-a", path.as_posix()], text=True
            ).strip()
            command = ["wsl", "-d", args.wsl, "--exec", "bash", "-lc", 'swift "$@"', "--", *args.swift_arg, mapped]
        else:
            swift = shutil.which("swift")
            if not swift:
                parser.error("Swift is unavailable; install Swift or select an existing WSL distro with --wsl.")
            command = [swift, *args.swift_arg, str(path)]
        raise SystemExit(subprocess.call(command))


if __name__ == "__main__":
    main()
