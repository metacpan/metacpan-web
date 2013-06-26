#!/bin/bash

chmod +x git/hooks/pre-commit
cd .git/hooks
ln -s ../../git/hooks/pre-commit
