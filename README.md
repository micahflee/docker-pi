# docker-pi

Loosely based on [these docs](https://pi.dev/docs/latest/containerization#run-pi-in-plain-docker).

Build with:

```sh
docker build -t pi-sandbox -f Dockerfile .
```

Start with:

```sh
docker run --rm -it \
  -e ANTHROPIC_API_KEY \
  -v "$PWD:/workspace" \
  -v pi-agent-home:/root/.pi/agent \
  pi-sandbox
```
