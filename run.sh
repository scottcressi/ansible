#!/usr/bin/env sh

if ! command -v python3 > /dev/null ; then echo python3 is not installed ;  exit 0 ; fi
if ! command -v ansible > /dev/null ; then echo ansible is not installed ;  exit 0 ; fi
if ! command -v yamllint > /dev/null ; then echo yamllint is not installed ;  exit 0 ; fi

echo running yamllint
yamllint . -s

if [ $# -eq 0 ] ; then
    echo """
options:
--playbook PLAYBOOK ie. playbooks/test.yaml | etc.
--env ENV ie. dev | test | prod | etc.
--limit LIMIT ie. git | mysql | etc.
--vault
--apply
"""
    exit 0
fi

export ANSIBLE_HOST_KEY_CHECKING=False

# defaults
NOOP="--check"
ENV="test"
LIMIT="test"

init_vault(){
    if ! command -v vault > /dev/null ; then echo vault is not installed ;  exit 0 ; fi
    if ! pgrep vault > /dev/null ; then
        vault server -dev -dev-root-token-id="root" &
    fi

}

while [ $# -gt 0 ]; do
  case "$1" in
    --playbook|-p) PLAYBOOK=$2 ;;
    --env) ENV=$2 ;;
    --limit) LIMIT=$2 ;;
    --apply) NOOP= ;;
    --vault) init_vault && exit 0 ;;
  esac
  shift
done

if [ "$ENV" = test ] ; then
    CONNECTION=--connection=local
fi

ansible-galaxy install -r requirements.yaml
echo
ansible-playbook \
    "$PLAYBOOK" \
    -e ansible_python_interpreter=/usr/bin/python3 \
    -i inventories/inventory-"$ENV".yaml \
    --limit "$LIMIT" \
    --diff \
    $NOOP \
    --become \
    "$CONNECTION"
