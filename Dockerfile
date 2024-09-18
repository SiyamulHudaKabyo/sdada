# Use Python as the base image
FROM python:3.11-slim

# Set the working directory
WORKDIR /app

# Install dependencies
RUN apt-get update && apt-get install -y wget

# Determine system architecture and install the corresponding version of Miniconda
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then \
        wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh; \
    elif [ "$ARCH" = "aarch64" ]; then \
        wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-aarch64.sh; \
    else \
        echo "Unsupported architecture: $ARCH" && exit 1; \
    fi && \
    bash Miniconda3-latest-Linux-*.sh -b && \
    ls -la /root/miniconda3 && \
    rm Miniconda3-latest-Linux-*.sh && \
    apt-get clean

# Install Mamba using Miniconda and create a new environment with Python 3.11
RUN /root/miniconda3/bin/conda install mamba -c conda-forge -y \
    && /root/miniconda3/bin/mamba create -n team4_env python=3.11 -y \
    && /root/miniconda3/bin/mamba clean --all -f -y

# Set environment path to use team4_env and ensure bash is used
ENV PATH="/root/miniconda3/envs/team4_env/bin:$PATH"

# Activate the environment and install packages from requirements.txt
SHELL ["/bin/bash", "-c"]
RUN echo "source /root/miniconda3/bin/activate team4_env" >> ~/.bashrc

# Copy requirements.txt into the container
COPY requirements.txt /app/requirements.txt

# Install Python packages from requirements.txt
RUN /bin/bash -c "source ~/.bashrc && mamba install --yes --file /app/requirements.txt && mamba clean --all -f -y"

# Install Jupyter Notebook
RUN /bin/bash -c "source ~/.bashrc && mamba install -c conda-forge jupyter"

# Install NGINX
RUN apt-get update && apt-get install -y nginx

# Copy NGINX config
COPY nginx.conf /etc/nginx/nginx.conf

# Copy the current directory contents into the container
COPY . /app

# Expose ports for NGINX, Streamlit, and Jupyter
EXPOSE 80
EXPOSE 5004
EXPOSE 8888

# Start NGINX, Streamlit, and Jupyter
CMD service nginx start && streamlit run app.py --server.port=5004 && jupyter notebook --ip=0.0.0.0 --port=8888 --no-browser --allow-root