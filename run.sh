#!/usr/bin/env sh

if ! command -v python3 > /dev/null ; then echo python3 is not installed ;  exit 0 ; fi
if ! command -v ansible > /dev/null ; then echo ansible is not installed, please pip3 install -r requirements.txt ;  exit 0 ; fi
if ! command -v yamllint > /dev/null ; then echo yamllint is not installed, please pip3 install -r requirements.txt;  exit 0 ; fi

INSTALLED_VERSION="$(pip3 list | grep "ansible " | awk '{print $2}')"
REQUIRED_VERSION="$(grep ansible== requirements.txt | sed 's/.*==//g')"

if [ "$INSTALLED_VERSION" != "$REQUIRED_VERSION" ] ; then
    echo please pip3 install -r requirements.txt
    exit 0
fi

print_help(){
    echo """
    options for prereqs
    --setup-ara             # sets up ara

    options for testing
    --test-vagrant          # test ansible in vagrant
    --lint                  # lint everything

    run:
    --run-ansible           # run ansible
    """
}

setup_ara(){
    docker-compose up -d ansible-ara
    sleep 1
    docker exec -ti ansible-ara sh -c "ara playbook list --long"
    echo
    echo open in browser: http://127.0.0.1:8000
}

test_vagrant(){
    vagrant up
    ansible-galaxy install -r requirements.yaml
    ansible-playbook --inventory inventories/vagrant.yaml playbooks/test.yaml
}

lint(){
    echo ; echo yamllint ; echo
    find . -type f -name "*.y*ml" \
        | grep -v /meta/ \
        | grep -v .travis.yml \
        | xargs yamllint -s -d "{extends: relaxed, rules: {line-length: {max: 120}}}"

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
    ansible-playbook --inventory inventories/local.yaml playbooks/test.yaml --check
    """
}

if [ $# -eq 0 ] ; then
    print_help
    exit 0
fi

TEMP=$(getopt -o h --long ,setup-ara,test-vagrant,run-ansible,lint,help \
             -n 'case' -- "$@")
while true; do
  case "$1" in
    --setup-ara) setup_ara ; break ;;
    --test-vagrant) test_vagrant ; break ;;
    --lint) lint ; break ;;
    --run-ansible) run_ansible ; break ;;
    -h | --help) print_help ; exit 0 ;;
    -- ) shift; break ;;
    * ) break ;;
  esac
done
