#!/bin/bash
# set -x -e

# run by 
# . <(wget -qO- https://raw.githubusercontent.com/Vahhhh/solana/main/post_restart_solana.sh)
# or
# wget -O - https://raw.githubusercontent.com/Vahhhh/solana/main/post_restart_solana.sh | bash -s $NODENAME $TELEGRAM_BOT_TOKEN $TELEGRAM_CHAT_ID

echo "###################### WARNING!!! ###################################"
echo "###   This script will perform the following operations:          ###"
echo "###   * check your slot and rpc slot                              ###"
echo "###   * restart validator service and send message                ###"
echo "###   * wait for catchup send message                             ###"
echo "###                                                               ###"
echo "###   *** Script provided by MARGUS.ONE and Vah StakeITeasy       ###"
echo "#####################################################################"
echo

SLEEP_SEC=30
service_file="/root/solana/solana.service"
NODE_NAME=$1
TELEGRAM_BOT_TOKEN=$2
TELEGRAM_CHAT_ID=$3

if [[ -z "$NODE_NAME" ]]; then
printf "${C_LGn}Enter the nodename [node-main]:${RES} "
read -r NODENAME
fi

if [[ -z "$TELEGRAM_BOT_TOKEN" ]]; then
printf "${C_LGn}Enter the Telegram bot token:${RES} "
read -r TELEGRAM_BOT_TOKEN
fi

if [[ -z "$TELEGRAM_CHAT_ID" ]]; then
printf "${C_LGn}Enter the Telegram chat id:${RES} "
read -r TELEGRAM_CHAT_ID
fi

LEDGER=$(grep '\--ledger ' $service_file | awk '{ print $2 }')        # path to ledger (default: /root/solana/ledger)
SNAPSHOTS=$(grep '\--snapshots ' $service_file | awk '{ print $2 }')  # path to snapshots (default: /root/solana/ledger)

ICON=`echo -e '\U0001F514'`
PATH="/root/.local/share/solana/install/active_release/bin:$PATH"

send_message() {
telegram_bot_token=$TELEGRAM_BOT_TOKEN
telegram_chat_id=$TELEGRAM_CHAT_ID
Title="$1"
Message="$2"
curl -s \
 --data parse_mode=HTML \
 --data chat_id=${telegram_chat_id} \
 --data text="<b>${Title}</b>%0A${Message}" \
 --request POST https://api.telegram.org/bot${telegram_bot_token}/sendMessage
}

catchup_info() {
  while true; do
    rpcPort=$(ps aux | grep solana-validator | grep -Po "\-\-rpc\-port\s+\K[0-9]+")
    solana catchup --our-localhost $rpcPort ; status=$?
    if [ $status -eq 0 ]
    then
      DELINQ=$(solana validators -um --output json-compact | jq -c --arg pub_key1 "$(solana address)" '.validators[] | select(.identityPubkey==$pub_key1 ) | .delinquent ')
        if [[ $DELINQ == false ]]
        then
          echo "Node is running on another server, don't touch identity"
        else
          solana-validator -l $LEDGER set-identity /root/solana/validator-keypair.json
        fi
      break
    fi
    echo "waiting next $SLEEP_SEC seconds for rpc"
    sleep $SLEEP_SEC
  done
}

send_message "${ICON} Solana alert! ${NODE_NAME}" "Solana service has been restarted! identity - $(ls -l /root/solana/identity.json | awk '{ print $NF }')"
send_message "${ICON} Solana alert! ${NODE_NAME}" "$(catchup_info)"