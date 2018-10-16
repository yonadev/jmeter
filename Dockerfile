FROM alpine:3.6

ARG JMETER_VERSION="3.3"

ENV JMETER_PATH /opt
ENV JMETER_HOME /opt/apache-jmeter-${JMETER_VERSION}
ENV JMETER_BIN  ${JMETER_HOME}/bin
ENV MIRROR_HOST https://archive.apache.org/dist/jmeter
ENV JMETER_DOWNLOAD_URL ${MIRROR_HOST}/binaries/apache-jmeter-${JMETER_VERSION}.tgz
ENV JMETER_PLUGINS_DOWNLOAD_URL http://repo1.maven.org/maven2/kg/apc
ENV JMETER_PLUGINS_FOLDER ${JMETER_HOME}/lib/ext/
ENV PLUGINMGR_VERSION 1.3

RUN    apk update \
	&& apk upgrade \
	&& apk add ca-certificates \
	&& update-ca-certificates \
	&& apk add --update openjdk8-jre tzdata curl unzip bash \
	&& cp /usr/share/zoneinfo/Europe/Rome /etc/localtime \
	&& echo "Europe/Rome" >  /etc/timezone \
	&& rm -rf /var/cache/apk/* \
	&& mkdir -p /tmp/dependencies  \
	&& curl -L --silent --show-error --fail ${JMETER_DOWNLOAD_URL} >  /tmp/dependencies/apache-jmeter-${JMETER_VERSION}.tgz  \
	&& mkdir -p /opt  \
	&& tar -xzf /tmp/dependencies/apache-jmeter-${JMETER_VERSION}.tgz -C /opt  \
	&& rm -rf /tmp/dependencies

# Get the PluginsManagerCMD.sh from the jar (the PluginsManagerCMD.sh is in the JAR)
RUN cd ${JMETER_PLUGINS_FOLDER} && \
	curl -O --silent --show-error --fail http://search.maven.org/remotecontent?filepath=kg/apc/jmeter-plugins-manager/$PLUGINMGR_VERSION/jmeter-plugins-manager-$PLUGINMGR_VERSION.jar && \
    java -cp jmeter-plugins-manager-${PLUGINMGR_VERSION}.jar org.jmeterplugins.repository.PluginManagerCMDInstaller && \
	cd ${JMETER_BIN} && \
    chmod u+x PluginsManagerCMD.sh && \
	cd ${JMETER_HOME}/lib && \
	curl -O --silent --show-error --fail https://search.maven.org/remotecontent?filepath=kg/apc/cmdrunner/2.2/cmdrunner-2.2.jar

# Plug-ins needed for Yona
ENV LIST_PLUGINS="jpgc-casutg=2.1,jpgc-dummy=0.1,jpgc-cmd=2.1,jpgc-ggl=2.0,jpgc-pde=0.1,jpgc-json=2.7,jpgc-ffw=2.0"

# Run the PluginsManager to download and install files (JARs and scripts files)
RUN cd ${JMETER_BIN} && \
    JVM_ARGS="-Dhttps.proxyHost=$ARG_https_proxyHost -Dhttps.proxyPort=$ARG_https_proxyPort" ./PluginsManagerCMD.sh install $LIST_PLUGINS && \
    JVM_ARGS="-Dhttps.proxyHost=$ARG_https_proxyHost -Dhttps.proxyPort=$ARG_https_proxyPort" ./PluginsManagerCMD.sh status

ENV PATH $PATH:$JMETER_BIN

COPY launch.sh /

WORKDIR ${JMETER_HOME}

ENTRYPOINT ["/launch.sh"]
