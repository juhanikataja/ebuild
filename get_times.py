#!/usr/bin/env python3

import os
import re
import sys
import io
import tarfile
import argparse
import textwrap


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

def ReadTestsFromTGZ(sbuf, tarname):
  outputs = dict()
  passed = dict()
  # with io.StringIO("") as sbuf:
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
  return outputs
    
def ReadLogsFromTGZ(sbuf,outputs,tarname):
  with tarfile.open(tarname, 'r') as tf:
    for test in filter(lambda x: outputs[x][0][1] != 'PASSED', outputs):
      nproc = str(outputs[test][1])
      fname = './fem/tests/'+test+'/test-stdout_'+str(nproc)+'.log'
      member = tf.getmember(fname)
      with tf.extractfile(member) as f:
        sbuf.write('##### Test name: ' + test+'_'+str(nproc)+'\n')
        sbuf.write(f.read().decode("utf-8"))

def ReadNonPassedTests(sbuf,outputs):
  for test in filter(lambda x: outputs[x][0][1] != 'PASSED', outputs):
    sbuf.write(test)
    sbuf.write(' ')

if __name__=="__main__":
    parser = argparse.ArgumentParser(
            description=textwrap.dedent('''\n
            Analyze and pretty-print elmer test output data tarballs.

            Copyright (c) 2018 CSC - Finnish IT Center for Science
            '''),
            formatter_class=argparse.RawDescriptionHelpFormatter)

    parser.add_argument('testdata', metavar='<filename.tar.gz>',type=str,nargs=1, help='Tarball that contains test outputlogs.')
    parser.add_argument("-p", "--printfailed", dest="printlogs", action="store_true", help='Print logs of failed tests to stdout.')
    parser.add_argument("-n", "--notpassed", dest="notpassed", action="store_true", help='Print non-passed testnames only.')
    args = parser.parse_args()

    tdfile = args.testdata[0]
    with io.StringIO("") as sbuf:
      outputs = ReadTestsFromTGZ(sbuf, tdfile)
      if args.printlogs:
        sbuf.truncate(0)
        ReadLogsFromTGZ(sbuf, outputs, tdfile)
      if args.notpassed:
        sbuf.truncate(0)
        ReadNonPassedTests(sbuf,outputs)
      sbuf.seek(0)
      print(sbuf.read())

  # if len(sys.argv)>1:
  #   outputs = ReadTestsFromTGZ(sys.argv[1])
  # else:
  #   print("Usage: "+sys.argv[0]+" <filename.tar.gz>")
