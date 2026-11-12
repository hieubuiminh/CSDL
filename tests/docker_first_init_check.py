"""Exercise the real MySQL Docker entrypoint and optional real HTTP authentication.

Creates owned temporary containers only. MySQL uses tmpfs, network=none, and no
published ports or host mounts. The optional app shares that isolated network
namespace and receives copies of the current backend/public, never host mounts.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import pathlib
import re
import secrets
import sys
import time
import uuid

from sql_new_schema_check import NewHarness, NewSchemaReview, NEW_DB, load_expected
from sql_report_check import LABEL, ROOT


HTTP_TEST = r"""
(async () => {
  const base = 'http://127.0.0.1:3000';
  const results = [];
  const check = (name, value) => results.push({name, passed:Boolean(value)});
  async function call(path, method='GET', body, cookie) {
    const headers = {};
    if (body) headers['Content-Type'] = 'application/json';
    if (cookie) headers.Cookie = cookie;
    const response = await fetch(base+path, {method,headers,body:body ? JSON.stringify(body):undefined});
    const data = await response.json();
    return {status:response.status,data,cookie:response.headers.get('set-cookie')?.split(';')[0]};
  }
  let ready = false;
  for (let attempt=0;attempt<40;attempt++) {
    try { if ((await call('/api/health')).status===200) {ready=true;break;} } catch {}
    await new Promise(resolve => setTimeout(resolve,500));
  }
  check('real HTTP health connects with the Docker-created application DB user',ready);
  if (!ready) throw new Error('Application did not become ready');
  const status=await call('/api/auth/status');
  check('first login screen reports setupRequired',status.status===200 && status.data.setupRequired===true);
  check('protected API rejects an anonymous HTTP request',(await call('/api/users')).status===401);
  const body={username:'isolated_admin',displayName:'Tai khoan kiem thu',password:'temporary-test-password-2026',securityQuestion:'first_teacher',securityAnswer:'cau tra loi kiem thu'};
  const setup=await call('/api/auth/setup','POST',body);
  check('initial ADMIN setup succeeds over real HTTP',setup.status===201 && setup.data.user?.role==='admin' && Boolean(setup.cookie));
  const logout=await call('/api/auth/logout','POST',{},setup.cookie);
  check('ADMIN logout clears the real HTTP session cookie',logout.status===200 && logout.cookie==='session=');
  const adminLogin=await call('/api/auth/login','POST',{username:body.username,password:body.password});
  check('ADMIN login succeeds after logout',adminLogin.status===200 && adminLogin.data.user?.role==='admin' && Boolean(adminLogin.cookie));
  const listing=await call('/api/users','GET',undefined,adminLogin.cookie);
  check('new ADMIN session can list safe account fields',listing.status===200 && listing.data.length===1 && !JSON.stringify(listing.data).includes('PasswordHash'));
  const create=await call('/api/users','POST',{...body,username:'isolated_staff',role:'staff',officerId:'CB01'},adminLogin.cookie);
  check('ADMIN creates staff over real HTTP',create.status===201);
  const login=await call('/api/auth/login','POST',{username:'isolated_staff',password:body.password});
  check('staff login succeeds over real HTTP',login.status===200 && login.data.user?.role==='staff' && Boolean(login.cookie));
  check('staff account administration is denied over real HTTP',(await call('/api/users','GET',undefined,login.cookie)).status===403);
  const metrics={};
  for (const path of ['/api/dashboard','/api/registrations','/api/reports/gender','/api/reports/areas?year=2026','/api/reports/age-causes','/api/reports/hospitals','/api/reports/years','/api/registrations/001000000001']) {
    const response=await call(path,'GET',undefined,adminLogin.cookie);
    check('ADMIN can read '+path,response.status===200);
    if(response.status!==200) continue;
    const value=response.data;
    if(path==='/api/registrations') {metrics.registrationCount=value.length;check('HTTP record list contains all 100 sample records',value.length===100);}
    if(path==='/api/reports/gender') {metrics.deceasedTotal=value.reduce((sum,row)=>sum+Number(row.value),0);check('HTTP gender report counts 100 deceased citizens',metrics.deceasedTotal===100);}
    if(path.startsWith('/api/reports/areas')) {metrics.areaCount=value.rows.length;metrics.areaRegistered=value.rows.reduce((sum,row)=>sum+Number(row.value),0);check('HTTP area report returns 8 areas and 73 registrations in 2026',metrics.areaCount===8 && metrics.areaRegistered===73);}
    if(path==='/api/reports/age-causes') {metrics.approvedAgeTotal=value.rows.reduce((sum,row)=>sum+Number(row.total),0);check('HTTP age report counts only 81 approved records',metrics.approvedAgeTotal===81);}
    if(path==='/api/reports/hospitals') {metrics.hospitalCounts=Object.fromEntries(value.rows.map(row=>[row.id,Number(row.value)]));check('HTTP hospital report returns CS01 with 52 previous-quarter notices',metrics.hospitalCounts.CS01===52);}
    if(path==='/api/reports/years') {metrics.yearCounts=Object.fromEntries(value.map(row=>[row.year,Number(row.value)]));check('HTTP yearly report counts 8, 16 and 76 notices',metrics.yearCounts[2024]===8 && metrics.yearCounts[2025]===16 && metrics.yearCounts[2026]===76);}
  }
  const all=(await call('/api/registrations','GET',undefined,adminLogin.cookie)).data;
  const own=all.filter(row=>row.officerId==='CB01');
  const foreign=all.find(row=>row.officerId!=='CB01');
  const staffList=await call('/api/registrations?officerId=CB02','GET',undefined,login.cookie);
  check('staff receives exactly own records despite a forged query parameter',staffList.status===200 && own.length>0 && own.length<all.length && JSON.stringify(staffList.data.map(row=>row.id).sort())===JSON.stringify(own.map(row=>row.id).sort()));
  check('staff own CCCD lookup succeeds',(await call('/api/registrations/'+own[0].deceasedId,'GET',undefined,login.cookie)).status===200);
  check('staff foreign CCCD lookup is hidden',(await call('/api/registrations/'+foreign.deceasedId,'GET',undefined,login.cookie)).status===404);
  check('staff cannot change foreign status',(await call('/api/registrations/'+foreign.id+'/status','PATCH',{status:'Từ chối'},login.cookie)).status===404);
  const dashboard=await call('/api/dashboard','GET',undefined,login.cookie);
  check('staff dashboard is scoped',dashboard.status===200 && Number(dashboard.data.cards.total)===own.length && dashboard.data.recent.every(row=>row.officerId==='CB01'));
  const officers=await call('/api/lookups','GET',undefined,login.cookie);
  check('staff officer choices contain self only',officers.status===200 && officers.data.officers.length===1 && officers.data.officers[0].id==='CB01');
  for(const path of ['gender','areas?year=2026','age-causes','hospitals','years']) check('staff can open scoped report '+path,(await call('/api/reports/'+path,'GET',undefined,login.cookie)).status===200);
  process.stdout.write(JSON.stringify({results,metrics})+'\n');
  process.exitCode=results.some(item=>!item.passed)?1:0;
})().catch(error=>{process.stdout.write(JSON.stringify({error:error.message})+'\n');process.exitCode=1;});
"""


class EntrypointHarness(NewHarness):
    def __init__(self, args):
        super().__init__(args)
        self.name = 'khai-tu-first-init-review-' + uuid.uuid4().hex[:10]
        self.app_name = self.name + '-app'
        self.app_created = False
        self.app_password = secrets.token_urlsafe(24)
        self.state_file = ROOT / 'work/new-schema-review/first-init-containers.json'

    def save_state(self, removed=False):
        self.state_file.parent.mkdir(parents=True, exist_ok=True)
        self.state_file.write_text(json.dumps({'database_container':self.name,'app_container':self.app_name if self.app_created else None,'label':self.label_value,'removed':removed}),encoding='utf-8')

    def own_name(self, name):
        result=self.docker('inspect','--format','{{ index .Config.Labels "'+LABEL+'" }}',name)
        if result.returncode or result.stdout.decode().strip()!=self.label_value:
            raise RuntimeError('Refusing to touch a container whose ownership label does not match.')

    def require(self, process, name):
        if process.returncode:
            raise RuntimeError(name+': '+process.stderr.decode(errors='replace')[-1400:].replace(self.password,'[test password]').replace(self.app_password,'[test password]'))

    def start(self):
        self.require(self.docker('image','inspect',self.args.image),'inspect cached MySQL image')
        self.save_state()
        print('Owned first-init container: '+self.name,flush=True)
        created=self.docker('create','--pull=never','--name',self.name,'--label',LABEL+'='+self.label_value,
                            '--network','none','--tmpfs','/var/lib/mysql:rw,nosuid,size=768m',
                            '-e','MYSQL_ROOT_PASSWORD='+self.password,'-e','MYSQL_DATABASE='+NEW_DB,
                            '-e','MYSQL_USER=khai_tu_test','-e','MYSQL_PASSWORD='+self.app_password,self.args.image)
        self.require(created,'create owned database container')
        self.created=True
        self.owned()
        for file,target in [(self.args.schema,'01-schema.sql'),(self.args.standalone,'02-sample.sql'),(self.args.setup,'03-app-setup.sql')]:
            self.require(self.docker('cp',str(file.resolve()),self.name+':/docker-entrypoint-initdb.d/'+target),'copy canonical initialization SQL')
        self.require(self.docker('start',self.name),'start owned database container')
        for _ in range(100):
            running=self.docker('inspect','--format','{{.State.Running}}',self.name)
            if running.stdout.decode().strip()!='true':
                logs=self.docker('logs','--tail','100',self.name)
                text=(logs.stdout+logs.stderr).decode(errors='replace')
                errors=[line for line in text.splitlines() if 'ERROR' in line or 'error' in line][-8:]
                raise RuntimeError('MySQL entrypoint exited before readiness: '+' | '.join(errors))
            ready=self.docker('exec','-e','MYSQL_PWD='+self.app_password,self.name,'mysql','-h127.0.0.1','-ukhai_tu_test','-N','-B',NEW_DB,'-e','SELECT VERSION(),(SELECT COUNT(*) FROM App_User);')
            if ready.returncode==0:
                self.metadata['mysql_version']=ready.stdout.decode().strip().split('\t')[0]
                self.metadata['entrypoint_application_user_ready']=True
                return
            time.sleep(1)
        raise RuntimeError('The real Docker entrypoint did not finish all three SQL files within 100 seconds.')

    def run_http(self):
        if self.docker('image','inspect',self.args.app_image).returncode:
            return {'skipped':'The requested application image is not cached; no pull attempted.'}
        self.owned()
        command=['create','--pull=never','--name',self.app_name,'--label',LABEL+'='+self.label_value,
                 '--network','container:'+self.name]
        environment={'DB_HOST':'127.0.0.1','DB_PORT':'3306','DB_NAME':NEW_DB,'DB_USER':'khai_tu_test',
                     'DB_PASSWORD':self.app_password,'JWT_SECRET':secrets.token_urlsafe(48),'COOKIE_SECURE':'false',
                     'PORT':'3000','BIND_HOST':'127.0.0.1','NODE_ENV':'production','ALLOW_LOCAL_PASSWORD_RESET':'false'}
        for key,value in environment.items(): command.extend(['-e',key+'='+value])
        command.append(self.args.app_image)
        self.require(self.docker(*command),'create owned app container')
        self.app_created=True
        self.save_state()
        self.own_name(self.app_name)
        for directory in ['backend','public']:
            self.require(self.docker('cp',str((ROOT/directory).resolve())+'/.',self.app_name+':/app/'+directory),'copy current application source')
        self.require(self.docker('start',self.app_name),'start isolated application')
        response=self.docker('exec','-i',self.app_name,'node','-',data=HTTP_TEST.encode(),timeout=90)
        lines=response.stdout.decode(errors='replace').strip().splitlines()
        try:
            result=json.loads(lines[-1])
        except (IndexError,json.JSONDecodeError):
            raise RuntimeError('HTTP test did not return its aggregate JSON result: '+response.stderr.decode(errors='replace')[-800:])
        return result

    def close(self):
        if self.app_created:
            self.own_name(self.app_name)
            self.require(self.docker('rm','--force',self.app_name),'remove owned app test container')
        super().close()
        if self.metadata.get('container_removed'):
            self.save_state(True)


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--run',action='store_true')
    parser.add_argument('--image',default='mysql:8.0')
    parser.add_argument('--app-image',default='khai-tu-app:bang-moi')
    parser.add_argument('--skip-http',action='store_true')
    parser.add_argument('--schema',type=pathlib.Path,default=ROOT/'database/tao_bang.sql')
    parser.add_argument('--standalone',type=pathlib.Path,default=ROOT/'database/du_lieu_mau.sql')
    parser.add_argument('--setup',type=pathlib.Path,default=ROOT/'database/app_setup.sql')
    parser.add_argument('--queries',type=pathlib.Path,default=ROOT/'database/truy_van.sql')
    original_seed=ROOT/'du_lieu_mau.sql'
    if not original_seed.exists():
        original_seed=ROOT/'work/truoc-khi-dung-bang-moi-20261110/nguon-nguoi-dung/du_lieu_mau.sql'
    parser.add_argument('--seed-source',type=pathlib.Path,default=original_seed)
    parser.add_argument('--output',type=pathlib.Path,default=ROOT/'work/new-schema-review/docker-first-init-results.json')
    args=parser.parse_args()
    if not args.run:
        print('Prepared only. No Docker command was executed.')
        return 0
    data,args.expected=load_expected(args.seed_source)
    args.expected_counts={table:item['count'] for table,item in args.expected.items()}
    review=NewSchemaReview(args,data)
    review.harness=EntrypointHarness(args)
    files=[args.schema,args.standalone,args.setup,args.queries,args.seed_source]
    hashes={str(file):hashlib.sha256(file.read_bytes()).hexdigest() for file in files}
    error=None
    http=None
    try:
        review.harness.start()
        review.result('real Docker entrypoint completed schema, sample and account setup',True)
        collation=review.execute('SELECT DEFAULT_COLLATION_NAME FROM information_schema.SCHEMATA WHERE SCHEMA_NAME=DATABASE();','database collation')
        review.result('Docker-auto-created database is normalized to utf8mb4_unicode_ci',collation=='utf8mb4_unicode_ci',actual=collation)
        locales=review.execute("SELECT DISTINCT DATABASE_COLLATION FROM information_schema.TRIGGERS WHERE TRIGGER_SCHEMA=DATABASE();",'trigger database collations')
        review.result('all trigger local variables inherit the canonical database collation',locales=='utf8mb4_unicode_ci',actual=locales)
        snapshot=review.snapshot()
        review.snapshots.append(snapshot)
        for table,expected in args.expected.items():
            review.result(table+': entrypoint imported unchanged raw sample data',snapshot[table]['rows']==expected['count'] and snapshot[table]['sha256']==expected['sha256'],count=snapshot[table]['rows'])
        review.constraints()
        review.check_reports()
        if not args.skip_http:
            http=review.harness.run_http()
            for item in http.get('results',[]): review.result(item['name'],item['passed'])
            if 'error' in http: review.result('real HTTP authentication flow',False,error=http['error'])
    except Exception as exc:
        error=str(exc)
        print('ERROR: '+error,file=sys.stderr,flush=True)
    finally:
        try: review.harness.close()
        except Exception as exc: error=(error+'; ' if error else '')+str(exc)
        review.result('initialization SQL sources remain unchanged',all(hashlib.sha256(file.read_bytes()).hexdigest()==hashes[str(file)] for file in files))
        report={'database_container':review.harness.name,'app_container':review.harness.app_name if review.harness.app_created else None,
                'database':NEW_DB,'isolation':{'network':'none; optional app shares the owned DB network namespace','ports':[],'host_mounts':[],'mysql_data':'disposable tmpfs'},
                'containers_removed':review.harness.metadata.get('container_removed',False),'mysql_version':review.harness.metadata.get('mysql_version'),
                'source_sha256':hashes,'snapshots':review.snapshots,'metadata':review.metadata,'http':http,'results':review.results,'error':error}
        args.output.parent.mkdir(parents=True,exist_ok=True)
        args.output.write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
        print('Aggregate result: '+str(args.output),flush=True)
    return int(bool(error) or any(not item['passed'] for item in review.results))


if __name__=='__main__':
    raise SystemExit(main())
