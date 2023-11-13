#!/bin/bash

dnf -y install sudo curl
curl -1sLf ${TOKEN_URL} | sudo -E bash

sudo dnf -y install ${1}
