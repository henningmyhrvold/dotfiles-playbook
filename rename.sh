#!/usr/bin/env bash

git grep -l henning | xargs sed -i 's/henning/youruser/g'
