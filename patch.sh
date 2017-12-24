#!/bin/bash
function __check_md5() {
    __print_header "Check resource md5"
    md5=`__get_prop $config "resource.md5"`
    thismd5=`md5sum $resource | head -c 32`
    echo "MD5: $md5"
    echo "MD5: $thismd5"
    [ "$md5"x != "$thismd5"x ] && __error "ERROR: resource md5 mismatch \"$md5\" != \"$thismd5\""
}

function __check_version() {
    __print_header "Check patch version"
    version_from=`__get_prop $config "version.from"`
    version_filter=`__get_prop $config "version.filter"`
    thisversion=`__extract_version $install_dir $version_filter`
    thisversionmd5=`echo $thisversion | md5sum | head -c 32`
    echo "install.dir: $install_dir"
    echo "version.filter: $version_filter"
    echo "version.from: $version_from"
    echo "local system: $thisversionmd5"
    [ "$version_from"x != "$thisversionmd5"x ] && __error "ERROR: version mismatch \"$version_from\" != \"$thisversionmd5\""
}

function __check_changelock() {
    __print_header "Check changing lock"
    lockfile=`find $install_dir -name 'change.lock'`
    [ -n "$lockfile" ] && echo "ERROR: lock file exist!" && __error "Start: `cat $lockfile`"
    echo "Not locked!"
    __lock
}

function __stop_server() {
    __print_header "Stop system modules"
    modules=`$install_dir/hanctl status | grep -v mysql |  awk '{print $1}' | tr "\n" " "`
    echo "$install_dir/hanctl stop $modules"
    $install_dir/hanctl stop $modules
    #[[ $? ]] && __error "Stop server failed"
}

function __backup_all() {
    __print_header "Backup current system"
    backup_dir=`__get_prop $config "backup.dir"`
    echo "backup.dir: "${backup_dir}
    if [ -d $backup_dir ];then
        echo "remove existing backup folder..."
        rm -rf $backup_dir
    fi
    backup_include=`__get_prop $config "backup.include"`
    for i in ${backup_include}
    do
        dir_from=${i//'${install.dir}'/$install_dir}
        dir_to=${i//'${install.dir}'/"$backup_dir$install_dir"}
        echo "cp $dir_from $dir_to"
        __copy $dir_from $dir_to
    done
}

function __lock() {
    echo "locking..."
    date > $lock
}

function __unlock() {
    rm -f $lock
}

function __get_prop() {
    grep "^$2=" $1 | head -n 1 | awk -F '=' '{print $2}' | tr -d "\n"
}

function __success() {
    __print_header "Apply patch OK!"
}

function __error() {
    echo $1
    __print_header "Rollback patch"
    __unlock
    exit 1
}

function __copy() {
    if [ -d $1 ];then
        echo "mkdir -p $2 && cp -rf $1 $_"
        mkdir -p $2 && cp -rf $1 $_
        [[ $? -ne 0 ]] && __error "ERROR: backup failed"
    else
        tar=${2%/*}/
        echo "mkdir -p $2 && cp -a $1 $_"
        mkdir -p $2 && cp -a $1 $_
        [[ $? -ne 0 ]] && __error "ERROR: backup failed"
    fi
}

function __extract_version() {
    # extract backend commitid & buildnum
    [[ "$2" =~ "backend" ]] && echo `__extract_commitid_and_buildnum $1 1 "backend"`
    # extract frontend commitid & buildnum
    [[ "$2" =~ "frontend" ]] && echo `__extract_commitid_and_buildnum $1 2 "frontend"`
    # extract cep commitid & buildnum
    [[ "$2" =~ "furion" ]] && echo `__extract_commitid_and_buildnum $1/cep 1 "furion"`
    # extract misc commitid & buildnum
    [[ "$2" =~ "rubick" ]] && echo `__extract_commitid_and_buildnum $1/misc 1 "rubick"`
    # extract alg commitid & buildnum
    [[ "$2" =~ "darchrow" ]] &&  echo `__extract_commitid_and_buildnum $1/alg 1 "darchrow"`
}

function __extract_commitid_and_buildnum() {
    buildnum=`grep buildnum $1/version.properties 2>/etc/null | sed -n $2p | awk -F '[= ]*' '{print $2}' | tr -d "\n"`
    [ -n "$buildnum" ] && printf "$3.buildnum=$buildnum\n"
    commitid=`grep commitid $1/version.properties 2>/etc/null | sed -n $2p | awk -F '[= ]*' '{print $2}' | tr -d "\n"`
    [ -n "$commitid" ] && printf "$3.commitid=$commitid\n"
}

function __print_header() {
    printf "\n%-20s %-20s %-20s\n" "====================" "$1" "===================="
}

export LANG=en
resource="resource.tar.gz"
config="config.properties"
install_dir=`__get_prop $config "install.dir"`
lock="change.lock"

__check_md5
__check_version
__check_changelock
__stop_server
__backup_all

__success