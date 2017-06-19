#!/usr/bin/python2

import os
import re
import sys,io
import tarfile



def ParseTimesStream(instream,outstream,name):
  outstream.write(name+':\t'.decode("utf-8"))
  matcher = re.compile('SOLVER TOTAL TIME\(CPU,REAL\):\s*\S+\s+(\S+)')
  byteout = instream.read()
  if (type(byteout)==str):
    matches = matcher.findall(byteout)
  else:
    matches = matcher.findall(byteout.decode("utf-8"))
  outstream.write(matches[0].decode("utf-8"))
  #outstream.write('\n')

  return matches


def ParseTimes(testbase,nproc=1,file=sys.stdout):  
  testdirs = os.listdir(testbase)
  outputs=dict()
  for dir in testdirs:
    with open(testbase+'/'+dir+'/test-stdout_'+str(nproc)+'.log','r') as f:
      matches = ParseTimesStream(f,file,dir)
      outputs[dir] = float(matches[0])
  return outputs

def ReadTestsFromTGZ(tarname=u"ctest_benchmark.tar.gz"):
  coding="utf-8"
  outputs=dict()
  with io.StringIO(None) as sbuf:
    sbuf.write(u"# SOLVER TOTAL TIME from tests in '"+tarname+u"':\n")
    with tarfile.open(tarname,'r') as tf:
      matcher = re.compile("\S*/(\S+)/test-stdout_(\d+)")
      members = tf.getmembers()
      for member in members:
        matches = matcher.findall(member.name)
        if(len(matches)>0):
          nprocs = int(matches[0][1])
          outputs[member.name]=(ParseTimesStream(tf.extractfile(member),
              sbuf,matches[0][0]),
              nprocs)
          sbuf.write(u'\t('+matches[0][1]+u' procs)\n')
    sbuf.seek(0)
    print(sbuf.read())
    
if __name__=="__main__":
  if len(sys.argv)>1:
    outputs = ReadTestsFromTGZ(sys.argv[1])
  else:
    print("Usage: "+sys.argv[0]+" <filename.tar.gz>")
