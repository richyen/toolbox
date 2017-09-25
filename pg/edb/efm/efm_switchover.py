import sys
import telnetlib
import os

HOST = '127.0.0.1'

### User needs to provide EFM cluster-name
efm_cluster_name = raw_input("Enter your EFM cluster-name: ")

### TODO: Logic to pull EFM version
efm_version = '2.1'

prop_file = '/etc/efm-' + efm_version + "/" + efm_cluster_name + ".properties"

port_cmd = 'cat ' + prop_file + ' | grep "^admin.port" | cut -f 2 -d"="'
p_raw = os.popen(port_cmd).read()
p_raw.rstrip("\r")
PORT=int(p_raw)

### Get EFM user authentication key
password = ''
with open('/var/run/efm-' + efm_version + '.' + efm_cluster_name + '.key', 'r') as key_file:
  password = key_file.read()

### Connect to EFM via telnet and issue the SWITCHOVER command
tn = telnetlib.Telnet(HOST, PORT, 60)
tn.set_debuglevel(1)
tn.msg('connected')

tn.write("SWITCHOVER\n")
auth_needed = tn.read_until('_authorization_needed_', 10)
tn.msg('got message: ' + auth_needed)
if auth_needed == '_authorization_needed_':
  tn.write(password + "\n")
else:
  print 'Could not issue SWITCHOVER commmand.  Aborting...'
  sys.exit()

try:
  ftw = tn.read_until('F_T_W', 10)
  tn.msg('got message:' + ftw)
except EOFError:
  print('Encountered EOF.  Aborting...')
  tn.close()

print tn.read_all()
print 'Switchover complete'
