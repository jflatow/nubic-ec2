========================================
`NUBIC` Guide to `Amazon Machine Images`
========================================
:Author: Jared Flatow
:Date:   August, 2008

Overview
========

In this guide we aim to provide the necessary background for accessing and running the `Amazon Machine Images` (`AMI`_\s) maintained by our group: the `Northwestern University Biomedical Informatics Center` (`NUBIC`_).
An `AMI` is an encrypted snapshot of the state of a virtual machine, specifically meant for running on the `Amazon Elastic Computing Cloud` (`EC2`_).
Most of the information contained in this document is not specific to any single `AMI`. 
Rather, this guide is intended to serve as a self-contained manual on using the `NUBIC` images for those with or without any prior knowledge on the subject.
Links to other resources on specific topics are provided and should be followed for those desiring a more extensive view of how the several pieces fit together.
Much of the contents provided here can be found amongst the other resources referenced, however the goal here is to provide a start to finish guide for working with the `NUBIC` images.

.. _AMI: http://docs.amazonwebservices.com/AWSEC2/2008-02-01/DeveloperGuide/index.html?glossary.html
.. _NUBIC: http://www.nucats.northwestern.edu/centers/nubic/index.html
.. _EC2: http://aws.amazon.com/ec2

What is an `AMI`?
=================

In order to understand what an `AMI` is, it is helpful to have some background on *virtualization* and *virtual machines*.
In this guide, when we speak of virtualization, we are referring to the process of running a complete operating system on a virtual machine.
The virtual machine itself is provided by another piece of software, generally called a virtual machine monitor (or sometimes hypervisor).
A virtual machine emulates a hardware architecture and bootloading system such that a guest operating system can be started and run within it.
Because the virtual machine itself is running inside another piece of software, the state of the system at any given time can be captured by the container system and stored as a file.
This file is a snapshot of the machine's state, and can be treated as either data (e.g. transferred across a network, copied to another file, saved to disk, etc.), or as a program (e.g. resuming execution inside a virtual machine).
An `AMI` is precisely one of these files, only it is specifically designed to be run inside of `Amazon`\'s virtualization platform, the `EC2`. [*]_
We have created several `AMI`\s, all of them built on top of an `Ubuntu`_ operating system, and each with specialized software and libraries installed.
By starting up an *instance* of one of these images on the `EC2`, one can gain access to a system with pre-configured capabilities. [*]_
The concepts and techniques discussed in this manual apply to all `AMI`\s.

.. [*] `Amazon` actually uses `Xen`_ virtualization technology running on a cluster of commodity `Linux`_ machines. 
.. [*] The `AMI` does not store the memory state of the virtual machine, thus the machine is effectively rebooted every time an instance is created.

.. _Xen: http://www.xen.org
.. _Linux: http://www.linux.org
.. _Ubuntu: http://www.ubuntu.com

Getting Started Using `Amazon Web Services`
===========================================

In order to use the `NUBIC` images, it is first necessary to register for the `Amazon Web Services` (`AWS`).  
`Amazon` charges for the time their machines spend running instances.
They also allow customers to persist data inside their network for a specified rate. [*]_

.. important:: 
   `Amazon` provides detailed instructions on `how to register`_ for the `AWS` and a `Getting Started Guide`_ for using the `EC2` service.
   At this point, it is necessary to read and follow these instructions in order to continue and learn how to use the `NUBIC` images.

.. [*] All `AMI`\s must be kept in this type of storage.

.. _how to register: http://aws.amazon.com
.. _Getting Started Guide: http://docs.amazonwebservices.com/AWSEC2/2008-02-01/GettingStartedGuide/?ref=get-started

Launching an Instance of a `NUBIC` Image
========================================

Launching an instance of a `NUBIC` image is a nearly identical process to that you followed in the `Getting Started Guide`.
The only difference, is that instead of specifying the `ami-id` for `Amazon`\'s public `Getting Started` image, you will specify the identifier of the `NUBIC` image you wish to run.

.. attention:: You will need to have followed the `Getting Started Guide` in order to obtain the `ec2-api-tools`, and to set them up such that you have access to the `EC2` service.

You can obtain the `ami-id` for the `mapreduce_32bit` image by running the command:

::

        ec2-describe-images -a | grep nubic-images/mapreduce_32bit | cut -f 2

Once you have obtained the ``ami-id`` of the image, you can start up an instance of it:

::

        ec2-run-instances ami-id -k keypair_name

.. tip:: The commands ``ec2-describe-images`` and ``ec2-run-instances`` can also be run with their respective shortcut command names: ``ec2dim`` and ``ec2run``
   
.. tip:: 
   For our purposes it is fine to use the same ``keypair_name`` as you created in the `Getting Started Guide`.
   We will use the default ``gsg-keypair`` from now on.

.. warning:: 
   Remember to shut down the instance, if you are stopping here.
   If not, we will continue to use the instance we have just created, and terminate it once we are finished.

Connecting to the Instance
--------------------------

Now that you have an instance running, you can treat it as your own private server.

::

        ec2-describe-instances

Will tell you the status of all your instances.
Wait a few moments for the instance to boot up.
You will know it has booted when the output of the ``ec2-describe-instances`` command indicates that the instance is no longer pending, and has assigned it an ``amazonaws.com`` address.
We will refer to this address as the ``amazon_instance_address``

.. tip:: The command ``ec2-describe-instances`` can also be run with the ``ec2din`` shortcut.

All we have to do now is ``ssh`` into it:

::

        ssh -i id_rsa-gsg-keypair -Y -o StrictHostKeyChecking=no root@amazon_instance_address


.. important:: In order to use the graphical capabilities of `X11` on the `EC2` instance, you will need to enable `X11` forwarding with the ``-Y`` option.

.. tip:: 
   Sometimes you will be assigned the same ``amazon_instance_address`` as one you have previously been assigned.
   In these cases it will be necessary to specify the ``-o StrictHostKeyChecking=no`` option, otherwise it is not needed.
   If you try to connect and get an error and a message about man-in-the-middle attacks, try supplying this option.

Copying Files to and from the Instance
--------------------------------------

The simplest way to copy files to and from the instance, is by using ``scp``.
``scp`` uses ``ssh`` to transfer data across the network, so authentication works exactly the same way.
Assuming we have started an instance whose external address is ``amazon_instance_address``, we can copy a file off of it like so:

::

        scp -i id_rsa-gsg-keypair root@amazon_instance_address:/path/to/file /local/path/to/copy/file/to

If we want to copy an entire directory, make sure to use the ``-r`` option:

::

        scp -r -i rsa-gsg-kepair root@amazon_instance_address:/path/to/directory /local/path/to/copy/directory/to

.. warning:: Remember that if you create files on the instance they will disappear once the instance is terminated unless you explicity copy them somewhere off of the instance, like to your local machine.

Terminating the Instance
------------------------

At this point we can log off and shutdown the instance.
From our local machine's `Bash` prompt, we can find out the ``instance_id``\'s of our running instances and then terminate them:

::

        ec2din
        ec2-terminate-instances instance_id

.. warning:: It is important to remember to terminate instances whenever you are finished using them, otherwise your account will continue to be charged while the instances are running.
