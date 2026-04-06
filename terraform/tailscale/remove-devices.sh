#!/usr/bin/env bash

tofu state list | rg device | xargs tofu state rm
