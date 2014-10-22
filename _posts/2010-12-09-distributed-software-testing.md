---
layout: post
title: Distributed software testing
tags: []
--- 

# About me

A word about me first: My name is Daniel Mewes and I just came over to
California to work at RethinkDB as an intern for the oncoming months. After
having been an undergraduate student of computer science at Saarland
University, Germany for the last two years, I am exited to work on an
influential real-world project at RethinkDB now. Why RethinkDB? Not only does
RethinkDB develop an exciting and novel piece of database technology,
RethinkDB also provides the great "startup kind" of work experience.

# Software testing

In complex software systems like database management systems, different
components have to work together. These components can interact in complex
ways, yielding a virtually infinite number of possible states that the overall
system can reach. This has consequences for software testing. As bugs in the
code might only show up in a small fraction of the possible states,
comprehensive testing of the system is essential. Encapsulation of code and
data into objects can reduce the number of states that must be considered for
any single piece of code. However an extremely large number of states can
still remain, especially when considering parallel systems. Reliability
requirements for database management systems on the other hand are stringent.
Losing or corrupting data due to bugs in the program cannot be tolerated here.

Among other measures, we at RethinkDB ensure the reliability of our software
by running extensive tests on a daily basis. The problem with these tests is
that they take a lot of time to complete. We recently reached time
requirements of more than 24 hours on a decent machine for a single test run.
So clearly a single machine is not enough anymore to run the tests. For our
daily test runs, we want to get results quickly. Buying more machines is
pricey, especially as those machines would be idle during the times at which
no tests are run. It also is not very flexible.

# Tapping into the endless resources of the cloud to ensure software quality and reliability

Cloud computing provides a more flexible and less pricey way to circumvent the
limitations of limited local hardware resources. We decided to use Amazon's
Elastic Compute Cloud ([Amazon EC2](http://aws.amazon.com/ec2/)). If you need
the computing power of ten systems, you can get that from EC2 in a matter of
minutes. If you need the power of a hundred machines, you can get that in a
matter of minutes, too. Basically, Amazon's EC2 provides you with as much
computing power as you need, at just the time that you need it. EC2 allows to
dynamically allocate and deallocate virtual compute nodes, which are billed on
an hourly basis. Each node can be used like a normal computer. The nodes run
Linux (Windows nodes are also available) and are accessible through SSH. So
EC2 looked like a promising platform to make our tests finish faster.

![Distributed Software Testing](/assets/images/blog/2010-12-09-distributed-software-testing-1.png)

_EC2 console showing a few nodes_

Our existing test suite already split up the work into independent test
scripts. What was missing for utilizing EC2 was an automated mechanism to
start and setup a number of EC2 nodes and dispatch the individual tests to
these nodes to run in parallel. Setting up a node especially involves the step
of installing a current build of RethinkDB together with a number of
dependencies on the node's file system. I wrote a Python script to fulfill
exactly these tasks. Our main concern was to improve the overall performance
of the testing process as much as possible.

In more detail, our new distributed testing tool works in the following steps:

  * Allocate a number of nodes in Amazon's EC2.
  * Once all nodes are up and booted, install the current build of RethinkDB on
  	each of them. As the bandwidth of the Internet connection in our office is
  	much lower than what is available to the EC2 nodes, we use SFTP to install
  	RethinkDB on only one of the nodes and then let that node distribute it to
  	all remaining ones.
  * We can now start running tests on the nodes: 
    * Pick a test from the list of all individual tests to be run.
    * Find a node which is not currently busy running another test. If no node
      is available, wait until a node becomes free.
    * Initiate the test on the free node. To do this, we use a wrapper script
      which we invoke and immediately background on the remote node. The
      wrapper script takes care of running the actual test and redirecting its
      output and result into specific files, which we can later retrieve
      asynchronously.
  * After repeating step 3 for all tests in the list, wait for all nodes to
  	finish their current work.
  * Collect the results of all tests from the different nodes. This works by
  	reading from the files in which our wrapper script has stored the tests'
  	results.
  * Finally, terminate the allocated nodes in EC2.

To communicate with the compute nodes, I opted for the use of
[Paramiko](http://www.lag.net/paramiko/), an implementation of SSH2 for
Python. Having direct access to the SSH2 protocol from a Python script makes
running commands remotely as well as fetching and installing files from/into
the remote systems very convenient. For allocating and terminating EC2 nodes,
we use [Boto](http://boto.s3.amazonaws.com/index.html), which provides an
interface for accessing Amazon's AWS API from within Python programs.

The results are convincing: Instead of 26 hours on a (fast) local machine,
running all of our tests takes only 4 hours when distributed across ten nodes
in EC2. By using still more nodes, the time for testing can be lowered even
further. This is very useful. Say we just made an important change to our code
and want to verify that everything works as it is supposed to. With local test
runs, this would mean waiting at least a day, even longer if our testing
machine is occupied with an earlier test run. If one of the test detects a
problem with the change and we fix it, it takes another day at least until we
can see if the fix even worked and had no other side effects. Thanks to cloud
computing and our distributed testing system, we can now initiate an arbitrary
number of test runs on demand, each of which finishes in a matter of mere
hours.

