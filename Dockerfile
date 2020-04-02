FROM percona:5.7.29

MAINTAINER Massimiliano Ferrero <m.ferrero@cognitio.it>

# install cron and nullmailer
# install updated version of tail (coreutils): https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=810669
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get upgrade -y \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y cron nullmailer wget \
    && wget http://ftp.debian.org/debian/pool/main/c/coreutils/coreutils_8.26-3_amd64.deb \
    && dpkg -i coreutils_8.26-3_amd64.deb \
    && rm -f coreutils_8.26-3_amd64.deb \
    && apt-get --purge -y autoremove wget \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# create mountpoint for mysql dumps
RUN mkdir -p /dump

# remove cron stock jobs
RUN rm -f /etc/cron.hourly/* /etc/cron.daily/* /etc/cron.weekly/* /etc/cron.monthly/* /etc/cron.d/*

# Create the log file to be able to run tail
RUN touch /var/log/cron.log

COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod 755 /usr/local/bin/docker-entrypoint.sh

# Run the command on container startup
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
