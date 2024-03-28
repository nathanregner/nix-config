```
ls ~/Library/Preferences/ | parallel 'echo {} && defaults read {}'
defaults read ~/Library/Preferences/pbs.plist | plutil -convert json - -o - | jq > nix-config/modules/darwin/pbs.json
```
