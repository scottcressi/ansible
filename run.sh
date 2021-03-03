#!/usr/bin/env sh

print_help(){
    echo """
    options for prereqs
    --setup-pip             # installs pip requirements
    --setup-vault           # sets up vault
    --setup-ara             # sets up ara

    options for testing
    --test-ara              # test ara once ansible is run without --check
    --test-vagrant          # test ansible in vagrant
    --lint                  # lint everything

    run:
    --run-ansible           # run ansible
    """
}

setup_vault(){
    if ! pgrep vault > /dev/null ; then
        docker-compose up -d vault
    fi
    sleep 2
    docker exec -ti vault sh -c "export VAULT_TOKEN=root \
    ; vault kv put -address http://127.0.0.1:8200 secret/hello foo=bar \
    "
    echo open in browser: http://127.0.0.1:8200
}

setup_ara(){
    docker-compose up -d ansible-ara
    echo
    echo open in browser: http://127.0.0.1:8000
}

test_vagrant(){
    vagrant up
    ansible-galaxy install -r requirements.yaml
    ansible-playbook --diff --inventory inventories/vagrant.yaml playbooks/test.yaml
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

    # ansible lint playbooks
    for i in $(find playbooks -type f) ; do
        ansible-lint "$i"
    done

    # ansible lint roles
    for i in $(find roles -maxdepth 1 -mindepth 1) ; do
        ansible-lint "$i"
    done

    # ansible playbook syntax check
    for i in $(find playbooks -type f) ; do
        ansible-playbook "$i" -i inventories/vagrant.yaml --check --syntax-check
    done
}

run_ansible(){
    ansible-galaxy install -r requirements.yaml
    echo """
    example command:
    ansible-playbook --diff --inventory inventories/local.yaml playbooks/test.yaml --check
    """
}

if [ $# -eq 0 ] ; then
    print_help
    exit 0
fi

TEMP=$(getopt -o h --long setup-pip,setup-vault,setup-ara,test-ara,test-vagrant,run-ansible,lint,help \
             -n 'case' -- "$@")
while true; do
  case "$1" in
    --setup-pip) setup_pip ; break ;;
    --setup-vault) setup_vault ; break ;;
    --setup-ara) setup_ara ; break ;;
    --test-ara) test_ara ; break ;;
    --test-vagrant) test_vagrant ; break ;;
    --lint) lint ; break ;;
    --run-ansible) run_ansible ; break ;;
    -h | --help) print_help ; exit 0 ;;
    -- ) shift; break ;;
    * ) break ;;
  esac
done

if ! command -v python3 > /dev/null ; then echo python3 is not installed ;  exit 0 ; fi
if ! command -v ansible > /dev/null ; then echo ansible is not installed ;  exit 0 ; fi
if ! command -v yamllint > /dev/null ; then echo yamllint is not installed ;  exit 0 ; fi
