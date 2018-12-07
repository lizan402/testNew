

#判断是否输入scheme
if [ $# -lt 1 ]; then
	echo "Error! Should enter the scheme!"
	exit 0
else
	scheme=$1
fi

if [ $scheme == "vpsp_dev" ]; then
    profile="vpsparents.adhoc.dis"
    apikey="0c0c36494ffcf2f9c8f7e170e59a84d3"
    userkey="c16cf41d21807c8dc47ce5ada3efe764"
elif [ $scheme == "vpsp_qdev" ];then
    profile="vpsparents.adhoc.dis"
    apikey="b75e54a8c0566af0fe6c4a47acb5ecd6"
    userkey="e1dbaef64c3e0b2417c7d38b5f46603f"
elif [ $scheme == "vpsp_uat" ];then
    profile="vpsparents.adhoc.dis"
    apikey="4a17488b2ee639b857ddee99181bc9cc"
    userkey="c31f4813418cb09af53a19d69781d24d"

elif [ $scheme == "vps_dev" ];then
    profile="VPS.adhoc"
    apikey="0c0c36494ffcf2f9c8f7e170e59a84d3"
    userkey="c16cf41d21807c8dc47ce5ada3efe764"
elif [ $scheme == "vps_qdev" ];then
    profile="VPS.adhoc"
    apikey="b75e54a8c0566af0fe6c4a47acb5ecd6"
    userkey="e1dbaef64c3e0b2417c7d38b5f46603f"
elif [ $scheme == "vps_uat" ];then
    profile="VPS.adhoc"
    apikey="4a17488b2ee639b857ddee99181bc9cc"
    userkey="c31f4813418cb09af53a19d69781d24d"
fi

echo "profile = $profile , apikey = $apikey ,userkey = $userkey"

#清理项目
# xcodebuild -scheme $scheme clean
if [[ ! $? -eq 0 ]]; then
	exit 0
fi

#   日期和时间
buildDay=$(date +%Y-%m-%d)
buildTime=$(date +%H.%M)

#   判断是否含有工程
project=false
workspace=false
dir=$(ls -l . |awk '/^d/ {print $NF}')
for i in $dir
do
	if [[ $i =~ \.xcworkspace$ ]]; then
		workspace=true
		break
    fi
    if [[ $i =~ \.xcodeproj$ ]]; then
    	project=true
    fi
done 

IFS_backup=$IFS
IFS=$(echo -en "\n\b")
buildPath="/Users/`whoami`/Developer/Xcode/Archives/${buildDay}/${scheme} ${buildDay} ${buildTime}.xcarchive"
IFS=$IFSBU


#	打包
if $workspace; then

	xcodebuild -scheme $scheme -workspace *.xcworkspace -archivePath $buildPath archive
elif $project; then
	xctool -scheme $scheme archive -archivePath $buildPath

	# xcodebuild -target <target> -configuration <configuration> -showBuildSettings
	# xcodebuild -scheme $scheme -workspace xxx.xcworkspace build

fi

if [[ ! $? -eq 0 ]]; then
	exit 0
fi

#   判断并创建ipa输出路径
ipaPath="./ipa/${buildDay}"
if [[ ! -d "$ipaPath" ]]; then
	mkdir -p "$ipaPath"
fi
ipaName="${ipaPath}/${scheme} ${buildDay} ${buildTime}.ipa"

#   输出ipa文件
xcodebuild -exportArchive -exportFormat IPA -archivePath ${buildPath} -exportPath ${ipaName} -exportProvisioningProfile $profile

if [[ ! $? -eq 0 ]]; then
	exit 0
fi

#上传pgy
curl -F "file=@${ipaName}" -F "uKey=${userkey}" -F "_api_key=${apikey}" https://qiniu-storage.pgyer.com/apiv1/app/upload
