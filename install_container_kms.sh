#!/bin/sh
clear
echo "

Version:  0.0.2
Last Updated:  12/8/2025


https://py-kms.readthedocs.io/en/latest/Keys.html


Login to windows
Run command prompt as administrator
Enter commands:

	slmgr /upk
	slmgr /ipk W269N-WFGWX-YVC9B-4J6C9-T83GX  (windows key)
	slmgr /skms 10.1.10.180 (IP of KMS Server)
	slmgr /at0
	slmgr /ato
------------------------------------------------------------


Windows Server 2022 Evaluation (Eval) to Full Version
Download Windows Server 2022 Evaluation English from Microsoft
https://software-static.download.prss.microsoft.com/sg/download/888969d5-f34g-4e03-ac9d-1f9786c66749/SERVER_EVAL_x64FRE_en-us.iso
Upgrade (Eval) to Full version
Open cmd (run as administrator), then use
Upgrade to STANDARD
dism /online /set-edition:serverstandard /productkey:<PRODUCT KEY> /accepteula



"

docker run -it -d --name py3-kms \
    -p 8080:80 \
    -p 1688:1688 \
    -e SQLITE=true \
    -v /etc/localtime:/etc/localtime:ro \
    --restart unless-stopped ghcr.io/py-kms-organization/py-kms:latest
