#! /bin/bash

OINK_CODE='place for your oink code'

if [ "${OINK_CODE}" == 'place for your oink code'   ]; then
   echo "  ================================================="
   echo "   This script need your personal \"oink code\""
   echo "   To get oink code, register with www.snort.org"
   echo "   Then put your oink code as variable OINK_CODE in file:"
   echo "   `pwd`/snort_install_config.sh"
   echo "  ================================================="
   exit 0
fi
