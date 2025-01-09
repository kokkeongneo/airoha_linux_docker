#!/bin/bash
DSP_LIC_FILE="xtensa.lic"
DSP_LICSERV_PORT=6677
XTENSA_ROOT="${HOME}/airoha_sdk_toolchain"

CADENCE_LIC_HOST=lic.airoha.com.tw
CADENCE_LIC_URL=${CADENCE_LIC_HOST}/all_key_gen.sh?float_req_hostid=
INSTALL_WORK_DIR="${PWD}"
XTENSA_PATH="${XTENSA_ROOT}/xtensa"
XTENSA_VERSION_2023="RI-2023.11-linux"
XTENSA_BIN_PATH="${XTENSA_ROOT}/xtensa/${XTENSA_VERSION_2023}/XtensaTools/bin"

DSP_TOOL_PACKAGE_2023="XtensaTools_RI_2023_11_linux.tgz"

DSP_TOOL_FOLDER="${INSTALL_WORK_DIR}"
DSP_LICSERV_FOLDER="${XTENSA_ROOT}/xt_server"
SEVEN_ZA="7z"
DSP_LICSERV_PACKAGE=licserv_linux_x64_v11_15.tgz

LMUTIL="${DSP_LICSERV_FOLDER}/x64_lsb/lmutil"

BUILD_ENV_DOC_PATH_IN_SDK="<SDK_root>/mcu/doc/Airoha_IoT_SDK_for_BT_Audio_Build_Environment_Guide.pdf"




# chip name var 
chip_names=("chip_156x" "chip_157x" "chip_158x" "chip_159x")

#define var
declare -A DSP_CONFIG_PACKAGE_ARRAY
declare -A DSP_CONFIG_INSTALL_FLAG_ARRAY
declare -A DSP_CONFIG_DIR_ARRAY
declare -A BUILD_ENV_VAR_CONFIG_ARRAY

# init var # 9x have two value
DSP_CONFIG_PACKAGE_ARRAY=(
    [chip_156x]="AB1568_i64B_d32B_512K_linux_redist.tgz"
    [chip_157x]="AIR_STEREO_HIGH_G3_MINI_A_linux_redist.tgz"
    [chip_158x]="AIR_PREMIUM_G3_HIFI5_linux_redist.tgz"
    [chip_159x]="AIR_PREMIUM_G5_HIFI5_DSP0_linux_redist.tgz AIR_PREMIUM_G5_HIFI5_DSP1_linux_redist.tgz" 
)

DSP_CONFIG_INSTALLED_FLAG_ARRAY=(
    [chip_156x]="no"
    [chip_157x]="no"
    [chip_158x]="no"
    [chip_159x_dsp0]="no"
    [chip_159x_dsp1]="no"
)

DSP_CONFIG_DIR_ARRAY=(
    [chip_156x]="AB1568_i64B_d32B_512K"
    [chip_157x]="AIR_STEREO_HIGH_G3_MINI_A"
    [chip_158x]="AIR_PREMIUM_G3_HIFI5"
    [chip_159x]="AIR_PREMIUM_G5_HIFI5_DSP0 AIR_PREMIUM_G5_HIFI5_DSP1"
)

untar_dsp_config() {
DSP_CONFIG_DIR=${1}
DSP_CONFIG_PACKAGE=${2}
CHIP_NAME=${3}
if [ -d "${XTENSA_PATH}/${XTENSA_VERSION_2023}/${DSP_CONFIG_DIR_ARRAY[${CHIP_NAME}]}/" ]; then
    DSP_CONFIG_INSTALLED_FLAG_ARRAY[${CHIP_NAME}]="yes"
else
    echo "tar -zxvf ${DSP_CONFIG_PACKAGE} -C $XTENSA_PATH" >> ${XTENSA_ROOT}/install_log
    tar -zxvf "${DSP_CONFIG_PACKAGE}" -C "$XTENSA_PATH"
    if [ "$?" -ne "0" ]; then
            echo  "Error: decompress ${DSP_CONFIG_PACKAGE} fail."
            exit 1
    fi
fi
}

