#! /bin/bash

#------------------------------------------------------------------------------
#Copyright (c) 2014 roundcafe
#
#Permission is hereby granted, free of charge, to any person obtaining a copy
#of this software and associated documentation files (the "Software"), to deal
#in the Software without restriction, including without limitation the rights
#to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#copies of the Software, and to permit persons to whom the Software is
#furnished to do so, subject to the following conditions:
#
#The above copyright notice and this permission notice shall be included in all
#copies or substantial portions of the Software.
#
#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#SOFTWARE.
#--------------------------------------------------------------------------------


RPMS_DIR='/root/rpmbuild/RPMS/x86_64'
RPM_TYPE=x86_64.rpm

f(){
error_code=$?
echo "ERROR: ${error_code}"
echo "The command executing at the time of the error:"
echo "$BASH_COMMAND"
echo "on line ${BASH_LINENO[0]}"

#error handling

exit ${error_code}
}

trap f ERR

function install_rpm(){
trap f ERR
PROG=$1
RPM_FILE=$2
RPM_FILE_TYPE=$3
PROG_VER=$4
RPM_FILE_URL=$5
RPM_FILE_MD5=$6
if rpm -qa | grep -qw ${PROG}; then
   echo "`rpm -qa | grep -w ${PROG}` is installed"
else
   case ${RPM_FILE} in
      '')
         yum install ${PROG}
	 ;;
      *)
         case ${RPM_FILE_TYPE} in
            src)
	        if [ ! -f ${RPM_FILE}.md5 ]; then
		   if [ ${RPM_FILE_MD5} == '' ]; then
		      echo downloading ${RPM_FILE}.md5
		      wget ${RPM_FILE_URL}/${RPM_FILE}.md5 -O ${RPM_FILE}.md5
		   else
		      echo ${RPM_FILE_MD5}'  '${RPM_FILE}>${RPM_FILE}.md5
		   fi
	       fi
	       if [ ! -f ${RPM_FILE}.md5 ]; then
		   echo "ERROR:"; echo "missing file: ${RPM_FILE}.md5"; echo ""; exit 0
	       fi     
	       if [ ! -f ${RPM_FILE} ]; then
		   echo downloading ${RPM_FILE}
		   wget ${RPM_FILE_URL}/${RPM_FILE} -O ${RPM_FILE}
	       fi   
	       md5sum --quiet -c ${RPM_FILE}.md5
	       rpm -K ${RPM_FILE}
               rpmbuild --rebuild ${RPM_FILE}
               yum install ${RPMS_DIR}/${PROG}-${PROG_VER}.${RPM_TYPE}
               ;;
	    *)
	       rpm -K ${ROM_FILE}
	       yum install ${RPM_FILE}
	 esac
   esac
fi
}


function edit_config_file(){
trap f ERR 
FILE_NAME=$1
PATERN_T=$2
PATERN_R=$3
if [[ -f ${FILE_NAME} ]]; then
   if [ "`grep -E \"${PATERN_T}\" ${FILE_NAME}`" == "" ]; then
      echo "${PATERN_R}" >> ${FILE_NAME}
   else
      echo "FILE: ${FILE_NAME}    at line: `sed -n -re "/${PATERN_T}/{=;p}" ${FILE_NAME}`"
      sed -i -re "s/${PATERN_T}/${PATERN_R}/" ${FILE_NAME}
      sed -n -re "/${PATERN_T}/p" ${FILE_NAME}
      echo "------------------------"
   fi
fi
}

function install_required_rpm_files(){
trap f ERR 
install_rpm gcc
install_rpm flex
install_rpm bison
install_rpm zlib
install_rpm zlib-devel
install_rpm libpcap
install_rpm libpcap-devel
install_rpm pcre
install_rpm pcre-devel
install_rpm libdnet
install_rpm libdnet-devel
install_rpm tcpdump
install_rpm daq daq-2.0.2-1.src.rpm src '2.0.2-1' 'https://www.snort.org/dl/snort-current' '68293f5a9f95943910edb60b387d39fc'
install_rpm snort snort-2.9.6.0-1.src.rpm src '2.9.6.0-1' 'https://www.snort.org/dl/snort-current' '617d1d59a3adf2d218bd6649b8f4a2b4'
}

#install_required_rpm_files


SNORT_RULES_URL=https://www.snort.org/reg-rules
OINK_CODE='place for your oink code'
SNORT_RULES_FILE='snortrules-snapshot-2960.tar.gz'

#SNORT_RULES_FILE_MD5='557b096836c2546e93b0061ba5b51680'
#echo ${SNORT_RULES_FILE_MD5}'  '${SNORT_RULES_FILE}>${SNORT_RULES_FILE}.md5

if [ ! -f ${SNORT_RULES_FILE}.md5 ]; then
   wget ${SNORT_RULES_URL}/${SNORT_RULES_FILE}.md5/${OINK_CODE} -O ${SNORT_RULES_FILE}.md5
   echo '  '${SNORT_RULES_FILE}>>${SNORT_RULES_FILE}.md5
