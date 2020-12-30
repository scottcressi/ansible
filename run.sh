if ! command -v ansible > /dev/null ; then echo ansible is not installed ;  exit 0 ; fi
if ! command -v yamllint > /dev/null ; then echo yamllint is not installed ;  exit 0 ; fi

yamllint . -s

export ANSIBLE_HOST_KEY_CHECKING=False

ansible-galaxy install -r requirements.yaml -f
NOOP=--check

while [ $# -gt 0 ]; do
  case "$1" in
    --playbook)
        PLAYBOOK=$2
      ;;
    --env)
        ENV=$2
      ;;
    --limit)
        LIMIT=$2
      ;;
    --apply)
        NOOP=
      ;;
  esac
  shift
done

ansible-playbook playbooks/"$PLAYBOOK".yaml -e ansible_python_interpreter=/usr/bin/python2 -i inventories/inventory-"$ENV".yaml --limit "$LIMIT" --diff $NOOP
