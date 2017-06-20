#!/usr/bin/python3

import os
import re
import sys
import io
import tarfile


def ParseTimesStream(instream,outstream,name):
  outstream.write(name+'\t')
  time_re = re.compile('SOLVER TOTAL TIME\(CPU,REAL\):\s*\S+\s+(\S+)')
  pass_re = re.compile('(PASSED|FAILED)')
  byteout = instream.read()
  if (type(byteout)==str):
    time_match = time_re.findall(byteout)
    pass_match = pass_re.findall(byteout)
  else:
    time_match = time_re.findall(byteout.decode("utf-8"))
    pass_match = pass_re.findall(byteout.decode("utf-8"))

  if len(time_match) > 0:
    outstream.write(time_match[0])
    time_retval=time_match[0]
  else:
    time_retval=''

  if len(pass_match) > 0:
    pass_retval = pass_match[0]
  else:
    pass_retval='UNDEFINED'

  return (time_retval, pass_retval)

def ParsePassed(instream):
  byteout = instream.read()
  if isinstance(byteout,str):
    return byteout == "1\n"
  else:
    return byteout.decode("utf-8") == "1\n"

def ParseTimes(testbase, nproc=1, file=sys.stdout):  
  testdirs = os.listdir(testbase)
  outputs = dict()
  for dir in testdirs:
    with open(testbase+'/'+dir+'/test-stdout_'+str(nproc)+'.log', 'r') as f:
      matches = ParseTimesStream(f,file,dir)
      outputs[dir] = float(matches[0])
  return outputs

def ReadTestsFromTGZ(tarname="ctest_benchmark.tar.gz"):
  outputs = dict()
  passed = dict()
  with io.StringIO("") as sbuf:
    sbuf.write("# SOLVER TOTAL TIME from tests in '"+tarname+"':\n")
    sbuf.write("Test name\ttime(s)\t(NPROCS)\tpass/fail\n")
    with tarfile.open(tarname, 'r') as tf:
      matcher = re.compile("\S*/(\S+)/test-stdout_(\d+)")
      passed_matcher = re.compile("\S*/(\S+)/TEST.PASSED(_{1}(\d+)|$)")
      members = tf.getmembers()
      for member in members:
        matches = passed_matcher.match(member.name)
        if matches:
          matches = matches.groups()
          testname = matches[0]
          nprocs = 1
          if matches[2]:
            nprocs = int(matches[2])
          passed[(testname, nprocs)] = ParsePassed(tf.extractfile(member))

      for member in members:
        matches = matcher.match(member.name)
        passed_matches = passed_matcher.match(member.name)
        if matches:
          matches = matches.groups()
          testname = matches[0]
          nprocs = int(matches[1])

          outputs[testname]=(ParseTimesStream(tf.extractfile(member),sbuf,matches[0]),
              nprocs)
          if (testname,nprocs) in passed:
          
            sbuf.write('\t'+matches[1]+'\t')
            if passed[(testname,nprocs)]:
              sbuf.write("PASSED\n")
            else:
              sbuf.write("FAILED\n")
          else:
            sbuf.write('\t('+matches[1]+' procs)'+'\tTEST.PASSED missing or error.\n')

    sbuf.seek(0)
    print(sbuf.read())
    
if __name__=="__main__":
  if len(sys.argv)>1:
    outputs = ReadTestsFromTGZ(sys.argv[1])
  else:
    print("Usage: "+sys.argv[0]+" <filename.tar.gz>")
