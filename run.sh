#!/usr/bin/env sh

if ! command -v python3 > /dev/null ; then echo python3 is not installed ;  exit 0 ; fi
if ! command -v ansible > /dev/null ; then echo ansible is not installed ;  exit 0 ; fi
if ! command -v yamllint > /dev/null ; then echo yamllint is not installed ;  exit 0 ; fi

# help
if [ $# -eq 0 ] ; then
    echo """
options:
--playbook PLAYBOOK ex. --playbook playbooks/tet.yaml
--env ENV           ex. --env dev
--limit LIMIT       ex. --limit git
--install-prereqs
--apply
--test-ara
"""
    exit 0
fi

export ANSIBLE_HOST_KEY_CHECKING=False

# ansible run analysis
export ANSIBLE_CALLBACK_PLUGINS="$(python3 -m ara.setup.callback_plugins)"
export ARA_API_CLIENT="http"
export ARA_API_SERVER="http://127.0.0.1:8000"

# defaults
NOOP="--check"
ENV="test"
LIMIT="test"

install_prereqs(){
    if ! command -v vault > /dev/null ; then echo vault is not installed ;  exit 0 ; fi
    if ! pgrep vault > /dev/null ; then
        vault server -dev -dev-root-token-id="root" &
    fi
    pip install --upgrade -r requirements.txt

}

while [ $# -gt 0 ]; do
  case "$1" in
    --playbook|-p) PLAYBOOK=$2 ;;
    --env) ENV=$2 ;;
    --limit) LIMIT=$2 ;;
    --apply) NOOP= ;;
    --install-prereqs) install_prereqs && exit 0 ;;
    --test-ara) docker exec -ti ansible-ara sh -c "ara playbook list" && exit 0 ;;
    *) echo invalid option && exit 0 ;;
  esac
  shift
done

if [ "$ENV" = test ] ; then
    CONNECTION=--connection=local
fi

yamllint . -s
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
