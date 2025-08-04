#!/usr/bin/env bash

git grep -l myuser | xargs sed -i 's/myuser/hm/g'
