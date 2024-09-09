#!/bin/bash
# jbenninghoff@maprtech.com 2013-Mar-20  vi: set ai et sw=3 tabstop=3:

# Assumes clush is installed, available from EPEL repository
# A sequence of maprcli commands to probe installed system configuration
# Log stdout/stderr with 'mapr-audit.sh |& tee mapr-audit.log'

#node='ssh -qtt lgpbd1000' #Single node to run maprcli commands from
parg='-B -g all' # Assuming clush group 'all' is configured to reach all nodes
[ $(id -u) -ne 0 ] && SUDO=sudo
sep='====================================================================='
#msg="what ever"; printf "%s%s \n" "$msg" "${sep:${#msg}}"
verbose=false
while getopts ":v" opt; do
  case $opt in
    v) verbose=true ;;
    \?) echo "Invalid option: -$OPTARG" >&2; exit ;;
  esac
done

echo ==================== MapR audits ================================
date; echo $sep
msg="Hadoop Jobs Status"; printf "%s%s \n" "$msg" "${sep:${#msg}}"
${node:-} hadoop job -list; echo $sep
echo MapR Dashboard
${node:-} ${SUDO:-} maprcli dashboard info -json; echo $sep
echo MapR Alarms
${node:-} ${SUDO:-} maprcli alarm list -summary true; echo $sep
echo MapR Services
${node:-} ${SUDO:-} maprcli node list -columns hostname,svc
echo zookeepers:
${node:-} ${SUDO:-} maprcli node listzookeepers; echo $sep
echo MapR map and reduce slots
${node:-} ${SUDO:-} maprcli node list -columns hostname,cpus,ttmapSlots,ttReduceSlots; echo $sep
echo MapR Volumes
${node:-} ${SUDO:-} maprcli volume list -columns numreplicas,mountdir,used,numcontainers,logicalUsed; echo $sep
echo MapR Storage Pools
clush $parg ${SUDO:-} /opt/mapr/server/mrconfig sp list -v; echo $sep
echo MapR env settings
clush $parg ${SUDO:-} grep ^export /opt/mapr/conf/env.sh
echo mapred-site.xml checksum
clush $parg ${SUDO:-} sum /opt/mapr/hadoop/hadoop-0.20.2/conf/mapred-site.xml; echo $sep
echo MapR Central Configuration setting
clush $parg ${SUDO:-} grep centralconfig /opt/mapr/conf/warden.conf
echo MapR Central Logging setting
clush $parg ${SUDO:-} grep ROOT_LOGGER /opt/mapr/hadoop/hadoop-0.20.2/conf/hadoop-env.sh
echo MapR roles per host
clush $parg ${SUDO:-} ls /opt/mapr/roles
echo MapR packages installed
clush $parg ${SUDO:-} 'rpm -qa | grep mapr-'

#$node maprcli dump balancerinfo | sort | awk '$1 == prvkey {size += $9}; $1 != prvkey {if (prvkey!="") print size; prvkey=$1; size=$9}'
#echo MapR disk list per host
[ "$verbose" == "true" ] && clush $parg ${SUDO:-} 'maprcli disk list -output terse -system 0 -host $(hostname)'
[ "$verbose" == "true" ] && clush $parg ${SUDO:-} '/opt/mapr/server/mrconfig dg list | grep -A4 StripeDepth'
[ "$verbose" == "true" ] && ${node:-} ${SUDO:-} maprcli dump balancerinfo | sort -r; echo $sep
[ "$verbose" == "true" ] && ${node:-} ${SUDO:-} hadoop conf -dump | sort; echo $sep
[ "$verbose" == "true" ] && ${node:-} ${SUDO:-} maprcli config load -json; echo $sep
# TBD:
# check all hadoop* packages installed

# set verbose to false, true or full
# Use new bash case switch/fallthrough using ;& instead of ;;
# case $verbose in
#   false)
#     date; echo $sep ...
#     ;&
#   true)
#     maprcli ...
#     ;&
#   full)
#     clush ...
#     ;&
# esac

