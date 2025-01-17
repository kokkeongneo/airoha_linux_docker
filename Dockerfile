# Use Ubuntu 22.04 as the base image
FROM ubuntu:22.04

# Set environment variable to avoid prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Update package list and install necessary tools
RUN apt-get update && apt-get install -y \
	sudo \
    unzip \
    tar \
    curl \
    git  \
	git-lfs \
	p7zip-full \
	python3 \
	net-tools \
    --no-install-recommends	&& \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN ln -s /usr/bin/python3 /usr/bin/python

# Create a non-root user and group
RUN groupadd -g 1000 user && \
    useradd -u 1000 -g user -m user && \
    echo "user ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Set the USER environment variable
ENV USER=user
# Set the HOME environment variable
ENV HOME=/home/user/
# Ensure the home directory exists
WORKDIR $HOME

# Create a temporary directory for extraction
RUN mkdir -p $HOME/tmp/ && \
    chmod 777 $HOME/tmp/

# Set working directory to temporary folder
WORKDIR $HOME/tmp

# Switch to non-root user
USER user

# Copy the file from the host to the container
COPY --chown=user:user BT_Audio_Linux_Build_Env.tar.gz $HOME/tmp/

# Extract the airoha toolchain 
RUN sudo tar -xvf $HOME/tmp/BT_Audio_Linux_Build_Env.tar.gz -C $HOME/tmp/

# Install airoha toolchain using sudo while preserving the environment
RUN sudo -E $HOME/tmp/install.sh

# Clean up
RUN sudo rm -rf $HOME/tmp

# Switch back to home directory
WORKDIR $HOME

# Copy startup script and make it executable
COPY startup.sh $HOME/startup.sh
RUN sudo chmod +x $HOME/startup.sh

# Set the startup script as the container's entrypoint
# ENTRYPOINT ["sh", "-c", "$HOME/startup.sh"]
CMD ["sh", "-c", "$HOME/startup.sh"]

# Set the default command for the container
#CMD ["bash"]
