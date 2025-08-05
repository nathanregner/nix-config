import requests

maven = requests.get(
    "http://sagittarius:8083/api/settings/domain/maven",
    headers={"Authorization": "xBasic YWRtaW46dGFpbHNjYWxl"},
).json()

by_id = {repo.id: repo for repo in maven["repositories"]}
print(by_id)
