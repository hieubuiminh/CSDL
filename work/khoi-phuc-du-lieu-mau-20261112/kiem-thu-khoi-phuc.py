"""Exercise the exact restore script in owned, disposable Docker containers only."""
from pathlib import Path
from types import SimpleNamespace
import json, sys

ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tests'))
import docker_first_init_check as module

folder=Path(__file__).resolve().parent
args=SimpleNamespace(image='mysql:8.0',app_image='khai-tu-app:bang-moi',schema=ROOT/'database/tao_bang.sql',standalone=ROOT/'database/du_lieu_mau.sql',setup=ROOT/'database/app_setup.sql')
harness=module.EntrypointHarness(args)
results=[]
def check(name,value):
    results.append({'name':name,'passed':bool(value)})
    print(('PASS ' if value else 'FAIL ')+name,flush=True)
def sql(value):
    process=harness.sql(value)
    if process.returncode: raise RuntimeError('Owned test SQL failed')
    return process.stdout.decode('utf8').strip()
try:
    harness.start()
    sql("INSERT INTO App_User (Username,PasswordHash,DisplayName,Role,MaCanBo) VALUES ('test_admin','preserved_admin_hash','Test ADMIN','admin',NULL),('test_staff','preserved_staff_hash','Test STAFF','staff','CB01'); UPDATE Ho_So_Khai_Tu SET TrangThaiHoSo='Chờ xử lý' WHERE SoGiayKhaiTu='HS002'; INSERT INTO Cong_Dan (CCCD,HoTen,NgaySinh,GioiTinh) VALUES ('990000000001','Test extra','1980-01-01','Nam');")
    before=sql('SELECT COUNT(*) FROM Cong_Dan;')
    script=(folder/'khoi-phuc-du-lieu-mau.cjs').read_text(encoding='ascii')
    module.HTTP_TEST="process.argv.push('--apply','--probe-rollback');\n"+script
    rollback=harness.run_http()
    check('failed restore rolls back all deletions',rollback.get('rolledBack') is True and sql('SELECT COUNT(*) FROM Cong_Dan;')==before)
    process=harness.docker('exec','-i',harness.app_name,'node','-','--apply',data=script.encode('ascii'))
    restore=json.loads(process.stdout.decode().strip().splitlines()[-1])
    check('exact source sample restored in all nine tables',restore.get('ok') is True and restore.get('totalRows')==491 and all(item['matchesSource'] for item in restore.get('after',{}).values()))
    check('ADMIN and staff rows including credentials are preserved',restore.get('accountsPreserved') is True and restore.get('accountCount')==2)
    check('extra test citizen removed',sql("SELECT COUNT(*) FROM Cong_Dan WHERE CCCD='990000000001';")=='0')
    check('HS002 default approved status restored',sql("SELECT TrangThaiHoSo='Đã duyệt' FROM Ho_So_Khai_Tu WHERE SoGiayKhaiTu='HS002';")=='1')
    process=harness.docker('exec','-i',harness.app_name,'node','-','--apply',data=script.encode('ascii'))
    again=json.loads(process.stdout.decode().strip().splitlines()[-1])
    check('running restore again is safe and retains accounts',again.get('ok') is True and again.get('accountsPreserved') is True and again.get('after')==restore.get('after'))
finally:
    harness.close()
    check('owned temporary containers removed',harness.metadata.get('container_removed') is True)
    (folder/'kiem-thu-khoi-phuc.json').write_text(json.dumps({'results':results,'isolated':True,'containersRemoved':harness.metadata.get('container_removed',False)},indent=2)+'\n',encoding='utf8')
sys.exit(any(not item['passed'] for item in results))
