#!/usr/bin/env sh

if ! command -v python3 > /dev/null ; then echo python3 is not installed ;  exit 0 ; fi
if ! command -v ansible > /dev/null ; then echo ansible is not installed ;  exit 0 ; fi
if ! command -v yamllint > /dev/null ; then echo yamllint is not installed ;  exit 0 ; fi

# hosts
export ANSIBLE_HOST_KEY_CHECKING=False

# ansible run analysis
export ANSIBLE_CALLBACK_PLUGINS="$(python3 -m ara.setup.callback_plugins)"
export ARA_API_CLIENT="http"
export ARA_API_SERVER="http://127.0.0.1:8000"

# defaults
NOOP="--check"
ENV="test"
LIMIT="test"

print_help(){
    echo """
    options for testing and prereqs
    --install-prereqs
    --test-ara

    options for running:
    --playbook PLAYBOOK ex. --playbook playbooks/tet.yaml
    --env ENV           ex. --env dev
    --limit LIMIT       ex. --limit git
    --apply
    """
}

install_prereqs(){
    if ! command -v vault > /dev/null ; then echo vault is not installed ;  exit 0 ; fi
    if ! pgrep vault > /dev/null ; then
        vault server -dev -dev-root-token-id="root" &
    fi
    pip install -r requirements.txt --quiet --quiet
    docker-compose up -d
    echo
    echo open in browser: http://localhost:8000
}

if [ $# -eq 0 ] ; then print_help ; exit 0 ; fi

while [ $# -gt 0 ]; do
  case "$1" in
    --playbook|-p) PLAYBOOK=$2 ; break ;;
    --env) ENV=$2 ; break ;;
    --limit) LIMIT=$2 ; break ;;
    --apply) NOOP= ; break ;;
    --install-prereqs) install_prereqs ; exit 0 ;;
    --test-ara) docker exec -ti ansible-ara sh -c "ara playbook list" ; exit 0 ;;
    --help|-h) print_help ; exit 0 ;;
    *) echo invalid option ; print_help ; exit 0 ;;
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
