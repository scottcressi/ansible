if ! command -v ansible > /dev/null ; then echo ansible is not installed ;  exit 0 ; fi

export ANSIBLE_HOST_KEY_CHECKING=False

echo "enter env: test | dev | prod"
read -r ENV
echo "enter group: git | mysql "
read -r LIMIT

ansible-galaxy install -r requirements.yaml -f
ansible-playbook test.yaml -e ansible_python_interpreter=/usr/bin/python2 -i inventory-"$ENV".yaml --limit "$LIMIT" --check --diff
