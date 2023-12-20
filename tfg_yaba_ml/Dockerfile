FROM python:3.9.5

ARG USER=docker
ARG UID=1000
ARG GID=1000

ENV APP_DIR /app

# Create user, group, and give it sudo
RUN groupadd --gid $GID $USER \
    && useradd --uid $UID --gid $GID -m $USER \
    && apt-get update \
    && apt-get install -y sudo \
    && echo $USER ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USER \
    && chmod 0440 /etc/sudoers.d/$USER

# Install gcloud
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg  add - && apt-get update -y && apt-get -oDebug::pkgAcquire::Worker=1 install google-cloud-sdk -y
# Create .gcloud directory and give permissions
RUN mkdir -p $(eval echo ~$USER)/.config/gcloud && chown $UID:$GID $(eval echo ~$USER)/.config/gcloud

# VSCode live session libraries
RUN wget -O ~/vsls-reqs https://aka.ms/vsls-linux-prereq-script && chmod +x ~/vsls-reqs && ~/vsls-reqs

# Install pipenv
RUN pip install pipenv==2022.1.8

# Create app dir, copy Pipfiles and install pip packages
RUN mkdir $APP_DIR
COPY Pipfile .
COPY Pipfile.lock .

RUN pipenv install --deploy --system --dev

# INSTALL EXTRA TOOLS
# Repo for Github Cli (gh)
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
RUN sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
# Install jq, vim & gh
RUN sudo apt-get update -y && sudo apt-get install -y jq vim gh

# Switch to standard user
USER $USER

# Working directory
WORKDIR $APP_DIR

CMD bash