install_dsp_config() {
DSP_CONFIG_DIR=${1}
DSP_CONFIG_INSTALLED_FLAG=${2}
CHIP_NAME=${3}
if [ "$DSP_CONFIG_INSTALLED_FLAG" == "no" ]; then
    echo Install dsp config ${DSP_CONFIG_DIR}, may take few seconds, please wait...
    echo "Install dsp config ${DSP_CONFIG_DIR}, may take few seconds, please wait... " >> ${XTENSA_ROOT}/install_log
    echo "cd ${XTENSA_PATH}/${XTENSA_VERSION_2023}/${DSP_CONFIG_DIR}" >> ${XTENSA_ROOT}/install_log
    echo "./install --xtensa-tools ${XTENSA_ROOT}/xtensa/${XTENSA_VERSION_2023}/XtensaTools --no-default" >> ${XTENSA_ROOT}/install_log
    cd "${XTENSA_PATH}/${XTENSA_VERSION_2023}/${DSP_CONFIG_DIR}"
    ./install --xtensa-tools "${XTENSA_ROOT}/xtensa/${XTENSA_VERSION_2023}/XtensaTools" --no-default
    if [ "$?" -ne "0" ]; then
            echo  "Error: install ${CHIP_NAME} dsp config package ${DSP_CONFIG_DIR} fail. The config may already installed or have incorrect tool path"
            echo  "Error: install dsp package fail. The config may already installed or have incorrect tool path"
            echo  ""
            echo  "Something went wrong. Please remove folder ${XTENSA_ROOT} and execute ./install.sh under terminal again."
            echo  "The Cadence toolchain requires the Microsoft patches vcredist_x64.exe and vcredist_x86.exe. Download them from https://www.microsoft.com/en-us/download/details.aspx?id=40784. You must confirm the completion of patch installation before initiating the build env setup."
            exit 1;
    fi
else
    echo  "${CHIP_NAME} dsp config package ${DSP_CONFIG_DIR} package was installed."
fi
}


check_package() {
if [ ! -e "${1}" ]; then
	echo "Error: please get package ${1}, and put in folder ${INSTALL_WORK_DIR}" 
	exit 1
fi
}

#for loop to check all chip dsp config file
cd "${INSTALL_WORK_DIR}"
for chip in "${chip_names[@]}"; do
	for package in ${DSP_CONFIG_PACKAGE_ARRAY[${chip}]}; do
		if [[ ${chip} == "chip_159x" ]]; then
			IFS=' ' read -ra PACKAGES_9x <<< "${DSP_CONFIG_PACKAGE_ARRAY[${chip}]}"
			check_package ${PACKAGES_9x[0]}
			check_package ${PACKAGES_9x[1]}
		else
			echo chip is ${chip} , package is ${package}
			check_package ${package}
		fi
	done 
done





echo "BT Audio build env installation"
echo "System requirements"
echo "   - Ubuntu 18.10"



echo ""
echo "Requirements during installation (for install required Linux component and get dsp tool chain license):"
echo "   - Network connection"
echo "   - Root permission"
echo ""
echo ""
echo "Getting required Linux component"
sudo apt-get update
sudo apt-get -y install p7zip-full
sudo apt-get -y install build-essential
sudo dpkg --add-architecture i386
sudo apt-get update
sudo apt-get -y install libc6-i386 lsb 
sudo apt-get -y install curl
ls -l /lib64/ld-linux-x86-64.so.2&&sudo ln -s /lib64/ld-linux-x86-64.so.2 /lib64/ld-lsb-x86-64.so.3


#Decompress license server

echo "'"
echo Decompress license server
if [ ! -e $DSP_LICSERV_PACKAGE ]; then
	echo "Error: please get package $DSP_LICSERV_PACKAGE, and put in folder ${INSTALL_WORK_DIR}" 
	exit 1
fi

if [ ! -e "${DSP_LICSERV_FOLDER}" ]; then
        mkdir -p "${DSP_LICSERV_FOLDER}"
fi

if [ ! -e "/usr/tmp" ]; then
        sudo mkdir -p /usr/tmp
        sudo chmod a+w /usr/tmp
fi

cd "$DSP_TOOL_FOLDER"
echo "$PWD"
tar -C "${DSP_LICSERV_FOLDER}" -zxvf "$DSP_LICSERV_PACKAGE"

HOST_MAC=$(${LMUTIL} lmhostid|grep -i "The FlexNet"| sed "s/The FlexNet host ID of this machine is \"\"*\(.*\)\"\"*/\1/i"|awk '{print $1}');

cd ${INSTALL_WORK_DIR}
#gen license file
if [ ${CADENCE_LIC_HOST} ]; then
	curl ${CADENCE_LIC_URL}${HOST_MAC} > ${INSTALL_WORK_DIR}/${DSP_LIC_FILE}
	if [ "$?" -ne "0" ]; then
    echo  "Get license fail, please check network setting, installation stop"
    exit 1
  fi
  echo "Remote request Cadence license success."  		
else 
	echo "Use user assigned license file"
fi	

if [ ! -e "${DSP_TOOL_PACKAGE_2023}" ]; then
	echo "Error: please get iot sdk tool package ${DSP_TOOL_PACKAGE_2023}, and put in folder ${INSTALL_WORK_DIR}" 
	exit 1
fi

