# setup vault (optional)
```
bash run.sh --vault
```

# install prereqs (optional)
```
bash run.sh --install_prereqs
```

# run ansible
```
bash run.sh
```

# run ansible example
```
bash run.sh -p playbooks/test.yaml
```

# testing with vagrant (optional)
```
vagrant up ; vagrant ssh -c "cd ~/ansible ; bash run.sh -p playbooks/test.yaml"
```
