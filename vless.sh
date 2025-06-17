#!/bin/bash
export LANG=en_US.UTF-8
export nix=${nix:-''}
[ -z "$nix" ] && sys='主流VPS-' || sys='容器NIX-'
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "甬哥Github项目 ：github.com/yonggekkk"
echo "甬哥Blogger博客 ：ygkkk.blogspot.com"
echo "甬哥YouTube频道 ：www.youtube.com/@ygkkk"
echo "${sys}ArgoSB真一键无交互脚本 - VLESS Mod"
echo "当前版本：25.5.10 测试beta7版 (Mod VLESS)"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
export UUID=${uuid:-''}
export port_vl_ws=${vlpt:-''} # Changed variable name for VLESS port
export ARGO_DOMAIN=${agn:-''}
export ARGO_AUTH=${agk:-''}
if [ -z "$nix" ]; then
[[ $EUID -ne 0 ]] && echo "当前为主流VPS专用脚本模式，必须以root模式运行。请在脚本前加上 nix=y 切换为容器NIX模式运行" && exit
if [[ -f /etc/redhat-release ]]; then
release="Centos"
elif cat /etc/issue | grep -q -E -i "alpine"; then
release="alpine"
elif cat /etc/issue | grep -q -E -i "debian"; then
release="Debian"
elif cat /etc/issue | grep -q -E -i "ubuntu"; then
release="Ubuntu"
elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
release="Centos"
elif cat /proc/version | grep -q -E -i "debian"; then
release="Debian"
elif cat /proc/version | grep -q -E -i "ubuntu"; then
release="Ubuntu"
elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
release="Centos"
else
echo "脚本不支持当前的系统，请选择使用Ubuntu,Debian,Centos系统。" && exit
fi
op=$(cat /etc/redhat-release 2>/dev/null || cat /etc/os-release 2>/dev/null | grep -i pretty_name | cut -d \" -f2)
if [[ $(echo "$op" | grep -i -E "arch") ]]; then
echo "脚本不支持当前的 $op sistem, please choose to use Ubuntu, Debian, Centos system." && exit
fi
[[ -z $(systemd-detect-virt 2>/dev/null) ]] && vi=$(virt-what 2>/dev/null) || vi=$(systemd-detect-virt 2>/dev/null)
case $(uname -m) in
aarch64) cpu=arm64;;
x86_64) cpu=amd64;;
*) echo "Currently the script does not support $(uname -m) architecture" && exit;;
esac
hostname=$(hostname)
del(){
kill -15 $(cat /etc/s-box-ag/sbargopid.log 2>/dev/null) >/dev/null 2>&1
kill -15 $(cat /etc/s-box-ag/sbpid.log 2>/dev/null) >/dev/null 2>&1
crontab -l > /tmp/crontab.tmp
sed -i '/sbargopid/d' /tmp/crontab.tmp
sed -i '/sbpid/d' /tmp/crontab.tmp
crontab /tmp/crontab.tmp
rm /tmp/crontab.tmp
rm -rf /etc/s-box-ag /usr/bin/agsb
}
up(){
rm -rf /usr/bin/agsb
curl -L -o /usr/bin/agsb -# --retry 2 --insecure https://raw.githubusercontent.com/yonggekkk/argosb/main/argosb.sh
chmod +x /usr/bin/agsb
}
if [[ "$1" == "del" ]]; then
del && sleep 2
echo "Uninstall completed"
exit
elif [[ "$1" == "up" ]]; then
up && sleep 2
echo "Upgrade completed"
exit
fi
if [[ -n $(ps -e | grep sing-box) ]] && [[ -n $(ps -e | grep cloudflared) ]] && [[ -e /etc/s-box-ag/list.txt ]]; then
echo "ArgoSB script is already running"
argoname=$(cat /etc/s-box-ag/sbargoym.log 2>/dev/null)
if [ -z $argoname ]; then
argodomain=$(cat /etc/s-box-ag/argo.log 2>/dev/null | grep -a trycloudflare.com | awk 'NR==2{print}' | awk -F// '{print $2}' | awk '{print $1}')
if [ -z $argodomain ]; then
echo "Current Argo temporary domain not generated, please uninstall the script first (agsb del), then reinstall ArgoSB script"
else
echo "Current Argo latest temporary domain: $argodomain"
fi
else
echo "Current Argo fixed domain: $argoname"
echo "Current Argo fixed domain token: $(cat /etc/s-box-ag/sbargotoken.log 2>/dev/null)"
fi
cat /etc/s-box-ag/list.txt
exit
elif [[ -z $(ps -e | grep sing-box) ]] && [[ -z $(ps -e | grep cloudflared) ]]; then
echo "Checking dependencies installation... Please wait"
if command -v apt &> /dev/null; then
apt update -y &> /dev/null
apt install curl wget tar gzip cron jq procps coreutils util-linux -y &> /dev/null
elif command -v yum &> /dev/null; then
yum install -y curl wget jq tar procps-ng coreutils util-linux &> /dev/null
elif command -v apk &> /dev/null; then
apk update -y &> /dev/null
apk add wget curl tar jq tzdata openssl git grep procps coreutils util-linux dcron &> /dev/null
fi
echo "VPS System: $op"
echo "CPU Architecture: $cpu"
echo "ArgoSB script not installed, starting installation..." && sleep 3
echo
else
echo "ArgoSB script not started, possibly conflicting with other sing-box or argo scripts, please uninstall the script first (agsb del), then reinstall ArgoSB script"
exit
fi
warpcheck(){
wgcfv6=$(curl -s6m5 https://www.cloudflare.com/cdn-cgi/trace -k | grep warp | cut -d= -f2)
wgcfv4=$(curl -s4m5 https://www.cloudflare.com/cdn-cgi/trace -k | grep warp | cut -d= -f2)
}
v4orv6(){
if [ -z $(curl -s4m5 icanhazip.com -k) ]; then
echo -e "nameserver 2a00:1098:2b::1\nnameserver 2a00:1098:2c::1\nnameserver 2a01:4f8:c2c:123f::1" > /etc/resolv.conf
fi
}
warpcheck
if [[ ! $wgcfv4 =~ on|plus && ! $wgcfv6 =~ on|plus ]]; then
v4orv6
else
systemctl stop wg-quick@wgcf >/dev/null 2>&1
kill -15 $(pgrep warp-go) >/dev/null 2>&1 && sleep 2
v4orv6
systemctl start wg-quick@wgcf >/dev/null 2>&1
systemctl restart warp-go >/dev/null 2>&1
systemctl enable warp-go >/dev/null 2>&1
systemctl start warp-go >/dev/null 2>&1
fi
mkdir -p /etc/s-box-ag
sbcore=$(curl -Ls https://data.jsdelivr.com/v1/package/gh/SagerNet/sing-box | grep -Eo '"[0-9.]+",' | sed -n 1p | tr -d '",')
sbname="sing-box-$sbcore-linux-$cpu"
echo "Downloading sing-box latest official kernel: $sbcore"
curl -L -o /etc/s-box-ag/sing-box.tar.gz -# --retry 2 https://github.com/SagerNet/sing-box/releases/download/v$sbcore/$sbname.tar.gz
if [[ -f '/etc/s-box-ag/sing-box.tar.gz' ]]; then
tar xzf /etc/s-box-ag/sing-box.tar.gz -C /etc/s-box-ag
mv /etc/s-box-ag/$sbname/sing-box /etc/s-box-ag
rm -rf /etc/s-box-ag/{sing-box.tar.gz,$sbname}
else
echo "Download failed, please check network" && exit
fi

if [ -z $port_vl_ws ]; then # Changed variable name
port_vl_ws=$(shuf -i 10000-65535 -n 1) # Changed variable name
fi
if [ -z $UUID ]; then
UUID=$(/etc/s-box-ag/sing-box generate uuid)
fi
echo
echo "Current VLESS main protocol port: $port_vl_ws" # Updated text
echo
echo "Current uuid password: $UUID"
echo
sleep 3

cat > /etc/s-box-ag/sb.json <<EOF
{
"log": {
    "disabled": false,
    "level": "info",
    "timestamp": true
  },
  "inbounds": [
{
        "type": "vless", # Changed from vmess to vless
        "tag": "vless-sb", # Updated tag
        "listen": "::",
        "listen_port": ${port_vl_ws}, # Changed variable name
        "users": [
            {
                "uuid": "${UUID}"
            }
        ],
        "transport": {
            "type": "ws",
            "path": "/${UUID}-vless", # Updated path for VLESS
            "max_early_data":2048,
            "early_data_header_name": "Sec-WebSocket-Protocol"
        },
        "tls":{
                "enabled": false,
                "server_name": "www.bing.com",
                "certificate_path": "/etc/s-box-ag/cert.pem",
                "key_path": "/etc/s-box-ag/private.key"
            }
    }
    ],
"outbounds": [
{
"type":"direct",
"tag":"direct"
}
]
}
EOF
nohup setsid /etc/s-box-ag/sing-box run -c /etc/s-box-ag/sb.json >/dev/null 2>&1 & echo "$!" > /etc/s-box-ag/sbpid.log
crontab -l > /tmp/crontab.tmp
sed -i '/sbpid/d' /tmp/crontab.tmp
echo '@reboot /bin/bash -c "nohup setsid /etc/s-box-ag/sing-box run -c /etc/s-box-ag/sb.json 2>&1 & pid=\$! && echo \$pid > /etc/s-box-ag/sbpid.log"' >> /tmp/crontab.tmp
crontab /tmp/crontab.tmp
rm /tmp/crontab.tmp
argocore=$(curl -Ls https://data.jsdelivr.com/v1/package/gh/cloudflare/cloudflared | grep -Eo '"[0-9.]+",' | sed -n 1p | tr -d '",')
echo "Downloading cloudflared-argo latest official kernel: $argocore"
curl -L -o /etc/s-box-ag/cloudflared -# --retry 2 https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-$cpu
chmod +x /etc/s-box-ag/cloudflared
if [[ -n "${ARGO_DOMAIN}" && -n "${ARGO_AUTH}" ]]; then
name='Fixed'
nohup setsid /etc/s-box-ag/cloudflared tunnel --no-autoupdate --edge-ip-version auto --protocol http2 run --token ${ARGO_AUTH} >/dev/null 2>&1 & echo "$!" > /etc/s-box-ag/sbargopid.log
echo ${ARGO_DOMAIN} > /etc/s-box-ag/sbargoym.log
echo ${ARGO_AUTH} > /etc/s-box-ag/sbargotoken.log
else
name='Temporary'
# --- FIX: Removed 'sed' pipe that was corrupting JSON output for jq ---
nohup setsid /etc/s-box-ag/cloudflared tunnel --url http://localhost:$(jq -r '.inbounds[0].listen_port' /etc/s-box-ag/sb.json) --edge-ip-version auto --no-autoupdate --protocol http2 > /etc/s-box-ag/argo.log 2>&1 &
echo "$!" > /etc/s-box-ag/sbargopid.log
fi
echo "Applying Argo$name tunnel... Please wait"
sleep 8
if [[ -n "${ARGO_DOMAIN}" && -n "${ARGO_AUTH}" ]]; then
argodomain=$(cat /etc/s-box-ag/sbargoym.log 2>/dev/null)
else
argodomain=$(cat /etc/s-box-ag/argo.log 2>/dev/null | grep -a trycloudflare.com | awk 'NR==2{print}' | awk -F// '{print $2}' | awk '{print $1}')
fi
if [[ -n $argodomain ]]; then
echo "Argo$name tunnel applied successfully, domain is: $argodomain"
else
echo "Argo$name tunnel application failed, please try again later" && del && exit
fi
crontab -l > /tmp/crontab.tmp
sed -i '/sbargopid/d' /tmp/crontab.tmp
if [[ -n "${ARGO_DOMAIN}" && -n "${ARGO_AUTH}" ]]; then
echo '@reboot /bin/bash -c "nohup setsid /etc/s-box-ag/cloudflared tunnel --no-autoupdate --edge-ip-version auto --protocol http2 run --token $(cat /etc/s-box-ag/sbargotoken.log 2>/dev/null) >/dev/null 2>&1 & pid=\$! && echo \$pid > /etc/s-box-ag/sbargopid.log"' >> /tmp/crontab.tmp
else
# --- FIX: Removed 'sed' pipe that was corrupting JSON output for jq in cronjob ---
echo '@reboot /bin/bash -c "nohup setsid /etc/s-box-ag/cloudflared tunnel --url http://localhost:$(jq -r '.inbounds[0].listen_port' /etc/s-box-ag/sb.json) --edge-ip-version auto --no-autoupdate --protocol http2 > /etc/s-box-ag/argo.log 2>&1 & pid=\$! && echo \$pid > /etc/s-box-ag/sbargopid.log"' >> /tmp/crontab.tmp
fi
crontab /tmp/crontab.tmp
rm /tmp/crontab.tmp
up
# VLESS link generation
vlatls_link1="vless://$(echo "${UUID}@104.16.0.0:443?encryption=none&security=tls&type=ws&host=${argodomain}&path=/${UUID}-vless&sni=${argodomain}&fp=&ed=2048#vless-ws-tls-argo-$hostname-443" | base64 -w0)"
echo "$vlatls_link1" > /etc/s-box-ag/jh.txt
vlatls_link2="vless://$(echo "${UUID}@104.17.0.0:8443?encryption=none&security=tls&type=ws&host=${argodomain}&path=/${UUID}-vless&sni=${argodomain}&fp=&ed=2048#vless-ws-tls-argo-$hostname-8443" | base64 -w0)"
echo "$vlatls_link2" >> /etc/s-box-ag/jh.txt
vlatls_link3="vless://$(echo "${UUID}@104.18.0.0:2053?encryption=none&security=tls&type=ws&host=${argodomain}&path=/${UUID}-vless&sni=${argodomain}&fp=&ed=2048#vless-ws-tls-argo-$hostname-2053" | base64 -w0)"
echo "$vlatls_link3" >> /etc/s-box-ag/jh.txt
vlatls_link4="vless://$(echo "${UUID}@104.19.0.0:2083?encryption=none&security=tls&type=ws&host=${argodomain}&path=/${UUID}-vless&sni=${argodomain}&fp=&ed=2048#vless-ws-tls-argo-$hostname-2083" | base64 -w0)"
echo "$vlatls_link4" >> /etc/s-box-ag/jh.txt
vlatls_link5="vless://$(echo "${UUID}@104.20.0.0:2087?encryption=none&security=tls&type=ws&host=${argodomain}&path=/${UUID}-vless&sni=${argodomain}&fp=&ed=2048#vless-ws-tls-argo-$hostname-2087" | base64 -w0)"
echo "$vlatls_link5" >> /etc/s-box-ag/jh.txt
vlatls_link6="vless://$(echo "${UUID}@[2606:4700::]:2096?encryption=none&security=tls&type=ws&host=${argodomain}&path=/${UUID}-vless&sni=${argodomain}&fp=&ed=2048#vless-ws-tls-argo-$hostname-2096" | base64 -w0)"
echo "$vlatls_link6" >> /etc/s-box-ag/jh.txt
vla_link7="vless://$(echo "${UUID}@104.21.0.0:80?encryption=none&security=none&type=ws&host=${argodomain}&path=/${UUID}-vless#vless-ws-argo-$hostname-80" | base64 -w0)"
echo "$vla_link7" >> /etc/s-box-ag/jh.txt
vla_link8="vless://$(echo "${UUID}@104.22.0.0:8080?encryption=none&security=none&type=ws&host=${argodomain}&path=/${UUID}-vless#vless-ws-argo-$hostname-8080" | base64 -w0)"
echo "$vla_link8" >> /etc/s-box-ag/jh.txt
vla_link9="vless://$(echo "${UUID}@104.24.0.0:8880?encryption=none&security=none&type=ws&host=${argodomain}&path=/${UUID}-vless#vless-ws-argo-$hostname-8880" | base64 -w0)"
echo "$vla_link9" >> /etc/s-box-ag/jh.txt
vla_link10="vless://$(echo "${UUID}@104.25.0.0:2052?encryption=none&security=none&type=ws&host=${argodomain}&path=/${UUID}-vless#vless-ws-argo-$hostname-2052" | base64 -w0)"
echo "$vla_link10" >> /etc/s-box-ag/jh.txt
vla_link11="vless://$(echo "${UUID}@104.26.0.0:2082?encryption=none&security=none&type=ws&host=${argodomain}&path=/${UUID}-vless#vless-ws-argo-$hostname-2082" | base64 -w0)"
echo "$vla_link11" >> /etc/s-box-ag/jh.txt
vla_link12="vless://$(echo "${UUID}@104.27.0.0:2086?encryption=none&security=none&type=ws&host=${argodomain}&path=/${UUID}-vless#vless-ws-argo-$hostname-2086" | base64 -w0)"
echo "$vla_link12" >> /etc/s-box-ag/jh.txt
vla_link13="vless://$(echo "${UUID}@[2400:cb00:2049::]:2095?encryption=none&security=none&type=ws&host=${argodomain}&path=/${UUID}-vless#vless-ws-argo-$hostname-2095" | base64 -w0)"
echo "$vla_link13" >> /etc/s-box-ag/jh.txt

baseurl=$(base64 -w 0 < /etc/s-box-ag/jh.txt)
line1=$(sed -n '1p' /etc/s-box-ag/jh.txt)
line6=$(sed -n '6p' /etc/s-box-ag/jh.txt)
line7=$(sed -n '7p' /etc/s-box-ag/jh.txt)
line13=$(sed -n '13p' /etc/s-box-ag/jh.txt)
vlport=${port_vl_ws} # Changed variable name
echo "ArgoSB script installation completed" && sleep 2
cat > /etc/s-box-ag/list.txt <<EOF
---------------------------------------------------------
---------------------------------------------------------
VLESS main protocol port (Argo fixed tunnel port): $vlport # Updated text
---------------------------------------------------------
Single node configuration output:
1、443 port VLESS-ws-tls-argo node, default preferred IPV4: 104.16.0.0 # Updated text
$line1

2、2096 port VLESS-ws-tls-argo node, default preferred IPV6: [2606:4700::] (available only if local network supports IPV6) # Updated text
$line6

3、80 port VLESS-ws-argo node, default preferred IPV4: 104.21.0.0 # Updated text
$line7

4、2095 port VLESS-ws-argo node, default preferred IPV6: [2400:cb00:2049::] (available only if local network supports IPV6) # Updated text
$line13

---------------------------------------------------------
Aggregated node configuration output:
5、Argo node 13 ports and immortal IP full coverage: 7 tls-off 80-series port nodes, 6 tls-on 443-series port nodes

$baseurl

---------------------------------------------------------
Related shortcuts are as follows:
Display domain and node information: agsb
Upgrade script: agsb up
Uninstall script: agsb del
---------------------------------------------------------
EOF
cat /etc/s-box-ag/list.txt
else # This is the nix/container part, also needs updates
op=$(cat /etc/redhat-release 2>/dev/null || cat /etc/os-release 2>/dev/null | grep -i pretty_name | cut -d \" -f2)
[[ -z $(systemd-detect-virt 2>/dev/null) ]] && vi=$(virt-what 2>/dev/null) || vi=$(systemd-detect-virt 2>/dev/null)
case $(uname -m) in
aarch64) cpu=arm64;;
x86_64) cpu=amd64;;
esac
hostname=$(uname -a | awk '{print $2}')
mkdir -p nixag
del(){
kill -15 $(cat nixag/sbargopid.log 2>/dev/null) >/dev/null 2>&1
kill -15 $(cat nixag/sbpid.log 2>/dev/null) >/dev/null 2>&1
sed -i '/yonggekkk/d' ~/.bashrc
source ~/.bashrc
rm -rf nixag
}
if [[ "$1" == "del" ]]; then
del && sleep 2
echo "Uninstall completed"
exit
fi
if [[ -n $(ps -e | grep sing-box) ]] && [[ -n $(ps -e | grep cloudflared) ]] && [[ -e nixag/list.txt ]]; then
echo "ArgoSB script is already running"
cat nixag/list.txt
exit
else
echo "VPS System: $op"
echo "CPU Architecture: $cpu"
echo "ArgoSB script not installed, starting installation..." && sleep 3
fi
if [ ! -e nixag/sing-box ]; then
sbcore=$(curl -Ls https://data.jsdelivr.com/v1/package/gh/SagerNet/sing-box | grep -Eo '"[0-9.]+",' | sed -n 1p | tr -d '",')
sbname="sing-box-$sbcore-linux-$cpu"
echo "Downloading sing-box latest official kernel: $sbcore"
curl -L -o nixag/sing-box.tar.gz -# --retry 2 https://github.com/SagerNet/sing-box/releases/download/v$sbcore/$sbname.tar.gz
if [[ -f 'nixag/sing-box.tar.gz' ]]; then
tar xzf nixag/sing-box.tar.gz -C nixag
mv nixag/$sbname/sing-box nixag
rm -rf nixag/{sing-box.tar.gz,$sbname}
chmod +x nixag/sing-box
else
echo "Download failed, please check network" && exit
fi
fi
if [ -z $port_vl_ws ]; then # Changed variable name
port_vl_ws=$(shuf -i 10000-65535 -n 1) # Changed variable name
fi
if [ -z $UUID ]; then
UUID=$(./nixag/sing-box generate uuid)
fi
echo
echo "Current VLESS main protocol port: $port_vl_ws" # Updated text
echo
echo "Current uuid password: $UUID"
echo
if [[ "$hostname" == *firebase* || "$hostname" == *idx* ]]; then
[ -f ~/.bashrc ] || touch ~/.bashrc
sed -i '/yonggekkk/d' ~/.bashrc
echo "export nix=y uuid=${uuid} vlpt=${port_vl_ws} agn=${ARGO_DOMAIN} agk=${ARGO_AUTH} && bash <(curl -Ls https://raw.githubusercontent.com/yonggekkk/argosb/main/argosb.sh)" >> ~/.bashrc
source ~/.bashrc
fi
sleep 2

cat > nixag/sb.json <<EOF
{
"log": {
    "disabled": false,
    "level": "info",
    "timestamp": true
  },
  "inbounds": [
{
        "type": "vless", # Changed from vmess to vless
        "tag": "vless-sb", # Updated tag
        "listen": "::",
        "listen_port": ${port_vl_ws}, # Changed variable name
        "users": [
            {
                "uuid": "${UUID}"
            }
        ],
        "transport": {
            "type": "ws",
            "path": "/${UUID}-vless", # Updated path for VLESS
            "max_early_data":2048,
            "early_data_header_name": "Sec-WebSocket-Protocol"
        },
        "tls":{
                "enabled": false,
                "server_name": "www.bing.com",
                "certificate_path": "/nixag/cert.pem",
                "key_path": "/nixag/private.key"
            }
    }
    ],
"outbounds": [
{
"type":"direct",
"tag":"direct"
}
]
}
EOF
nohup ./nixag/sing-box run -c nixag/sb.json >/dev/null 2>&1 & echo "$!" > nixag/sbpid.log
if [ ! -e nixag/cloudflared ]; then
argocore=$(curl -Ls https://data.jsdelivr.com/v1/package/gh/cloudflare/cloudflared | grep -Eo '"[0-9.]+",' | sed -n 1p | tr -d '",')
echo "Downloading cloudflared-argo latest official kernel: $argocore"
curl -L -o nixag/cloudflared -# --retry 2 https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-$cpu
chmod +x nixag/cloudflared
fi
if [[ -n "${ARGO_DOMAIN}" && -n "${ARGO_AUTH}" ]]; then
name='Fixed'
nohup ./nixag/cloudflared tunnel --no-autoupdate --edge-ip-version auto --protocol http2 run --token ${ARGO_AUTH} >/dev/null 2>&1 & echo "$!" > nixag/sbargopid.log
echo ${ARGO_DOMAIN} > nixag/sbargoym.log
echo ${ARGO_AUTH} > nixag/sbargotoken.log
else
name='Temporary'
nohup ./nixag/cloudflared tunnel --url http://localhost:${port_vl_ws} --edge-ip-version auto --no-autoupdate --protocol http2 > nixag/argo.log 2>&1 &
echo "$!" > nixag/sbargopid.log
fi
echo "Applying Argo$name tunnel... Please wait"
sleep 8
if [[ -n "${ARGO_DOMAIN}" && -n "${ARGO_AUTH}" ]]; then
argodomain=$(cat nixag/sbargoym.log 2>/dev/null)
nametn="Current Argo fixed tunnel token: $(cat nixag/sbargotoken.log 2>/dev/null)"
else
argodomain=$(cat nixag/argo.log 2>/dev/null | grep -a trycloudflare.com | awk 'NR==2{print}' | awk -F// '{print $2}' | awk '{print $1}')
fi
if [[ -n $argodomain ]]; then
echo "Argo$name tunnel applied successfully, domain is: $argodomain"
else
echo "Argo$name tunnel application failed, please try again later" && del && exit
fi
# VLESS link generation for nix
vlatls_link1="vless://$(echo "${UUID}@104.16.0.0:443?encryption=none&security=tls&type=ws&host=${argodomain}&path=/${UUID}-vless&sni=${argodomain}&fp=&ed=2048#vless-ws-tls-argo-$hostname-443" | base64 -w0)"
echo "$vlatls_link1" > nixag/jh.txt
vlatls_link2="vless://$(echo "${UUID}@104.17.0.0:8443?encryption=none&security=tls&type=ws&host=${argodomain}&path=/${UUID}-vless&sni=${argodomain}&fp=&ed=2048#vless-ws-tls-argo-$hostname-8443" | base64 -w0)"
echo "$vlatls_link2" >> nixag/jh.txt
vlatls_link3="vless://$(echo "${UUID}@104.18.0.0:2053?encryption=none&security=tls&type=ws&host=${argodomain}&path=/${UUID}-vless&sni=${argodomain}&fp=&ed=2048#vless-ws-tls-argo-$hostname-2053" | base64 -w0)"
echo "$vlatls_link3" >> nixag/jh.txt
vlatls_link4="vless://$(echo "${UUID}@104.19.0.0:2083?encryption=none&security=tls&type=ws&host=${argodomain}&path=/${UUID}-vless&sni=${argodomain}&fp=&ed=2048#vless-ws-tls-argo-$hostname-2083" | base64 -w0)"
echo "$vlatls_link4" >> nixag/jh.txt
vlatls_link5="vless://$(echo "${UUID}@104.20.0.0:2087?encryption=none&security=tls&type=ws&host=${argodomain}&path=/${UUID}-vless&sni=${argodomain}&fp=&ed=2048#vless-ws-tls-argo-$hostname-2087" | base64 -w0)"
echo "$vlatls_link5" >> nixag/jh.txt
vlatls_link6="vless://$(echo "${UUID}@[2606:4700::]:2096?encryption=none&security=tls&type=ws&host=${argodomain}&path=/${UUID}-vless&sni=${argodomain}&fp=&ed=2048#vless-ws-tls-argo-$hostname-2096" | base64 -w0)"
echo "$vlatls_link6" >> nixag/jh.txt
vla_link7="vless://$(echo "${UUID}@104.21.0.0:80?encryption=none&security=none&type=ws&host=${argodomain}&path=/${UUID}-vless#vless-ws-argo-$hostname-80" | base64 -w0)"
echo "$vla_link7" >> nixag/jh.txt
vla_link8="vless://$(echo "${UUID}@104.22.0.0:8080?encryption=none&security=none&type=ws&host=${argodomain}&path=/${UUID}-vless#vless-ws-argo-$hostname-8080" | base64 -w0)"
echo "$vla_link8" >> nixag/jh.txt
vla_link9="vless://$(echo "${UUID}@104.24.0.0:8880?encryption=none&security=none&type=ws&host=${argodomain}&path=/${UUID}-vless#vless-ws-argo-$hostname-8880" | base64 -w0)"
echo "$vla_link9" >> nixag/jh.txt
vla_link10="vless://$(echo "${UUID}@104.25.0.0:2052?encryption=none&security=none&type=ws&host=${argodomain}&path=/${UUID}-vless#vless-ws-argo-$hostname-2052" | base64 -w0)"
echo "$vla_link10" >> nixag/jh.txt
vla_link11="vless://$(echo "${UUID}@104.26.0.0:2082?encryption=none&security=none&type=ws&host=${argodomain}&path=/${UUID}-vless#vless-ws-argo-$hostname-2082" | base64 -w0)"
echo "$vla_link11" >> nixag/jh.txt
vla_link12="vless://$(echo "${UUID}@104.27.0.0:2086?encryption=none&security=none&type=ws&host=${argodomain}&path=/${UUID}-vless#vless-ws-argo-$hostname-2086" | base64 -w0)"
echo "$vla_link12" >> nixag/jh.txt
vla_link13="vless://$(echo "${UUID}@[2400:cb00:2049::]:2095?encryption=none&security=none&type=ws&host=${argodomain}&path=/${UUID}-vless#vless-ws-argo-$hostname-2095" | base64 -w0)"
echo "$vla_link13" >> nixag/jh.txt
line1=$(sed -n '1p' nixag/jh.txt)
line6=$(sed -n '6p' nixag/jh.txt)
line7=$(sed -n '7p' nixag/jh.txt)
line13=$(sed -n '13p' nixag/jh.txt)
echo "ArgoSB script installation completed" && sleep 2
echo
echo
cat > nixag/list.txt <<EOF
---------------------------------------------------------
---------------------------------------------------------
---------------------------------------------------------
The following node information content, please check the nixag/list.txt file or run cat nixag/jh.txt to copy
---------------------------------------------------------
VLESS main protocol port (Argo fixed tunnel port): $port_vl_ws # Updated text
Current Argo$name domain: $argodomain
$nametn
---------------------------------------------------------
1、443 port VLESS-ws-tls-argo node, default preferred IPV4: 104.16.0.0 # Updated text
$line1

2、2096 port VLESS-ws-tls-argo node, default preferred IPV6: [2606:4700::] (available only if local network supports IPV6) # Updated text
$line6

3、80 port VLESS-ws-argo node, default preferred IPV4: 104.21.0.0 # Updated text
$line7

4、2095 port VLESS-ws-argo node, default preferred IPV6: [2400:cb00:2049::] (available only if local network supports IPV6) # Updated text
$line13

5、Argo node 13 ports aggregation node information, please check the nixag/jh.txt file or run cat nixag/jh.txt to copy
---------------------------------------------------------
---------------------------------------------------------
---------------------------------------------------------
EOF
cat nixag/list.txt
fi
