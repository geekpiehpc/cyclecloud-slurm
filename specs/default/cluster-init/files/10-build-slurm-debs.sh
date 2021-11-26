#!/usr/bin/env bash

install_ofed () {
    mkdir /lib/modules
    ln -s ../../lib/linux-kbuild-4.19/scripts  /usr/src/linux-headers-4.19.0-10-common/scripts
    ln -s ../../lib/linux-kbuild-4.19/tools  /usr/src/linux-headers-4.19.0-10-common/tools

    mkdir -p /install_ofed && cd /install_ofed
    apt install -yq apt-utils gcc-8 curl libcap2
    curl -LO https://content.mellanox.com/ofed/MLNX_OFED-5.4-3.0.3.0/MLNX_OFED_LINUX-5.4-3.0.3.0-ubuntu20.04-x86_64.tgz
    apt install -y bzip2 python3-distutils pkg-config quilt python3 dh-autoreconf build-essential dh-python debhelper make gcc
    tar -xvf MLNX_OFED_LINUX-5.4-3.0.3.0-ubuntu20.04-x86_64.tgz
    cd MLNX_OFED_LINUX-5.4-3.0.3.0-ubuntu20.04-x86_64
    ./mlnxofedinstall --add-kernel-support --user-space-only --without-fw-update
}

change_mirror () {
    sed -i 's!http://archive.ubuntu.com/!http://mirrors.tuna.tsinghua.edu.cn/!g' /etc/apt/sources.list
    apt update
}

build_slurm () {
    apt install -yq build-essential devscripts debian-keyring equivs debmake libpmix2 hwloc
    mkdir ~/build-slurm && cd ~/build-slurm
    dget http://archive.ubuntu.com/ubuntu/pool/universe/s/slurm-wlm/slurm-wlm_20.11.7+really20.11.4-2.dsc
    cd slurm-wlm-20.11.7+really20.11.4/
    sed -i 's#--with-pmix=/usr/lib/$(DEB_HOST_MULTIARCH)/pmix2#--with-pmix=/usr/lib/$(DEB_HOST_MULTIARCH)/pmix#g' debian/rules
    sed -i 's#dh_shlibdeps -O#dh_shlibdeps --dpkg-shlibdeps-params=--ignore-missing-info -O#g' debian/rules

    git clone https://github.com/Azure/cyclecloud-slurm ~/cyclecloud-slurm
    rsync -a ~/cyclecloud-slurm/specs/default/cluster-init/files/JobSubmitPlugin/. src/plugins/job_submit/cyclecloud/
    pushd src/plugins/job_submit/cyclecloud/
    mv Makefile.in.v19 Makefile.in
    popd
    sed -i 's#src/plugins/job_submit/Makefile#src/plugins/job_submit/Makefile\n\t\t src/plugins/job_submit/cyclecloud/Makefile#g' configure.ac
    sed -i 's#require_timelimit \\\n\tthrottle#require_timelimit \\\n\tcyclecloud\n\tthrottle#g' src/plugins/job_submit/Makefile.am

    dpkg-source --commit . Cyclecloud

    mk-build-deps -ir --tool='apt -o Debug::pkgProblemResolver=yes -yq' debian/control

    # gpg --import --batch /kiruya.key
    # apt-key adv --keyserver keyserver.ubuntu.com --recv-keys [key]
    # debuild -k[key]  -p'gpg --yes --no-tty --passphrase [pass] --pinentry-mode loopback'
    debuild -us -uc
}

build_slurm()
