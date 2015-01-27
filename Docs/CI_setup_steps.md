# Steps to Set Up the Testing Environment on Ubuntu 14.04
===================================================================
1. Install Jenkins
>wget -q -O - https://jenkins-ci.org/debian/jenkins-ci.org.key | sudo apt-key add -
>sudo sh -c 'echo deb http://pkg.jenkins-ci.org/debian binary/ > /etc/apt/sources.list.d/jenkins.list'
>sudo apt-get update
>sudo apt-get install jenkins

From: https://wiki.jenkins-ci.org/display/JENKINS/Installing+Jenkins+on+Ubuntu

2. Install Virtualbox.
>sudo echo "deb http://download.virtualbox.org/virtualbox/debian trusty contrib" >> /etc/apt/sources.list
>wget -q https://www.virtualbox.org/download/oracle_vbox.asc -O- | sudo apt-key add -
>sudo apt-get update
>sudo apt-get install virtualbox-4.3
>sudo apt-get install dkms

From: https://www.virtualbox.org/wiki/Linux_Downloads

3. Install Vagrant.
>wget https://dl.bintray.com/mitchellh/vagrant/vagrant_1.7.2_x86_64.deb
>sudo dpkg -i vagrant_1.7.2_x86_64.deb

4. Install Github plugin via the web interfact.
  1. Go to "Manage Jenkins" --> "Manage plugins"
  2. Find "GitHub Plugin", check it, and click "Install without restart"
  3. If (after installation) some dependencies require a restart, check the box below the install progress to restart Jenkins.

5. Make a dedicated user to run Jenkins builds
>adduser jenkins
