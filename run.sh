#!/usr/bin/env sh

if ! command -v python3 > /dev/null ; then echo python3 is not installed ;  exit 0 ; fi
if ! command -v ansible > /dev/null ; then echo ansible is not installed ;  exit 0 ; fi
if ! command -v yamllint > /dev/null ; then echo yamllint is not installed ;  exit 0 ; fi

print_help(){
    echo """
    options for prereqs
    --setup-pip             # installs pip requirements
    --setup-vault           # sets up vault
    --setup-ara             # sets up ara

    options for testing
    --test-ara              # test ara once ansible is run
    --test-docker           # test ansible in a docker
    --test-vagrant          # test ansible in a vagrant

    options for running:
    --playbook PLAYBOOK     # playbook ex. --playbook playbooks/test.yaml
    --inventory INVENTORY   # inventory ex. --env inventory
    --limit LIMIT           # limits to host groups in inventory ex. --limit git
    --apply                 # applies (noop by default)
    """
}

setup_vault(){
    if ! command -v vault > /dev/null ; then echo vault is not installed ;  exit 0 ; fi
    if ! pgrep vault > /dev/null ; then
        vault server -dev -dev-root-token-id="root" &
        sleep 2
    fi
    vault kv put -address http://127.0.0.1:8200 secret/hello foo=bar
    echo
    echo open in browser: http://127.0.0.1:8200
}

setup_ara(){
    docker-compose up -d
    echo
    echo open in browser: http://127.0.0.1:8000
}

test_docker(){
    docker build -t ansible-test .
    docker run -ti -v "$(pwd)":/test ansible-test
}

test_vagrant(){
    vagrant up
    vagrant ssh -c "cd ~/ansible ; bash run.sh -p playbooks/test.yaml --apply"
}

setup_pip(){
    pip install -r requirements.txt
}

test_ara(){
    docker exec -ti ansible-ara sh -c "ara playbook list --long"
}

lint(){
    # yamllint
    find playbooks/ inventories/ roles/ \
        -not -path "roles/*/.travis.yml" \
        -not -path "roles/*/meta/main.yml" \
        -not -path "roles/*/README.md" \
        -not -path "roles/*/tests/inventory" \
        -type f | xargs yamllint -s -d "{extends: relaxed, rules: {line-length: {max: 120}}}"

    # ansible lint
    for i in $(find playbooks -type f) ; do
        ansible-lint --exclude ../../../.ansible/roles/ "$i"
    done

    # ansible playbook syntax check
    for i in $(find playbooks -type f) ; do
        ansible-playbook "$i" -i inventories/vagrant.yaml --check --syntax-check
    done
}

TEMP=$(getopt -o h --long inventory:,playbook:,limit:,apply,setup-pip,setup-vault,setup-ara,test-ara,test-docker,test-vagrant,lint,help \
             -n 'case' -- "$@")
while true; do
  case "$1" in
    --setup-pip) setup_pip ; break ;;
    --setup-vault) setup_vault ; break ;;
    --setup-ara) setup_ara ; break ;;
    --test-ara) test_ara ; break ;;
    --test-docker) test_docker ; break ;;
    --test-vagrant) test_vagrant ; break ;;
    --lint) lint ; break ;;
    -h | --help) print_help ; break ;;
    -- ) shift; break ;;
    * ) break ;;
  esac
done

# ansible run analysis
export ANSIBLE_CALLBACK_PLUGINS="$(python3 -m ara.setup.callback_plugins)"
export ARA_API_CLIENT="http"
export ARA_API_SERVER="http://127.0.0.1:8000"

# galaxy
ansible-galaxy install -r requirements.yaml

# ansible playbook run
echo
echo """
example command:
ansible-playbook --inventory inventories/vagrant.yaml --check --diff playbooks/test.yaml
"""
echo
