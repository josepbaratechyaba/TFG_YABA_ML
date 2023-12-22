FROM python:3.11

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
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add - && apt-get update -y && apt-get install google-cloud-sdk -y
# Create .gcloud directory and give permissions
RUN mkdir -p $(eval echo ~$USER)/.config/gcloud && chown $UID:$GID $(eval echo ~$USER)/.config/gcloud

# Install pipenv
RUN pip install pipenv==2022.1.8

# Create app dir, copy Pipfiles and install pip packages
RUN mkdir $APP_DIR
COPY Pipfile .
COPY Pipfile.lock .

RUN pipenv install --deploy --system --dev

# Install jq, vim & gh
RUN sudo apt-get update -y && sudo apt-get install -y jq vim

# Switch to standard user
USER $USER

# Working directory
WORKDIR $APP_DIR

RUN python -m ipykernel install --user --name ml_kernel --display-name "ml_kernel"

CMD ["jupyter", "notebook", "--kernel=ml_kernel"]