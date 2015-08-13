#!/usr/bin/python
import sys
import re

filename = sys.argv[1]

class PostgresConf:
    params = {}
    def build(self, fname):
        try:
            file = open(fname)
        except ioerror:
            print '%s is not able to be opened' % fname
        conf_data = file.readlines()
        for ln in conf_data:
            ln = chomp(ln)
            if re.search('^\s+#',ln) or not re.search(' = ',ln) or re.search('^\s+$',ln) or ln == '':
                continue
            #print ">>>%s<<<" % ln
            (key, val) = ln.split(' = ')

            #we want to collect numbers for commented out params
            sr = re.compile('^#')
            key = sr.sub('',key)

            #get rid of whitespace
            sr = re.compile('\\t')
            val = sr.sub(' ',val)
            m = re.search('(.+?)\s*#.*', val)
            if m:
                val = m.group(1)
            sr = re.compile('\s+$')
            val = sr.sub('',val)

            #convert ints
            if re.search('^\d+$',val):
                val = int(val)
            #save the data
            self.params[key] = val
        file.close()
        return
    def calc_shm_use(self):
        max_locks_per_transaction = self.params['max_locks_per_transaction']
        max_prepared_transactions = (600 + (270 * max_locks_per_transaction)) * self.params['max_prepared_transactions']
        max_fsm_relations         = 70 * self.params['max_fsm_relations']
        max_connections           = (400 + (270 * max_locks_per_transaction)) * self.params['max_connections']
        shared_buffers            = 8300 * self.params['shared_buffers']
        max_fsm_pages             = 6 * self.params['max_fsm_pages']
        wal_buffers               = 8200 * self.params['wal_buffers']
        shm_use = max_connections + max_prepared_transactions + shared_buffers + wal_buffers + max_fsm_relations + max_fsm_pages
        return shm_use

def chomp(ln):
    ln = ln[:-1]
    return ln

def main():
    shm = open('/proc/sys/kernel/shmmax')
    shmmax = int(chomp(shm.readline()))
    shm.close()
    print "shmmax is currently %s (%sGB)" % (shmmax, shmmax / 1073741824.0)

    conf = PostgresConf()
    conf.build(filename)
    wanted = ('max_locks_per_transaction','max_prepared_transactions',
                     'max_fsm_relations','max_connections','shared_buffers',
                     'max_fsm_pages','wal_buffers')
    for key in wanted:
        print "%s \t\t = %s" % (key, conf.params[key])
    shm_use = conf.calc_shm_use()
    print "conf file will use approx %s bytes (%sGB) of shared memory" % (shm_use, shm_use / 1073741824.0)

    print "here are some other shared_buffers options:"
    for i in range(1,50):
        shared_buffers = conf.params['shared_buffers']
        conf.params['shared_buffers'] = shared_buffers - (10 * i)
        shm_use = conf.calc_shm_use()
        print "%s  |  %s" % (conf.params['shared_buffers'], shm_use)
        conf.params['shared_buffers'] = shared_buffers

main();
