#!/bin/bash

if [ ! -z "`which yum`" ]; then

    # On rpm-based system, use yum to install rubygems and related packages for building native
    # extensions

    for pkg in rubygems20 gcc-c++ ruby20-devel make autoconf automake; do
        yum list installed $pkg &> /dev/null
        if [ $? != 0 ]; then
            yum -y install $pkg
        fi
    done

elif [ ! -z "`which apt-get`" ]; then
    # On debian-like system, use apt-get to install

    for pkg in ruby2.0-dev ruby2.0 make autoconf g++; do
        aptitude show $pkg | grep -q 'State: installed' 
        if [ $? != 0 ]; then
            apt-get -y install $pkg
        fi
    done
fi

# Now, we can install the required gems
for gem in chef ohai librarian-chef io-console; do
    gem2.0 list | grep -q $gem
    if [ $? != 0 ]; then
        gem2.0 install $gem

        if [ $? != 0 ]; then
            echo "Failed to install required gems. Cannot continue with deployment"
            exit 1
        fi
    fi
done
