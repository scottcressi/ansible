if ! command -v ansible > /dev/null ; then echo ansible is not installed ;  exit 0 ; fi
if ! command -v yamllint > /dev/null ; then echo yamllint is not installed ;  exit 0 ; fi

yamllint . -s

export ANSIBLE_HOST_KEY_CHECKING=False

echo "enter env: test | dev | prod"
read -r ENV
echo "enter playbook: base | test"
read -r PLAYBOOK
echo "enter group: git | mysql "
read -r LIMIT

ansible-galaxy install -r requirements.yaml -f
ansible-playbook roles/"$PLAYBOOK".yaml -e ansible_python_interpreter=/usr/bin/python2 -i inventories/inventory-"$ENV".yaml --limit "$LIMIT" --check --diff
