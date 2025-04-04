#!/usr/bin/env nix-shell
#!nix-shell -i bash -p openssl
openssl genrsa -out example.com.private 2048
openssl req -new -key example.com.private -out example.com.csr
openssl x509 -req -days 3652 -in example.com.csr -signkey example.com.private -out example.com.cert
