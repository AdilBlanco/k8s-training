read -p "HOST IP ? " IP
if [ "$IP" = "" ];then
  echo "HOST IP must be provided"
  exit 1
fi

curl -s -o nginx.log https://gist.githubusercontent.com/lucj/83769b6a74dd29c918498d022442f2a0/raw

while read -r line; do curl -s -XPUT -d "$line" http://$IP:31500; done < ./nginx.log
