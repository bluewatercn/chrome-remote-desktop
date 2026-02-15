FROM ubuntu:noble

ENV DEBIAN_FRONTEND=noninteractive

# INSTALL SOURCES FOR CHROME REMOTE DESKTOP 
RUN apt-get update && apt-get upgrade --assume-yes
RUN apt-get --assume-yes install curl gpg wget
RUN wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | apt-key add -
RUN sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list'

# INSTALL XFCE DESKTOP AND DEPENDENCIES
RUN apt-get update && apt-get upgrade --assume-yes
RUN apt-get install --assume-yes --fix-missing sudo wget apt-utils xvfb xfce4 xbase-clients \
    desktop-base vim google-chrome-stable psmisc xserver-xorg-video-dummy ffmpeg dialog python3-xdg \
    fonts-noto-cjk pavucontrol ibus ibus-rime rime-data-pinyin-simp \
    python3-packaging python3-psutil dbus-x11 
RUN apt-get install libutempter0
RUN wget https://dl.google.com/linux/direct/chrome-remote-desktop_current_amd64.deb
RUN dpkg --install chrome-remote-desktop_current_amd64.deb
RUN apt-get install --assume-yes --fix-broken
RUN bash -c 'echo "exec /etc/X11/Xsession /usr/bin/xfce4-session" > /etc/chrome-remote-desktop-session'

### Google Chrome
RUN apt-get update && wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb \
     && sudo apt install -y ./google-chrome-stable_current_amd64.deb; \
     sudo apt install --assume-yes --fix-broken --no-install-recommends; \
     rm -f google-chrome-stable_current_amd64.deb \
     && rm -rf /var/lib/apt/lists/* \
     && apt-get clean; apt-get autoclean

# ---------------------------------------------------------- 
# SPECIFY VARIABLES FOR SETTING UP CHROME REMOTE DESKTOP
ARG USER=crduser
# use 6 digits at least
ENV PIN=123456
ENV CODE=4/xxx
ENV HOSTNAME=myvirtualdesktop
# ---------------------------------------------------------- 
# ADD USER TO THE SPECIFIED GROUPS
RUN adduser --disabled-password --gecos '' $USER
RUN mkhomedir_helper $USER
RUN adduser $USER sudo
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
RUN usermod -aG chrome-remote-desktop $USER 
USER $USER
WORKDIR /home/$USER
RUN mkdir -p .config/chrome-remote-desktop
RUN mkdir .config/chrome-remote-desktop/crashpad
RUN chmod a+rx .config/chrome-remote-desktop
#RUN touch .config/chrome-remote-desktop/host.json
RUN echo "/usr/bin/pulseaudio --start" > .chrome-remote-desktop-session
RUN echo "startxfce4 :1030" >> .chrome-remote-desktop-session
RUN sudo chown -R $USER:$USER /home/$USER
CMD \
   DISPLAY= /opt/google/chrome-remote-desktop/start-host --code=$CODE --redirect-url="https://remotedesktop.google.com/_/oauthredirect" --name=$HOSTNAME --pin=$PIN ; \
   HOST_HASH=$(python3 -c "import hashlib,socket; print(hashlib.md5(socket.gethostname().encode()).hexdigest())") && \
   FILENAME=.config/chrome-remote-desktop/host#${HOST_HASH}.json && echo $FILENAME && \
   mv .config/chrome-remote-desktop/host#*.json $FILENAME ; \
   sudo service chrome-remote-desktop stop && \
   sudo service chrome-remote-desktop start && \
   echo $HOSTNAME && \
   sleep infinity & wait

