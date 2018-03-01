FROM ubuntu:14.04

MAINTAINER FND <fndemers@gmail.com>

ENV PROJECTNAME=SL4A

# Working Directory
ENV WORKDIRECTORY /home/ubuntu

# Access SSH login
ENV USERNAME=ubuntu
ENV PASSWORD=ubuntu

RUN apt-get update

RUN apt-get install -y python-dev unzip vim-nox

# Install a basic SSH server
RUN apt install -y openssh-server
RUN sed -i 's|session    required     pam_loginuid.so|session    optional     pam_loginuid.so|g' /etc/pam.d/sshd
RUN mkdir -p /var/run/sshd
RUN /usr/bin/ssh-keygen -A

# Add user to the image
RUN adduser --quiet --disabled-password --shell /bin/bash --home /home/${USERNAME} --gecos "User" ${USERNAME}
# Set password for the jenkins user (you may want to alter this).
RUN echo "$USERNAME:$PASSWORD" | chpasswd

# Installation Java.
# Open JDK
#RUN apt-get install -qy --no-install-recommends python-dev default-jdk
# Oracle Java 8
RUN apt-get install -y software-properties-common \
    && add-apt-repository -y ppa:webupd8team/java \
    && apt-get update
RUN echo oracle-java8-installer shared/accepted-oracle-license-v1-1 \
    select true | /usr/bin/debconf-set-selections
RUN apt-get install -y oracle-java8-installer
ENV JAVA_HOME /usr/lib/jvm/java-8-oracle/

# Install Deps
RUN dpkg --add-architecture i386 && apt-get update \
    && apt-get install -y --force-yes expect wget \
    libc6-i386 lib32stdc++6 lib32gcc1 lib32ncurses5 lib32z1

# Install Android SDK
RUN cd /opt && wget --quiet --output-document=android-sdk.tgz \
    http://dl.google.com/android/${ANDROID_SDK} \
    && tar xzf android-sdk.tgz && rm -f android-sdk.tgz \
    && chown -R root.root android-sdk-linux

# Setup environment
ENV ANDROID_HOME /opt/android-sdk-linux
ENV PATH ${PATH}:${ANDROID_HOME}/tools:${ANDROID_HOME}/platform-tools:${ANDROID_HOME}/tools/bin

# Install sdk elements
COPY tools /opt/tools
ENV PATH ${PATH}:/opt/tools
RUN ["/opt/tools/android-accept-licenses.sh", \
    "android update sdk --all --force --no-ui --filter platform-tools,tools,build-tools-23,build-tools-23.0.2,android-23,addon-google_apis_x86-google-23,extra-android-support,extra-android-m2repository,extra-google-m2repository,extra-google-google_play_services,sys-img-armeabi-v7a-android-23"]

# Unzip tools if not unzipped.
# Strange that it is not uncompressed.
RUN cd ${ANDROID_HOME} \
    && unzip -o -q ${ANDROID_HOME}/temp/${ANDROID_TOOLS}

# Accept all Android licenses
#RUN /opt/android-sdk-linux/tools/bin/sdkmanager --update
RUN ["/opt/tools/android-accept-licenses2.sh", \
    "/opt/android-sdk-linux/tools/bin/sdkmanager --update"]

# Pour exécuter Android Studio
RUN apt-get install -y libxtst6

# Install Android Studio
RUN cd /opt \
    && wget --quiet --output-document=android-studio.zip \
    https://dl.google.com/dl/android/studio/ide-zips/3.0.1.0/${ANDROID_STUDIO} \
    && unzip android-studio.zip -d /opt \
    && rm -f android-studio.zip

# Acces X11
RUN echo "X11Forwarding yes" >> /etc/ssh/ssh_config

RUN apt install -y xauth vim-gtk

# Fournir accès complet à Android (REVOIR)
RUN chown $USERNAME -R /opt

## Clean up when done
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Port publish access
EXPOSE 5037
EXPOSE 5554
EXPOSE 5555

# Standard SSH port
EXPOSE 22

RUN mkdir -p ${WORKDIRECTORY}

RUN cd ${WORKDIRECTORY} \
    && mkdir -p work \
    && chown -R $USERNAME work

# Go to workspace
WORKDIR ${WORKDIRECTORY}

RUN echo "export PS1=\"\\e[0;31m $PROJECTNAME\\e[m \$PS1\"" >> ${WORKDIRECTORY}/.bash_profile
RUN echo "export ANDROID_HOME=\"/opt/android-sdk-linux\"" >> ${WORKDIRECTORY}/.bash_profile
RUN echo "export PATH=\"\${PATH}:\${ANDROID_HOME}/tools:\${ANDROID_HOME}/platform-tools:\${ANDROID_HOME}/tools/bin:/opt/android-studio/bin\"" >> ${WORKDIRECTORY}/.bash_profile
RUN chown ${USERNAME} ${WORKDIRECTORY}/.bash_profile

# Start SSHD server...
CMD ["/usr/sbin/sshd", "-D"]
