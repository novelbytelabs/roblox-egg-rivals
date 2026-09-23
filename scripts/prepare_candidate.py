#!/usr/bin/env python3
"""Freeze paired Studio builds and verify their exact script bytes. Does not publish."""
from pathlib import Path
from datetime import datetime, timezone
import hashlib
import json
import subprocess
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parent.parent

def hashes():
    return {str(p.relative_to(ROOT)): hashlib.sha256(p.read_bytes()).hexdigest()
            for p in sorted((ROOT / 'src').rglob('*.lua'))}

def scripts(path):
    result = {}
    def walk(node, parent=''):
        for item in node.findall('Item'):
            name = item.find("./Properties/string[@name='Name']")
            current = parent + '/' + (name.text if name is not None else item.attrib['class'])
            source = item.find("./Properties/*[@name='Source']")
            if source is not None:
                result[current] = (source.text or '').encode()
            walk(item, current)
    walk(ET.parse(path).getroot())
    return result

def main():
    branch = subprocess.check_output(['git','branch','--show-current'],cwd=ROOT,text=True).strip()
    if branch != 'feature/0.4.0-living-world':
        raise RuntimeError('Wrong branch; refusing to build this workstream')
    subprocess.run(['stylua','--check','src'],cwd=ROOT,check=True)
    before = hashes()
    digest = hashlib.sha256(json.dumps(before,sort_keys=True,separators=(',',':')).encode()).hexdigest()
    stamp = datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%S%fZ')
    out = ROOT / 'build' / ('candidate-' + stamp)
    out.mkdir(parents=True,exist_ok=False)
    artifacts = {}
    for mode, template in [('PLAY','default.project.json'),('TEST','test.project.json')]:
        project = json.loads((ROOT/template).read_text())
        def absolute(node):
            if isinstance(node,dict):
                for key,value in node.items():
                    if key=='$path': node[key]=str(ROOT/value)
                    else: absolute(value)
            elif isinstance(node,list):
                for value in node: absolute(value)
        absolute(project)
        project['tree']['Workspace'].setdefault('$attributes',{})['Stage3SourceDigest']=digest
        project_path = out / (mode + '.project.json')
        project_path.write_text(json.dumps(project,indent=2))
        artifact = out / ('EggRivals_0.4.0_' + mode + '.rbxlx')
        subprocess.run(['rojo','build',str(project_path),'-o',str(artifact)],cwd=ROOT,check=True)
        artifacts[mode]={'path':str(artifact),'sha256':hashlib.sha256(artifact.read_bytes()).hexdigest()}
    if before != hashes(): raise RuntimeError('Source changed during build')
    play,suite=scripts(Path(artifacts['PLAY']['path'])),scripts(Path(artifacts['TEST']['path']))
    if play != suite: raise RuntimeError('PLAY/TEST script mismatch')
    raw=sorted(p.read_bytes() for p in (ROOT/'src').rglob('*.lua'))
    if sorted(play.values()) != raw: raise RuntimeError('Built scripts differ from source bytes')
    manifest={'branch':branch,'head':subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),
              'status':subprocess.check_output(['git','status','--porcelain=v1'],cwd=ROOT,text=True),
              'sourceDigest':digest,'digestAlgorithm':'SHA256 of sorted compact JSON mapping relative script path to SHA256',
              'files':before,'artifacts':artifacts,'scriptCount':len(play),'scriptByteIdentity':'PASS',
              'engine':'NOT_RUN','humanPresentation':'PENDING'}
    (out/'manifest.json').write_text(json.dumps(manifest,indent=2))
    for mode in artifacts: Path(artifacts[mode]['path']).chmod(0o444)
    print('CANDIDATE_DIRECTORY='+str(out))
    print('SOURCE_DIGEST='+digest)
    print('IDENTICAL_GAMEPLAY_SCRIPTS='+str(len(play)))

if __name__=='__main__':
    main()
