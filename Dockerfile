FROM ubuntu:noble

ENV DEBIAN_FRONTEND=noninteractive

# INSTALL SOURCES FOR CHROME REMOTE DESKTOP 
RUN apt-get update && apt-get -y upgrade && apt-get install -y curl gpg wget \
     && rm -rf /var/lib/apt/lists/* \
     && apt-get clean \
     && apt-get autoclean

RUN apt-get update \
     && apt-get install -y --fix-broken sudo apt-utils xvfb xfce4 xbase-clients desktop-base vim psmisc xserver-xorg-video-dummy ffmpeg dialog python3-xdg fonts-noto-cjk pavucontrol ibus ibus-rime rime-data-pinyin-simp python3-packaging python3-psutil dbus-x11 libutempter0 \
     && wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor | tee /etc/apt/keyrings/google-chrome.gpg > /dev/null \
     && wget https://dl.google.com/linux/direct/chrome-remote-desktop_current_amd64.deb \
     && apt-get install -y --fix-broken ./chrome-remote-desktop_current_amd64.deb \
     && rm -f chrome-remote-desktop_current_amd64.deb \
     && echo "exec /etc/X11/Xsession /usr/bin/xfce4-session" > /etc/chrome-remote-desktop-session \
     &&  wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb \
     && apt-get install -y ./google-chrome-stable_current_amd64.deb \
     && apt-get install -y --fix-broken --no-install-recommends \
     && sed -i 's#/usr/bin/google-chrome-stable#/usr/bin/google-chrome-stable --no-sandbox --disable-dev-shm-usage --disable-gpu --disable-software-resterizer#g' /usr/share/applications/google-chrome.desktop \
     && rm -rf google-chrome-stable_current_amd64.deb \
     && rm -rf /var/lib/apt/lists/* \
     && apt-get clean \
     && apt-get autoclean

# SPECIFY VARIABLES FOR SETTING UP CHROME REMOTE DESKTOP
ARG USER=crduser
# use 6 digits at least
ENV PIN=123456
ENV CODE=4/xxx
ENV HOSTNAME=myvirtualdesktop

# ADD USER TO THE SPECIFIED GROUPS
RUN adduser --disabled-password --gecos '' $USER \
     && mkhomedir_helper $USER \
     && adduser $USER sudo \
     && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers \
     && usermod -aG chrome-remote-desktop $USER 
USER $USER
WORKDIR /home/$USER
RUN mkdir -p .config/chrome-remote-desktop .config/chrome-remote-desktop/crashpad \
     && chmod a+rx .config/chrome-remote-desktop \
     && echo "/usr/bin/pulseaudio --start" > .chrome-remote-desktop-session \
     && echo "pactl load-module module-pipe-sink sink_name=chrome_remote_desktop_session format=s16le rate=48000 channels=2" >> .chrome-remote-desktop-session \
     && echo 'pactl set-default-sink chrome_remote_desktop_session' >> .chrome-remote-desktop-session \
     && echo "startxfce4 :1030" >> .chrome-remote-desktop-session \
     && chown -R $USER:$USER /home/$USER
CMD \
   DISPLAY= /opt/google/chrome-remote-desktop/start-host --code=$CODE --redirect-url="https://remotedesktop.google.com/_/oauthredirect" --name=$HOSTNAME --pin=$PIN ; \
   HOST_HASH=$(python3 -c "import hashlib,socket; print(hashlib.md5(socket.gethostname().encode()).hexdigest())") && \
   FILENAME=.config/chrome-remote-desktop/host#${HOST_HASH}.json && echo $FILENAME && \
   mv .config/chrome-remote-desktop/host#*.json $FILENAME ; \
   sudo service chrome-remote-desktop stop && \
   sudo service chrome-remote-desktop start && \
   echo $HOSTNAME && \
   sleep infinity & wait