fi

if [ ! -f ${SNORT_RULES_FILE}.md5 ]; then
   echo "ERROR:"; echo "missing file: ${SNORT_RULES_FILE}.md5"; echo ""; exit 0
fi     
     
if [ ! -f ${SNORT_RULES_FILE} ]; then
   echo downloading ${SNORT_RULES_FILE}
   wget ${SNORT_RULES_URL}/${SNORT_RULES_FILE}/${OINK_CODE} -O ${SNORT_RULES_FILE}
fi   
md5sum -c ${SNORT_RULES_FILE}.md5

if [ -d ~/snort ]; then rm -rf ~/snort; fi
mkdir -p ~/snort
tar xzf ${SNORT_RULES_FILE} -C ~/snort
chown -R root.root ~/snort

cp -r /etc/snort ~/etc_snort-`date '+%F_%T'`

mv -f ~/snort/etc/* /etc/snort/
rm -rf /etc/snort/rules /etc/snort/preproc_rules /etc/snort/so_rules
mv -i ~/snort/rules ~/snort/preproc_rules ~/snort/so_rules /etc/snort/




edit_config_file '/etc/snort/snort.conf'     '^ipvar HOME_NET($| .*$)'              'ipvar HOME_NET 10.0.2.25\/24'
edit_config_file '/etc/snort/snort.conf'     '^ipvar EXTERNAL_NET($| .*$)'          'ipvar EXTERNAL_NET !$HOME_NET'
edit_config_file '/etc/snort/snort.conf'     '^var RULE_PATH($| .*$)'               'var RULE_PATH \/etc\/snort\/rules'
edit_config_file '/etc/snort/snort.conf'     '^var SO_RULE_PATH($| .*$)'            'var SO_RULE_PATH \/etc\/snort\/so_rules'
edit_config_file '/etc/snort/snort.conf'     '^var PREPROC_RULE_PATH($| .*$)'       'var PREPROC_RULE_PATH \/etc\/snort\/preproc_rules'
edit_config_file '/etc/snort/snort.conf'     '^var WHITE_LIST_PATH($| .*$)'         'var WHITE_LIST_PATH \/etc\/snort\/rules'
edit_config_file '/etc/snort/snort.conf'     '^var BLACK_LIST_PATH($| .*$)'         'var BLACK_LIST_PATH \/etc\/snort\/rules'

edit_config_file '/etc/snort/snort.conf'     '^ipvar DNS_SERVERS($| .*$)'           'ipvar DNS_SERVERS 192.168.77.1'
edit_config_file '/etc/snort/snort.conf'     '^ipvar SMTP_SERVERS($| .*$)'          'ipvar SMTP_SERVERS $HOME_NET'
edit_config_file '/etc/snort/snort.conf'     '^ipvar HTTP_SERVERS($| .*$)'          'ipvar HTTP_SERVERS $HOME_NET'

edit_config_file '/etc/snort/snort.conf'     '^dynamicpreprocessor directory($| .*$)'  'dynamicpreprocessor directory \/usr\/lib64\/snort-2.9.6.0_dynamicpreprocessor\/'
edit_config_file '/etc/snort/snort.conf'     '^dynamicengine($| .*$)'                  'dynamicengine \/usr\/lib64\/snort-2.9.6.0_dynamicengine\/libsf_engine.so.0'
edit_config_file '/etc/snort/snort.conf'     '^dynamicdetection directory($| .*$)'     'dynamicdetection directory \/etc\/snort\/so_rules\/precompiled\/RHEL-6-0\/x86-64\/2.9.6.0\/'

#edit_config_file '/etc/snort/snort.conf'     '^($| .*$)'              ''
#edit_config_file '/etc/snort/snort.conf'     '^($| .*$)'              ''
#edit_config_file '/etc/snort/snort.conf'     '^($| .*$)'              ''
#edit_config_file '/etc/snort/snort.conf'     '^($| .*$)'              ''
#edit_config_file '/etc/snort/snort.conf'     '^($| .*$)'              ''
#edit_config_file '/etc/snort/snort.conf'     '^($| .*$)'              ''

touch /etc/snort/rules/white_list.rules
touch /etc/snort/rules/black_list.rules

chown -R snort:snort /etc/snort

SELINUX_STATUS=`getenforce`

if [ ${SELINUX_STATUS} == 'Enforcing' ]; then
   echo "SELINUX = ${SELINUX_STATUS}"
   chcon -R system_u:object_r:snort_etc_t:s0 /etc/snort
   chcon -R system_u:object_r:lib_t:s0 /etc/snort/so_rules/precompiled/RHEL-6-0/
fi

#Now, you should be able to start Snort, i.e.

    # /etc/init.d/snortd start
 #   Starting snort: Spawning daemon child...
 #   My daemon child 1904 lives...
 #   Daemon parent exiting (0)                         [  OK  ]