if [ ! -e "${DSP_LIC_FILE}" ]; then
	echo "Error: please get DSP license by JIRA request and change the value of \${DSP_LIC_FILE}, and put the license file in folder ${INSTALL_WORK_DIR}" 
	exit 1
fi


if [ ! -e "$XTENSA_ROOT" ]; then
        mkdir -p "${XTENSA_ROOT}"
fi

if [ ! -e "${XTENSA_PATH}" ]; then
        mkdir -p "${XTENSA_PATH}"
fi

echo "'"
echo Decompress tool chain
# unrar xtensa toolchain to $XTENSA_PATH"
if [ -d "${XTENSA_PATH}/${XTENSA_VERSION_2023}/" ]; then
   echo  "${XTENSA_PATH}/${XTENSA_VERSION_2023}/ is installed."
else
   echo tar -C ${XTENSA_PATH} -zxvf ${DSP_TOOL_PACKAGE_2023} >> ${XTENSA_ROOT}/install_log
   tar -C "${XTENSA_PATH}" -zxvf "${DSP_TOOL_PACKAGE_2023}"
   #mkdir ${XTENSA_PATH}/${XTENSA_VERSION_2023} #will delete while release version
   if [ "$?" -ne "0" ]; then
           echo  "Error: decompress ${DSP_TOOL_PACKAGE_2023} fail."
           exit 1
   fi
fi




# for every chip, untar dsp config
for chip in "${chip_names[@]}"; do
    echo "Unpacking dsp config for ${chip}..."
    if [[ ${chip} == "chip_159x" ]]; then
		IFS=' ' read -ra DSP_CONFIG_9x <<< "${DSP_CONFIG_PACKAGE_ARRAY[${chip}]}"
		IFS=' ' read -ra CONFIG_DIR_9x <<< "${DSP_CONFIG_DIR_ARRAY[${chip}]}"
        untar_dsp_config ${CONFIG_DIR_9x[0]} ${DSP_CONFIG_9x[0]} ${chip}
        untar_dsp_config ${CONFIG_DIR_9x[1]} ${DSP_CONFIG_9x[1]} ${chip}
    else
        untar_dsp_config ${DSP_CONFIG_DIR_ARRAY[${chip}]} ${DSP_CONFIG_PACKAGE_ARRAY[${chip}]} ${chip}
    fi
done


# for every chip, install dsp config
for chip in "${chip_names[@]}"; do
    echo "Unpacking dsp config for ${chip}..."
    if [[ ${chip} == "chip_159x" ]]; then
		IFS=' ' read -ra CONFIG_DIR_9x <<< "${DSP_CONFIG_DIR_ARRAY[${chip}]}"
        install_dsp_config ${CONFIG_DIR_9x[0]} ${DSP_CONFIG_INSTALLED_FLAG_ARRAY["chip_159x_dsp0"]} ${chip}
        install_dsp_config ${CONFIG_DIR_9x[1]} ${DSP_CONFIG_INSTALLED_FLAG_ARRAY["chip_159x_dsp1"]} ${chip}
    else
        install_dsp_config ${DSP_CONFIG_DIR_ARRAY[${chip}]} ${DSP_CONFIG_INSTALLED_FLAG_ARRAY[${chip}]} ${chip}
    fi
done

#start lic sever for floating lic
echo ""
cd "${DSP_LICSERV_FOLDER}"
cp "${INSTALL_WORK_DIR}/${DSP_LIC_FILE}" x64_lsb
sed -i "s/<SERVERNAME>/${HOSTNAME}/" "${DSP_LICSERV_FOLDER}/x64_lsb/${DSP_LIC_FILE}"
sed -i "s/<PORT>/$DSP_LICSERV_PORT/g" "${DSP_LICSERV_FOLDER}/x64_lsb/${DSP_LIC_FILE}"
sed -i "s/<\/PATH\/TO\/XTENSAD>/xtensad/" "${DSP_LICSERV_FOLDER}/x64_lsb/${DSP_LIC_FILE}" 
chmod a+x "${INSTALL_WORK_DIR}"/start_lic_server.sh

cp -f "${INSTALL_WORK_DIR}/start_lic_server.sh" ${XTENSA_ROOT}/

echo ""
echo Installing candence license server
"${INSTALL_WORK_DIR}"/start_lic_server.sh




sleep 5 
echo ""
echo ""
echo ""



echo "Installation complete. To begin the first build, please navigate to your SDK directory using the command below:"
echo "Example:"
echo "If your SDK is located in /home/Airoha_SDK, use the following commands:"
echo "       cd  /home/Airoha_SDK"
echo "       ./build.sh ab1592_evk earbuds_ref_design"
echo "The example is demonstrated using the ab159x series chip."
echo "For detailed build command usage for other chips or further information, please refer to the documentation in ${BUILD_ENV_DOC_PATH_IN_SDK}."
