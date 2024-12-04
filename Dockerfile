# Use the official Nix image as base
FROM nixos/nix:latest

# Switch to unstable channel and update
RUN nix-channel --add https://nixos.org/channels/nixos-unstable nixpkgs && \
    nix-channel --update

# Create a working directory
WORKDIR /app

# Create the entrypoint script using printf to properly handle newlines
RUN printf '#!/usr/bin/env bash\n\
if [ $# -eq 0 ] || [ $# -gt 2 ]; then\n\
    echo "Usage: $0 <script.nix> [input_file]"\n\
    echo "If input_file is not provided, defaults to input.txt"\n\
    exit 1\n\
fi\n\
\n\
# Set input file to second argument or default to input.txt\n\
INPUT_FILE=${2:-input.txt}\n\
\n\
if [ ! -f /input/$INPUT_FILE ]; then\n\
    echo "Error: $INPUT_FILE not found in mounted volume"\n\
    exit 1\n\
fi\n\
\n\
nix-instantiate --show-trace --extra-experimental-features pipe-operators --eval "/input/$1" --argstr inputFile "/input/$INPUT_FILE"\n' > /app/entrypoint.sh

# Make the entrypoint script executable
RUN chmod +x /app/entrypoint.sh

# Set the entrypoint
ENTRYPOINT ["/app/entrypoint.sh"]
