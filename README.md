why nix?

idk, i just set up a nix server so why not

```bash
docker build -t nix-runner -f Dockerfile.nix .

# optionally, leave out `example.txt` to default to `input.txt`
docker run -v ./d4:/input -t nix-runner solution_a.nix example.txt
```
