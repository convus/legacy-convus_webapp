#!/bin/bash
LOCATION_ARG=$1 # $STACK_BASE needs to be passed as the first argument when running this script

papertrail_host="logs7.papertrailapp.com"        # The host for your Papertrail connection
papertrail_port="47912"                         # The port for your Papertrail connection
log_files=(                                     # List of log files to send to Papertrail
  "- $LOCATION_ARG/shared/log/nginx_error.log"
  "- $LOCATION_ARG/shared/log/production.log"     # Default rack app log location
)
initd_url="https://github.com/papertrail/remote_syslog2/releases/download/v0.20/remote_syslog_linux_amd64.tar.gz"

# Download and install the remote_syslog2 binary from papertrail
wget $initd_url -P /tmp/
tar xzfC /tmp/remote_syslog*.tar.gz /tmp/
cd /tmp/remote_syslog
cp ./remote_syslog /usr/local/bin

# Generate the log_files.yml file from the configured variables
log_files_yaml="/etc/log_files.yml"
> $log_files_yaml
echo "files:" >> $log_files_yaml
for file in ${log_files[*]}; do
  echo "  $file" >> $log_files_yaml
done
echo "destination:" >> $log_files_yaml
echo "  host: $papertrail_host" >> $log_files_yaml
echo "  port: $papertrail_port" >> $log_files_yaml
echo "  protocol: tls" >> $log_files_yaml
chmod 775 $log_files_yaml

# Set it up as a service
mv "$LOCATION_ARG/current/.cloud66/remote_syslog.init.d" /etc/init.d/remote_syslog
chmod +x /etc/init.d/remote_syslog
service remote_syslog start
update-rc.d remote_syslog defaults
