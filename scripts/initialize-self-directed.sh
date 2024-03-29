#! /bin/bash

basedir=${HOME}/environment
cd ${basedir}

sudo yum remove -y openssl-devel
sudo yum install -y jq openssl11 openssl11-devel

export PATH=${HOME}/.local/bin:$PATH
echo "export PATH=${HOME}/.local/bin:$PATH" >> ~/.bashrc
echo "source ${HOME}/environment/credentials/*/exports" >> ~/.bashrc
pip3 install --user -U boto boto3 botocore awscli

git config --global user.name "Cloudy Builder"
git config --global user.email "developer@builder.me"
git config --global credential.helper '!aws codecommit credential-helper $@'
git config --global credential.UseHttpPath true

mkdir -p ${HOME}/environment/cmake
wget https://github.com/Kitware/CMake/releases/download/v3.21.4/cmake-3.21.4-linux-x86_64.sh
sh ./cmake-3.21.4-linux-x86_64.sh --skip-license --prefix=${HOME}/environment/cmake
echo "export PATH=${HOME}/environment/cmake/bin:$PATH" >> ~/.bashrc
rm cmake-3.21.4-linux-x86_64.sh

cd ${basedir}
repository_url=
if test -z "$1"; then
    repository_url=$(aws codecommit create-repository --repository-name myapp-core --output text --query repositoryMetadata.cloneUrlHttp)
else
    repository_url=$1
fi
git clone ${repository_url}
cd ${basedir}/myapp-core
git remote add source https://github.com/aws/aws-iot-device-sdk-embedded-C
git checkout -b main
git fetch source
git merge source/main
git push --set-upstream origin main
git submodule update --init --recursive
cd ${basedir}

#git clone https://github.com/rpcme/stm32f7-renode myapp-config

mkdir ${basedir}/myapp-core/configuration
cp ${basedir}/myapp-config/configuration/awscsdk-buildspec-build.yml ${basedir}/myapp-core/configuration
cp ${basedir}/myapp-config/configuration/awscsdk-buildspec-test.yml ${basedir}/myapp-core/configuration

mkdir ${basedir}/myapp-core/scripts
cp ${basedir}/myapp-config/scripts/da-monitor.sh ${basedir}/myapp-core/scripts

cd ${basedir}/myapp-core
git add configuration/awscsdk-buildspec-build.yml configuration/awscsdk-buildspec-test.yml scripts/da-monitor.sh
git commit -m"automation artifacts" configuration/awscsdk-buildspec-build.yml configuration/awscsdk-buildspec-test.yml scripts/da-monitor.sh
git push

cd ${basedir}
mkdir ${basedir}/credentials
mydevice=$(uuidgen)
myapp-config/scripts/create-iot-credential.sh \
    -F \
    -d "$2" \
    -t "$3" \
    -n awscsdk-mqtt-policy-${mydevice} \
    -f ${basedir}/myapp-config/configuration/awscsdk-iotcore-policy.json \
    -o ${basedir}/credentials \
    -s "$4" \
    -S \
    > ${basedir}/credentials/log

#echo creating deployment bucket...
#${basedir}/myapp-config/scripts/create-deploy-to-bucket.sh
echo Done.
