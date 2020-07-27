#!/bin/sh

mkdir $HOME/secrets

echo $SSH_PUB_KEY > $HOME/secrets/pub
echo $SSH_PRIV_KEY > $HOME/secrets/priv