#!/usr/bin/env sh

# defaults
NOOP="--check"
ENV="test"
LIMIT="test"

print_help(){
    echo """
    options for prereqs
    --setup-pip         # installs pip requirements
    --setup-vault       # sets up vault
    --setup-ara         # sets up ara

    options for testing
    --test-ara          # test ara once ansible is run
    --test-docker       # test ansible in a docker
    --test-vagrant      # test ansible in a vagrant

    options for running:
    --playbook PLAYBOOK # playbook ex. --playbook playbooks/test.yaml
    --env ENV           # environment ex. --env dev
    --limit LIMIT       # limits to host groups in inventory ex. --limit git
    --apply             # applies (noop by default)
    """
}

setup_vault(){
    if ! command -v vault > /dev/null ; then echo vault is not installed ;  exit 0 ; fi
    if ! pgrep vault > /dev/null ; then
        vault server -dev -dev-root-token-id="root" &
    fi
    echo
    echo open in browser: http://localhost:8200
}

setup_ara(){
    docker-compose up -d
    echo
    echo open in browser: http://localhost:8000
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
    docker exec -ti ansible-ara sh -c "ara playbook list"
}

if [ $# -eq 0 ] ; then print_help ; exit 0 ; fi

while [ $# -gt 0 ]; do
  case "$1" in
    --playbook|-p) PLAYBOOK=$2 ; break ;;
    --env) ENV=$2 ; break ;;
    --limit) LIMIT=$2 ; break ;;
    --apply) NOOP= ; break ;;
    --setup-pip) setup_pip ; exit 0 ;;
    --setup-vault) setup_vault ; exit 0 ;;
    --setup-ara) setup_ara ; exit 0 ;;
    --test-ara) test_ara ; exit 0 ;;
    --test-docker) test_docker ; exit 0 ;;
    --test-vagrant) test_vagrant ; exit 0 ;;
    --help|-h) print_help ; exit 0 ;;
    *) echo invalid option ; print_help ; exit 0 ;;
  esac
  shift
done

if ! command -v python3 > /dev/null ; then echo python3 is not installed ;  exit 0 ; fi
if ! command -v ansible > /dev/null ; then echo ansible is not installed ;  exit 0 ; fi
if ! command -v yamllint > /dev/null ; then echo yamllint is not installed ;  exit 0 ; fi

# hosts
export ANSIBLE_HOST_KEY_CHECKING=False

# ansible run analysis
export ANSIBLE_CALLBACK_PLUGINS="$(python3 -m ara.setup.callback_plugins)"
export ARA_API_CLIENT="http"
export ARA_API_SERVER="http://127.0.0.1:8000"

if [ "$ENV" = test ] ; then
    CONNECTION=--connection=local
fi

ansible-galaxy install -r requirements.yaml
yamllint . -s
ansible-lint "$PLAYBOOK"
ansible-playbook "$PLAYBOOK" -e ansible_python_interpreter=/usr/bin/python3 -i inventories/inventory-"$ENV".yaml --limit "$LIMIT" --diff "$NOOP" --become "$CONNECTION" --syntax-check
ansible-playbook "$PLAYBOOK" -e ansible_python_interpreter=/usr/bin/python3 -i inventories/inventory-"$ENV".yaml --limit "$LIMIT" --diff "$NOOP" --become "$CONNECTION"
