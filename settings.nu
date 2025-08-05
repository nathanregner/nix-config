#!/usr/bin/env nu

let maven = (
  curl -s 'http://sagittarius:8083/api/settings/domain/maven'
  -H 'Authorization: xBasic YWRtaW46dGFpbHNjYWxl'
)
| from json

let by_id = $maven.repositories | group-by id

def add-mirror [url: string] {
  let id = $url | url parse | get host
  if $id not-in by_id {
  {
      ..by_id
      {$id: {
        id: $id
      }}
      id:$id,
    }
  } else {
  by_id
  }
}

# add-mirror "https://nregner.net"

{} | update "1" { |row| print -e $row}
