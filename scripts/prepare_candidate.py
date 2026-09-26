#!/usr/bin/env python3
"""Freeze exact-source PLAY/TEST builds. Does not launch Studio or publish."""
import argparse
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import re
import subprocess
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parent.parent
BRANCHES = (
    "feature/0.4.0-living-world",
    "fix/0.4.6-speed-mastery-verification",
    "feature/0.4.7-living-ranch",
)
TEMPLATES = ("default.project.json", "test.project.json")


def git(root, *args):
    return subprocess.check_output(["git", *args], cwd=root, text=True).strip()


def file_hash(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def hashes(root=ROOT):
    source = root / "src"
    if source.is_symlink() or not source.is_dir():
        raise RuntimeError("Source directory is missing or symlinked")
    paths = sorted(source.rglob("*"))
    if any(p.is_symlink() for p in paths):
        raise RuntimeError("Symlinked source is not an admissible candidate")
    result = {p.relative_to(root).as_posix(): file_hash(p)
              for p in paths if p.is_file() and p.suffix == ".lua"}
    tracked = subprocess.check_output(["git", "ls-files", "-z", "--", "src"], cwd=root)
    expected = {p.decode() for p in tracked.split(b"\0") if p.endswith(b".lua")}
    if not result or set(result) != expected:
        raise RuntimeError("Lua source set differs from tracked Git paths")
    return result


def scripts(path):
    result = {}

    def walk(node, parent=""):
        for item in node.findall("Item"):
            name = item.find("./Properties/string[@name='Name']")
            current = parent + "/" + (name.text if name is not None else item.attrib["class"])
            source = item.find("./Properties/*[@name='Source']")
            if source is not None:
                if current in result:
                    raise RuntimeError("Duplicate built script path: " + current)
                result[current] = (source.text or "").encode()
            walk(item, current)

    walk(ET.parse(path).getroot())
    return result


def absolute_paths(node, root):
    if isinstance(node, dict):
        for key, value in node.items():
            if key == "$path":
                target = (root / value).resolve(strict=True)
                if not target.is_relative_to(root):
                    raise RuntimeError("Project source path escapes the candidate worktree")
                node[key] = str(target)
            else:
                absolute_paths(value, root)
    elif isinstance(node, list):
        for value in node:
            absolute_paths(value, root)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo", type=Path, default=ROOT,
                        help="Explicit isolated source worktree; tooling identity is recorded separately")
    parser.add_argument("--expected-branch", choices=BRANCHES, default=BRANCHES[0])
    parser.add_argument("--expected-head")
    parser.add_argument("--output-root", type=Path,
                        help="Generated builds directory, separate from canonical source")
    args = parser.parse_args()
    root = args.repo.resolve(strict=True)
    branch, head = git(root, "branch", "--show-current"), git(root, "rev-parse", "HEAD")
    if args.expected_branch != BRANCHES[0] and not args.expected_head:
        parser.error("The repair and Living Ranch branches require --expected-head")
    if args.expected_head and not re.fullmatch(r"[0-9a-f]{40}", args.expected_head):
        parser.error("--expected-head must be a full 40-character lowercase commit SHA")
    if branch != args.expected_branch or (args.expected_head and head != args.expected_head):
        raise RuntimeError("Wrong branch or HEAD; refusing to build this workstream")
    for name in TEMPLATES:
        if (root / name).is_symlink():
            raise RuntimeError("Symlinked project template")
    if git(root, "status", "--porcelain=v1", "--", "src", *TEMPLATES):
        raise RuntimeError("Commit or preserve source/template WIP before freezing a candidate")
    before = hashes(root)
    template_hashes = {name: file_hash(root / name) for name in TEMPLATES}
    runner_hash = file_hash(Path(__file__).resolve())
    subprocess.run(["stylua", "--check", "src"], cwd=root, check=True)
    digest = hashlib.sha256(json.dumps(before, sort_keys=True, separators=(",", ":")).encode()).hexdigest()
    stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S%fZ")
    output_root = args.output_root.resolve() if args.output_root else root / "build"
    out = output_root / ("candidate-" + stamp)
    out.mkdir(parents=True, exist_ok=False)
    artifacts = {}
    try:
        for mode, template in zip(("PLAY", "TEST"), TEMPLATES):
            project = json.loads((root / template).read_text())
            absolute_paths(project, root)
            attributes = project["tree"]["Workspace"].setdefault("$attributes", {})
            if attributes.get("Stage3AutoTest") is not (mode == "TEST"):
                raise RuntimeError("PLAY/TEST execution flag mismatch")
            attributes["Stage3SourceDigest"] = digest
            project_path = out / (mode + ".project.json")
            project_path.write_text(json.dumps(project, indent=2) + "\n")
            artifact = out / ("EggRivals_" + mode + ".rbxlx")
            subprocess.run(["rojo", "build", str(project_path), "-o", str(artifact)], cwd=root, check=True)
            artifacts[mode] = {"path": str(artifact), "sha256": file_hash(artifact)}
        if before != hashes(root) or template_hashes != {name: file_hash(root / name) for name in TEMPLATES}:
            raise RuntimeError("Source or project templates changed during build")
        if branch != git(root, "branch", "--show-current") or head != git(root, "rev-parse", "HEAD"):
            raise RuntimeError("Git identity changed during build")
        if runner_hash != file_hash(Path(__file__).resolve()):
            raise RuntimeError("Candidate-builder bytes changed during execution")
        play = scripts(Path(artifacts["PLAY"]["path"]))
        suite = scripts(Path(artifacts["TEST"]["path"]))
        if play != suite:
            raise RuntimeError("PLAY/TEST script mismatch")
        if sorted(play.values()) != sorted((root / name).read_bytes() for name in before):
            raise RuntimeError("Built scripts differ from exact source bytes")
        manifest = {
            "branch": branch, "head": head, "sourceRoot": str(root),
            "status": git(root, "status", "--porcelain=v1"),
            "sourceDigest": digest,
            "digestAlgorithm": "SHA256 of sorted compact JSON mapping relative script path to SHA256",
            "files": before, "templateHashes": template_hashes,
            "runnerPath": str(Path(__file__).resolve()), "runnerSha256": runner_hash,
            "artifacts": artifacts, "scriptCount": len(play), "scriptByteIdentity": "PASS",
            "engine": "NOT_RUN", "humanPresentation": "PENDING",
        }
        (out / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
        for info in artifacts.values():
            Path(info["path"]).chmod(0o444)
    except Exception as exc:
        (out / "build-failure.json").write_text(json.dumps({
            "branch": branch, "head": head, "sourceDigest": digest,
            "error": str(exc), "engine": "NOT_RUN", "artifacts": artifacts,
        }, indent=2) + "\n")
        raise
    print("CANDIDATE_DIRECTORY=" + str(out))
    print("SOURCE_DIGEST=" + digest)
    print("IDENTICAL_GAMEPLAY_SCRIPTS=" + str(len(play)))


if __name__ == "__main__":
    main()
