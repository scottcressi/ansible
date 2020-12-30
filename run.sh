if ! command -v ansible > /dev/null ; then echo ansible is not installed ;  exit 0 ; fi
if ! command -v yamllint > /dev/null ; then echo yamllint is not installed ;  exit 0 ; fi

yamllint . -s

export ANSIBLE_HOST_KEY_CHECKING=False

ansible-galaxy install -r requirements.yaml -f

echo
echo available environments:
find inventories -type f | sed 's/inventories\/inventory-//g' | sed 's/.yaml//g'
echo

echo enter env:
read -r ENV
echo

echo available playbooks:
find roles -type f | sed 's/roles\///g' | sed 's/.yaml//g'
echo

echo "enter playbook:"
read -r PLAYBOOK
echo

echo "enter group: git | mysql | or hit enter for all hosts"
read -r LIMIT
echo

ansible-playbook roles/"$PLAYBOOK".yaml -e ansible_python_interpreter=/usr/bin/python2 -i inventories/inventory-"$ENV".yaml --limit "$LIMIT" --check --diff
